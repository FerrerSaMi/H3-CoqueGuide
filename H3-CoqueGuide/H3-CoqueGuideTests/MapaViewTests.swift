//
//  MapaViewTests.swift
//  H3-CoqueGuideTests
//
//  Unit tests para la logica de datos y coordenadas de MapaView.
//

import XCTest
@testable import H3_CoqueGuide

final class MapaViewTests: XCTestCase {

    func testFallbackConfigContainsExpectedLocations() {
        let config = MapLocationsConfig.fallback

        XCTAssertEqual(config.levels.count, 2)
        XCTAssertEqual(config.allLocations.count, 15)
        XCTAssertEqual(config.allLocations[1], "Laboratorio de Innovación")
        XCTAssertEqual(config.allLocations[15], "Salón Show del horno")
    }

    func testNormalizedPinsApplyDifferentXAxisScalePerLevel() {
        let level1 = MapLevel(
            id: 1,
            imageName: "MapaN1",
            locations: [MapLocation(id: 100, name: "Test", x: 100, y: 50)]
        )
        let level2 = MapLevel(
            id: 2,
            imageName: "MapaN2",
            locations: [MapLocation(id: 100, name: "Test", x: 100, y: 50)]
        )

        let size = CGSize(width: 200, height: 100)
        let pinLevel1 = level1.normalizedPins(forImageSize: size).first
        let pinLevel2 = level2.normalizedPins(forImageSize: size).first

        XCTAssertNotNil(pinLevel1)
        XCTAssertNotNil(pinLevel2)

        XCTAssertEqual(pinLevel1?.x ?? 0, 0.85, accuracy: 0.0001)
        XCTAssertEqual(pinLevel2?.x ?? 0, 0.65, accuracy: 0.0001)
        XCTAssertEqual(pinLevel1?.y ?? 0, 0.5, accuracy: 0.0001)
        XCTAssertEqual(pinLevel2?.y ?? 0, 0.5, accuracy: 0.0001)
        XCTAssertGreaterThan((pinLevel1?.x ?? 0), (pinLevel2?.x ?? 0))
    }
}
