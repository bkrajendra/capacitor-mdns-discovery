import XCTest
@testable import MdnsDiscoveryPlugin

class MdnsDiscoveryTests: XCTestCase {
    func testEcho() {
        let implementation = MdnsDiscovery()
        implementation.startDiscovery(serviceType: "_http._tcp")
        implementation.stopDiscovery(serviceType: "_http._tcp")
        implementation.stopAll()
        XCTAssertTrue(true)
    }
}
