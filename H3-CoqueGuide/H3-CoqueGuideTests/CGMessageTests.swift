//
//  CGMessageTests.swift
//  H3-CoqueGuideTests
//
//  Unit tests para los modelos de datos de CoqueGuide.
//

import XCTest
@testable import H3_CoqueGuide

final class CGMessageTests: XCTestCase {

    // MARK: - CGMessage

    func testUserMessageFactory() {
        let message = CGMessage.userMessage("Hola")

        XCTAssertEqual(message.text, "Hola")
        XCTAssertEqual(message.sender, .user)
        XCTAssertTrue(message.cards.isEmpty)
        XCTAssertNotNil(message.id)
    }

    func testGuideMessageFactory() {
        let message = CGMessage.guideMessage("Bienvenido")

        XCTAssertEqual(message.text, "Bienvenido")
        XCTAssertEqual(message.sender, .coqueGuide)
        XCTAssertTrue(message.cards.isEmpty)
    }

    func testGuideMessageWithCardsFactory() {
        let card = CGActionCard(cardType: .map, title: "Mapa")
        let message = CGMessage.guideMessage("Texto", cards: [card])

        XCTAssertEqual(message.text, "Texto")
        XCTAssertEqual(message.sender, .coqueGuide)
        XCTAssertEqual(message.cards.count, 1)
        XCTAssertEqual(message.cards.first?.title, "Mapa")
    }

    func testGuideMessageWithNilText() {
        let message = CGMessage.guideMessage(nil, cards: [])

        XCTAssertNil(message.text)
        XCTAssertEqual(message.sender, .coqueGuide)
    }

    func testMessageHasUniqueIds() {
        let msg1 = CGMessage.userMessage("A")
        let msg2 = CGMessage.userMessage("B")

        XCTAssertNotEqual(msg1.id, msg2.id)
    }

    func testMessageTimestamp() {
        let before = Date()
        let message = CGMessage.userMessage("Test")
        let after = Date()

        XCTAssertGreaterThanOrEqual(message.timestamp, before)
        XCTAssertLessThanOrEqual(message.timestamp, after)
    }

    // MARK: - CGSuggestion

    func testSuggestionCreation() {
        let suggestion = CGSuggestion(text: "¿Quieres ver el mapa?", icon: "map")

        XCTAssertEqual(suggestion.text, "¿Quieres ver el mapa?")
        XCTAssertEqual(suggestion.icon, "map")
        XCTAssertNotNil(suggestion.id)
    }

    func testSuggestionsHaveUniqueIds() {
        let s1 = CGSuggestion(text: "A", icon: "map")
        let s2 = CGSuggestion(text: "B", icon: "star")

        XCTAssertNotEqual(s1.id, s2.id)
    }

    // MARK: - CGQuickAction

    func testQuickActionCreation() {
        let action = CGQuickAction(title: "Ver mapa", icon: "map", message: "Muestra el mapa")

        XCTAssertEqual(action.title, "Ver mapa")
        XCTAssertEqual(action.icon, "map")
        XCTAssertEqual(action.message, "Muestra el mapa")
        XCTAssertNotNil(action.id)
    }

    func testDefaultQuickActionsCount() {
        XCTAssertEqual(CGQuickAction.defaults.count, 5)
    }

    func testDefaultQuickActionsHaveContent() {
        for action in CGQuickAction.defaults {
            XCTAssertFalse(action.title.isEmpty, "Quick action title should not be empty")
            XCTAssertFalse(action.icon.isEmpty, "Quick action icon should not be empty")
            XCTAssertFalse(action.message.isEmpty, "Quick action message should not be empty")
        }
    }
}
