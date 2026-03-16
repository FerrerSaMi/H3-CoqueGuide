//
//  CGNavigationCoordinatorTests.swift
//  H3-CoqueGuideTests
//
//  Unit tests para el coordinador de navegación.
//

import XCTest
@testable import H3_CoqueGuide

final class CGNavigationCoordinatorTests: XCTestCase {

    var coordinator: CGNavigationCoordinator!

    override func setUp() {
        super.setUp()
        coordinator = CGNavigationCoordinator()
    }

    func testInitialStateIsNil() {
        XCTAssertNil(coordinator.pendingDestination)
    }

    func testNavigateSetsDestination() {
        coordinator.navigate(to: .map)

        XCTAssertEqual(coordinator.pendingDestination, .map)
    }

    func testConsumeDestinationReturnsAndClears() {
        coordinator.navigate(to: .events)

        let consumed = coordinator.consumeDestination()

        XCTAssertEqual(consumed, .events)
        XCTAssertNil(coordinator.pendingDestination, "Destination should be cleared after consuming")
    }

    func testConsumeDestinationReturnsNilWhenEmpty() {
        let consumed = coordinator.consumeDestination()

        XCTAssertNil(consumed)
    }

    func testNavigateOverwritesPreviousDestination() {
        coordinator.navigate(to: .map)
        coordinator.navigate(to: .scanning)

        XCTAssertEqual(coordinator.pendingDestination, .scanning)
    }

    func testAllDestinations() {
        let destinations: [CGAppDestination] = [.map, .events, .scanning, .survey]

        for dest in destinations {
            coordinator.navigate(to: dest)
            XCTAssertEqual(coordinator.pendingDestination, dest)
            let consumed = coordinator.consumeDestination()
            XCTAssertEqual(consumed, dest)
        }
    }
}
