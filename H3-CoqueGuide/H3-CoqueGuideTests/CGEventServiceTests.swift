//
//  CGEventServiceTests.swift
//  H3-CoqueGuideTests
//
//  Unit tests para el servicio de eventos del museo.
//

import XCTest
@testable import H3_CoqueGuide

final class CGEventServiceTests: XCTestCase {

    // MARK: - Singleton

    func testSharedInstance() {
        let instance1 = CGEventService.shared
        let instance2 = CGEventService.shared

        XCTAssertTrue(instance1 === instance2, "Should return same singleton instance")
    }

    // MARK: - Today's Events

    func testTodaysEventsCount() {
        let events = CGEventService.shared.todaysEvents()

        XCTAssertEqual(events.count, 4)
    }

    func testTodaysEventsHaveRequiredFields() {
        let events = CGEventService.shared.todaysEvents()

        for event in events {
            XCTAssertFalse(event.id.isEmpty, "Event ID should not be empty")
            XCTAssertFalse(event.name.isEmpty, "Event name should not be empty")
            XCTAssertFalse(event.time.isEmpty, "Event time should not be empty")
            XCTAssertFalse(event.location.isEmpty, "Event location should not be empty")
            XCTAssertFalse(event.description.isEmpty, "Event description should not be empty")
            XCTAssertFalse(event.icon.isEmpty, "Event icon should not be empty")
        }
    }

    func testTodaysEventsHaveUniqueIds() {
        let events = CGEventService.shared.todaysEvents()
        let ids = events.map { $0.id }
        let uniqueIds = Set(ids)

        XCTAssertEqual(ids.count, uniqueIds.count, "All event IDs should be unique")
    }

    // MARK: - Next Event

    func testNextEventReturnsFirst() {
        let nextEvent = CGEventService.shared.nextEvent()
        let firstEvent = CGEventService.shared.todaysEvents().first

        XCTAssertNotNil(nextEvent)
        XCTAssertEqual(nextEvent?.id, firstEvent?.id)
    }
}
