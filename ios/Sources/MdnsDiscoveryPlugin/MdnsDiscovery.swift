import Foundation
import Network

@objc public class MdnsDiscovery: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    // One browser per service type so we can scan multiple types at once.
    private var browsers: [String: NetServiceBrowser] = [:]
    private var services: [String: NetService] = [:]

    @objc public var onDeviceFound: (([String: Any]) -> Void)?
    @objc public var onDeviceLost: (([String: Any]) -> Void)?
    @objc public var onError: (([String: Any]) -> Void)?

    @objc public func startDiscovery(serviceType: String) {
        let normalizedType = serviceType.hasSuffix(".") ? serviceType : "\(serviceType)."

        // If we're already browsing this type, do nothing.
        if browsers[normalizedType] != nil {
            return
        }

        let browser = NetServiceBrowser()
        browser.delegate = self
        browsers[normalizedType] = browser
        browser.searchForServices(ofType: normalizedType, inDomain: "local.")
    }

    @objc public func stopDiscovery(serviceType: String?) {
        guard let serviceType else {
            stopAll()
            return
        }

        let normalizedType = serviceType.hasSuffix(".") ? serviceType : "\(serviceType)."
        if let browser = browsers[normalizedType] {
            browser.stop()
            browser.delegate = nil
            browsers.removeValue(forKey: normalizedType)
        }

        // Stop monitoring any services for this type.
        let keysToRemove = services.keys.filter { $0.hasSuffix(".\(normalizedType)") }
        for key in keysToRemove {
            services[key]?.stopMonitoring()
            services.removeValue(forKey: key)
        }
    }

    @objc public func stopAll() {
        browsers.values.forEach {
            $0.stop()
            $0.delegate = nil
        }
        browsers.removeAll()
        services.values.forEach { $0.stopMonitoring() }
        services.removeAll()
    }

    public func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        service.delegate = self
        let key = serviceKey(for: service)
        services[key] = service
        service.resolve(withTimeout: 5.0)
    }

    public func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        let key = serviceKey(for: service)
        services.removeValue(forKey: key)

        let data: [String: Any] = [
            "name": service.name,
            "serviceType": service.type.trimmingCharacters(in: CharacterSet(charactersIn: "."))
        ]
        onDeviceLost?(data)
    }

    public func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String: NSNumber]) {
        let code = errorDict[NetService.errorCode]?.intValue ?? -1
        let data: [String: Any] = [
            "message": "mDNS discovery failed to start",
            "code": code
        ]
        onError?(data)
    }

    public func netServiceDidResolveAddress(_ sender: NetService) {
        let host = sender.hostName ?? ""
        let port = sender.port

        var txtRecords: [String: String] = [:]
        if let txtData = sender.txtRecordData() {
            let dict = NetService.dictionary(fromTXTRecord: txtData)
            for (key, valueData) in dict {
                let value = String(data: valueData, encoding: .utf8) ?? ""
                txtRecords[key] = value
            }
        }

        let data: [String: Any] = [
            "name": sender.name,
            "host": host,
            "port": port,
            "serviceType": sender.type.trimmingCharacters(in: CharacterSet(charactersIn: ".")),
            "txtRecords": txtRecords
        ]
        onDeviceFound?(data)
    }

    public func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
        let code = errorDict[NetService.errorCode]?.intValue ?? -1
        let data: [String: Any] = [
            "message": "Failed to resolve service",
            "code": code
        ]
        onError?(data)
    }

    private func serviceKey(for service: NetService) -> String {
        // Include type so services don't collide across browsers.
        return "\(service.name).\(service.type)"
    }
}
