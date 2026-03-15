import XCTest
@testable import HowToEntraIos

final class AzureMapsAuthProtocolTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        AzureMapsAuthProtocol.reset()
    }

    // MARK: - canInit

    func test_canInit_returnsTrueForAzureMapsURL() {
        let request = URLRequest(url: URL(string: "https://atlas.microsoft.com/map/tile?api-version=2024-04-01&tilesetId=microsoft.base.road&zoom=16&x=1&y=1&tileSize=256")!)
        XCTAssertTrue(AzureMapsAuthProtocol.canInit(with: request))
    }

    func test_canInit_returnsFalseForOtherURL() {
        let request = URLRequest(url: URL(string: "https://example.com/api/data")!)
        XCTAssertFalse(AzureMapsAuthProtocol.canInit(with: request))
    }

    func test_canInit_returnsFalseForAlreadyHandledRequest() {
        let url = URL(string: "https://atlas.microsoft.com/map/tile")!
        let mutableRequest = NSMutableURLRequest(url: url)
        URLProtocol.setProperty(true, forKey: "AzureMapsAuthProtocol.handled", in: mutableRequest)

        XCTAssertFalse(AzureMapsAuthProtocol.canInit(with: mutableRequest as URLRequest))
    }

    // MARK: - configure / reset

    func test_configure_setsCredentials() {
        AzureMapsAuthProtocol.configure(token: "test-token", clientId: "test-client-id")

        XCTAssertEqual(AzureMapsAuthProtocol.bearerToken, "test-token")
        XCTAssertEqual(AzureMapsAuthProtocol.azureMapsClientId, "test-client-id")
    }

    func test_reset_clearsCredentials() {
        AzureMapsAuthProtocol.configure(token: "test-token", clientId: "test-client-id")

        AzureMapsAuthProtocol.reset()

        XCTAssertTrue(AzureMapsAuthProtocol.bearerToken.isEmpty)
        XCTAssertTrue(AzureMapsAuthProtocol.azureMapsClientId.isEmpty)
    }

    // MARK: - makeSessionConfiguration

    func test_makeSessionConfiguration_containsProtocolClass() {
        let config = AzureMapsAuthProtocol.makeSessionConfiguration()

        let containsProtocol = config.protocolClasses?.contains(where: { $0 == AzureMapsAuthProtocol.self }) ?? false
        XCTAssertTrue(containsProtocol)
    }

    func test_makeSessionConfiguration_doesNotSetHttpAdditionalHeaders() {
        AzureMapsAuthProtocol.configure(token: "token", clientId: "client-id")

        let config = AzureMapsAuthProtocol.makeSessionConfiguration()

        XCTAssertNil(config.httpAdditionalHeaders)
    }
}

