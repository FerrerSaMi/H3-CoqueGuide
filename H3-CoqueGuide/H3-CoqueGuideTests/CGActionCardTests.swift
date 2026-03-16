//
//  CGActionCardTests.swift
//  H3-CoqueGuideTests
//
//  Unit tests para CGActionCard y tipos relacionados.
//

import XCTest
@testable import H3_CoqueGuide

final class CGActionCardTests: XCTestCase {

    // MARK: - CGCardType

    func testCardTypeActionLabels() {
        XCTAssertEqual(CGCardType.event.actionLabel, "Ver evento")
        XCTAssertEqual(CGCardType.map.actionLabel, "Ir al mapa")
        XCTAssertEqual(CGCardType.scan.actionLabel, "Abrir escáner")
        XCTAssertEqual(CGCardType.info.actionLabel, "Más información")
    }

    func testCardTypeDefaultIcons() {
        XCTAssertEqual(CGCardType.event.defaultIcon, "calendar")
        XCTAssertEqual(CGCardType.map.defaultIcon, "map")
        XCTAssertEqual(CGCardType.scan.defaultIcon, "qrcode.viewfinder")
        XCTAssertEqual(CGCardType.info.defaultIcon, "info.circle")
    }

    // MARK: - CGAppDestination

    func testDestinationHashable() {
        let destinations: Set<CGAppDestination> = [.map, .events, .scanning, .survey]
        XCTAssertEqual(destinations.count, 4)
    }

    // MARK: - CGActionCard

    func testCardCreationWithDefaults() {
        let card = CGActionCard(cardType: .map, title: "Mapa del museo")

        XCTAssertEqual(card.title, "Mapa del museo")
        XCTAssertEqual(card.cardType, .map)
        XCTAssertEqual(card.icon, "map") // uses defaultIcon
        XCTAssertNil(card.subtitle)
        XCTAssertNil(card.description)
        XCTAssertNil(card.action)
        XCTAssertNotNil(card.id)
    }

    func testCardCreationWithCustomIcon() {
        let card = CGActionCard(cardType: .event, title: "Tour", icon: "star.fill")

        XCTAssertEqual(card.icon, "star.fill")
    }

    func testCardCreationWithAllFields() {
        let card = CGActionCard(
            cardType: .scan,
            title: "Escáner",
            subtitle: "QR Code",
            description: "Escanea objetos del museo",
            icon: "camera",
            action: .navigate(.scanning)
        )

        XCTAssertEqual(card.title, "Escáner")
        XCTAssertEqual(card.subtitle, "QR Code")
        XCTAssertEqual(card.description, "Escanea objetos del museo")
        XCTAssertEqual(card.icon, "camera")
    }

    func testCardsHaveUniqueIds() {
        let card1 = CGActionCard(cardType: .map, title: "A")
        let card2 = CGActionCard(cardType: .map, title: "B")

        XCTAssertNotEqual(card1.id, card2.id)
    }

    // MARK: - CGCardAction

    func testNavigateAction() {
        let action = CGCardAction.navigate(.map)
        if case .navigate(let destination) = action {
            XCTAssertEqual(destination, .map)
        } else {
            XCTFail("Expected navigate action")
        }
    }

    func testSendMessageAction() {
        let action = CGCardAction.sendMessage("Hola")
        if case .sendMessage(let text) = action {
            XCTAssertEqual(text, "Hola")
        } else {
            XCTFail("Expected sendMessage action")
        }
    }
}
