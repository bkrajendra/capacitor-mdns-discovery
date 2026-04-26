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
        // NetServiceBrowser expects to run on a runloop; do it on the main thread.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let normalizedType = serviceType.hasSuffix(".") ? serviceType : "\(serviceType)."

            // If we're already browsing this type, do nothing.
            if self.browsers[normalizedType] != nil {
                return
            }

            let browser = NetServiceBrowser()
            browser.delegate = self
            self.browsers[normalizedType] = browser
            browser.searchForServices(ofType: normalizedType, inDomain: "local.")
        }
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
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.browsers.values.forEach {
                $0.stop()
                $0.delegate = nil
            }
            self.browsers.removeAll()
            self.services.values.forEach { $0.stopMonitoring() }
            self.services.removeAll()
        }
    }

    public func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        service.delegate = self
        let key = serviceKey(for: service)
        services[key] = service

        // Emit an early "found" event even before resolution.
        // On some networks iOS resolution can fail while browsing still works; this keeps the UI informative.
        let early: [String: Any] = [
            "name": service.name,
            "host": service.hostName ?? "",
            "port": service.port,
            "serviceType": service.type.trimmingCharacters(in: CharacterSet(charactersIn: ".")),
            "txtRecords": [:] as [String: String],
            "resolved": false
        ]
        onDeviceFound?(early)

        DispatchQueue.main.async {
            service.resolve(withTimeout: 10.0)
        }
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
            "message": "mDNS discovery failed to start (code \(code))",
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
            "message": "Failed to resolve service \(sender.name) \(sender.type) (code \(code))",
            "code": code
        ]
        onError?(data)
    }

    private func serviceKey(for service: NetService) -> String {
        // Include type so services don't collide across browsers.
        return "\(service.name).\(service.type)"
    }
}
