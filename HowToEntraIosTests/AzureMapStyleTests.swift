import XCTest
@testable import HowToEntraIos

final class AzureMapStyleTests: XCTestCase {

    // MARK: - allCases

    func test_allCases_contains8Styles() {
        XCTAssertEqual(AzureMapStyle.allCases.count, 8)
    }

    // MARK: - rawValue (tilesetId)

    func test_road_rawValue() {
        XCTAssertEqual(AzureMapStyle.road.rawValue, "microsoft.base.road")
    }

    func test_darkgrey_rawValue() {
        XCTAssertEqual(AzureMapStyle.darkgrey.rawValue, "microsoft.base.darkgrey")
    }

    func test_imagery_rawValue() {
        XCTAssertEqual(AzureMapStyle.imagery.rawValue, "microsoft.imagery")
    }

    func test_hybridRoad_rawValue() {
        XCTAssertEqual(AzureMapStyle.hybridRoad.rawValue, "microsoft.base.hybrid.road")
    }

    func test_hybridDarkgrey_rawValue() {
        XCTAssertEqual(AzureMapStyle.hybridDarkgrey.rawValue, "microsoft.base.hybrid.darkgrey")
    }

    func test_terra_rawValue() {
        XCTAssertEqual(AzureMapStyle.terra.rawValue, "microsoft.terra.main")
    }

    func test_weatherRadar_rawValue() {
        XCTAssertEqual(AzureMapStyle.weatherRadar.rawValue, "microsoft.weather.radar.main")
    }

    func test_weatherInfrared_rawValue() {
        XCTAssertEqual(AzureMapStyle.weatherInfrared.rawValue, "microsoft.weather.infrared.main")
    }

    // MARK: - displayName

    func test_road_displayName() {
        XCTAssertEqual(AzureMapStyle.road.displayName, "道路")
    }

    func test_darkgrey_displayName() {
        XCTAssertEqual(AzureMapStyle.darkgrey.displayName, "ダークグレー")
    }

    func test_imagery_displayName() {
        XCTAssertEqual(AzureMapStyle.imagery.displayName, "衛星画像")
    }

    func test_hybridRoad_displayName() {
        XCTAssertEqual(AzureMapStyle.hybridRoad.displayName, "ハイブリッド(道路)")
    }

    func test_hybridDarkgrey_displayName() {
        XCTAssertEqual(AzureMapStyle.hybridDarkgrey.displayName, "ハイブリッド(ダークグレー)")
    }

    func test_terra_displayName() {
        XCTAssertEqual(AzureMapStyle.terra.displayName, "地形")
    }

    func test_weatherRadar_displayName() {
        XCTAssertEqual(AzureMapStyle.weatherRadar.displayName, "気象レーダー")
    }

    func test_weatherInfrared_displayName() {
        XCTAssertEqual(AzureMapStyle.weatherInfrared.displayName, "赤外線")
    }

    // MARK: - id

    func test_id_equalsRawValue() {
        for style in AzureMapStyle.allCases {
            XCTAssertEqual(style.id, style.rawValue)
        }
    }

    // MARK: - styleURL

    func test_styleURL_isFileURL() {
        let url = AzureMapStyle.road.styleURL
        XCTAssertTrue(url.isFileURL)
    }

    func test_styleURL_fileContainsValidJSON() throws {
        let url = AzureMapStyle.road.styleURL
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(json?["version"] as? Int, 8)
    }

    func test_styleURL_containsTilesetIdInTileURL() throws {
        let style = AzureMapStyle.darkgrey
        let url = style.styleURL
        let data = try Data(contentsOf: url)
        let content = String(data: data, encoding: .utf8) ?? ""
        XCTAssertTrue(content.contains(style.rawValue))
    }

    func test_styleURL_differentStylesProduceDifferentFiles() {
        let roadURL = AzureMapStyle.road.styleURL
        let imageryURL = AzureMapStyle.imagery.styleURL
        XCTAssertNotEqual(roadURL, imageryURL)
    }
}
