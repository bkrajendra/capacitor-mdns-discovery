import Foundation

@objc public class MdnsDiscovery: NSObject {
    @objc public func echo(_ value: String) -> String {
        print(value)
        return value
    }
}
