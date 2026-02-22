package com.rajendrakhope.plugins.mdns

import android.content.Context
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.os.Build
import android.util.Log
import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.atomic.AtomicBoolean

private const val TAG = "MdnsDiscovery"

@CapacitorPlugin(name = "MdnsDiscovery")
class MdnsDiscoveryPlugin : Plugin() {

    private var nsdManager: NsdManager? = null
    private val discoveryListeners = ConcurrentHashMap<String, NsdManager.DiscoveryListener>()
    private val resolveQueue = LinkedBlockingQueue<NsdServiceInfo>()
    private val isResolving = AtomicBoolean(false)
    private val resolveExecutor = Executors.newSingleThreadExecutor()

    @PluginMethod
    fun startDiscovery(call: PluginCall) {
        val serviceType = call.getString("serviceType", "_http._tcp")!!
            .let { if (it.endsWith(".")) it else "$it." }

        if (discoveryListeners.containsKey(serviceType)) {
            call.resolve()
            return
        }

        nsdManager = nsdManager ?: (context.getSystemService(Context.NSD_SERVICE) as NsdManager)

        val listener = buildDiscoveryListener(serviceType)
        discoveryListeners[serviceType] = listener

        try {
            nsdManager!!.discoverServices(serviceType, NsdManager.PROTOCOL_DNS_SD, listener)
            Log.i(TAG, "Discovery started for $serviceType")
            call.resolve()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start discovery: ${e.message}")
            discoveryListeners.remove(serviceType)
            call.reject("Failed to start mDNS discovery: ${e.message}")
        }
    }

    @PluginMethod
    fun stopDiscovery(call: PluginCall) {
        val serviceType = call.getString("serviceType", "_http._tcp")!!
            .let { if (it.endsWith(".")) it else "$it." }

        val listener = discoveryListeners.remove(serviceType)
        if (listener != null) {
            try {
                nsdManager?.stopServiceDiscovery(listener)
                Log.i(TAG, "Discovery stopped for $serviceType")
            } catch (e: Exception) {
                Log.w(TAG, "Error stopping discovery: ${e.message}")
            }
        }
        call.resolve()
    }

    override fun handleOnDestroy() {
        super.handleOnDestroy()
        discoveryListeners.forEach { (_, listener) ->
            try { nsdManager?.stopServiceDiscovery(listener) } catch (_: Exception) {}
        }
        discoveryListeners.clear()
        resolveExecutor.shutdown()
    }

    private fun buildDiscoveryListener(serviceType: String): NsdManager.DiscoveryListener {
        return object : NsdManager.DiscoveryListener {

            override fun onDiscoveryStarted(regType: String) {
                Log.d(TAG, "Discovery started: $regType")
            }

            override fun onServiceFound(serviceInfo: NsdServiceInfo) {
                Log.d(TAG, "Service found: ${serviceInfo.serviceName}")
                resolveQueue.offer(serviceInfo)
                processResolveQueue()
            }

            override fun onServiceLost(serviceInfo: NsdServiceInfo) {
                Log.d(TAG, "Service lost: ${serviceInfo.serviceName}")
                val data = JSObject().apply {
                    put("name", serviceInfo.serviceName)
                    put("serviceType", serviceType.trimEnd('.'))
                }
                notifyListeners("deviceLost", data)
            }

            override fun onDiscoveryStopped(serviceType: String) {
                Log.d(TAG, "Discovery stopped: $serviceType")
            }

            override fun onStartDiscoveryFailed(serviceType: String, errorCode: Int) {
                Log.e(TAG, "Start discovery failed: $errorCode")
                discoveryListeners.remove(serviceType)
                val err = JSObject().apply {
                    put("message", "Discovery failed to start")
                    put("code", errorCode)
                }
                notifyListeners("discoveryError", err)
            }

            override fun onStopDiscoveryFailed(serviceType: String, errorCode: Int) {
                Log.e(TAG, "Stop discovery failed: $errorCode")
            }
        }
    }

    private fun processResolveQueue() {
        if (!isResolving.compareAndSet(false, true)) return

        resolveExecutor.submit {
            val serviceInfo = resolveQueue.poll()
            if (serviceInfo == null) {
                isResolving.set(false)
                return@submit
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                resolveWithExecutor(serviceInfo)
            } else {
                resolveClassic(serviceInfo)
            }
        }
    }

    private fun resolveWithExecutor(serviceInfo: NsdServiceInfo) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return

        nsdManager?.resolveService(serviceInfo, resolveExecutor, object : NsdManager.ResolveListener {
            override fun onResolveFailed(info: NsdServiceInfo, errorCode: Int) {
                Log.w(TAG, "Resolve failed for ${info.serviceName}: $errorCode")
                finishResolve()
            }
            override fun onServiceResolved(info: NsdServiceInfo) {
                Log.i(TAG, "Resolved: ${info.serviceName} → ${info.host?.hostAddress}:${info.port}")
                emitDeviceFound(info)
                finishResolve()
            }
        })

        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            finishResolve()
        }, 3000)
    }

    private fun resolveClassic(serviceInfo: NsdServiceInfo) {
        nsdManager?.resolveService(serviceInfo, object : NsdManager.ResolveListener {
            override fun onResolveFailed(info: NsdServiceInfo, errorCode: Int) {
                Log.w(TAG, "Resolve failed for ${info.serviceName}: $errorCode")
                finishResolve()
            }
            override fun onServiceResolved(info: NsdServiceInfo) {
                Log.i(TAG, "Resolved: ${info.serviceName} → ${info.host?.hostAddress}:${info.port}")
                emitDeviceFound(info)
                finishResolve()
            }
        })
    }

    private fun finishResolve() {
        isResolving.set(false)
        if (resolveQueue.isNotEmpty()) {
            processResolveQueue()
        }
    }

    private fun emitDeviceFound(info: NsdServiceInfo) {
        val hostAddress = info.host?.hostAddress ?: return

        val txtRecords = JSObject()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            info.attributes?.forEach { (key, valueBytes) ->
                val value = valueBytes?.let { String(it, Charsets.UTF_8) } ?: ""
                txtRecords.put(key, value)
            }
        }

        val data = JSObject().apply {
            put("name",        info.serviceName ?: "")
            put("host",        hostAddress)
            put("port",        info.port)
            put("serviceType", (info.serviceType ?: "").trimEnd('.'))
            put("txtRecords",  txtRecords)
        }

        notifyListeners("deviceFound", data)
    }
}
