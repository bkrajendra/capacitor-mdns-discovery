import Foundation
import Capacitor

@objc(MdnsDiscoveryPlugin)
public class MdnsDiscoveryPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "MdnsDiscoveryPlugin"
    public let jsName = "MdnsDiscovery"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "startDiscovery", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "stopDiscovery", returnType: CAPPluginReturnPromise)
    ]

    private let discovery = MdnsDiscovery()

    public override func load() {
        super.load()

        discovery.onDeviceFound = { [weak self] data in
            self?.notifyListeners("deviceFound", data: data)
        }

        discovery.onDeviceLost = { [weak self] data in
            self?.notifyListeners("deviceLost", data: data)
        }

        discovery.onError = { [weak self] data in
            self?.notifyListeners("discoveryError", data: data)
        }
    }

    @objc func startDiscovery(_ call: CAPPluginCall) {
        let serviceType = call.getString("serviceType") ?? "_http._tcp"
        discovery.startDiscovery(serviceType: serviceType)
        call.resolve()
    }

    @objc func stopDiscovery(_ call: CAPPluginCall) {
        let serviceType = call.getString("serviceType")
        discovery.stopDiscovery(serviceType: serviceType)
        call.resolve()
    }

    deinit {
        discovery.stopAll()
    }
}
