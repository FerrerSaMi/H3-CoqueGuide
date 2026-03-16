//
//  CGViewModelTests.swift
//  H3-CoqueGuideTests
//
//  Unit tests para el ViewModel principal de CoqueGuide.
//

import XCTest
@testable import H3_CoqueGuide

// MARK: - Mock AI Service para tests

final class MockAIService: CGAIServiceProtocol {
    var lastReceivedMessage: String?
    var responseToReturn: CGAIResponse = .textOnly("Mock response")
    var processMessageCallCount = 0

    func processMessage(_ text: String) async -> CGAIResponse {
        lastReceivedMessage = text
        processMessageCallCount += 1
        return responseToReturn
    }
}

// MARK: - Tests

@MainActor
final class CGViewModelTests: XCTestCase {

    var viewModel: CGViewModel!
    var mockService: MockAIService!

    override func setUp() {
        super.setUp()
        mockService = MockAIService()
        viewModel = CGViewModel(aiService: mockService)
    }

    // MARK: - Estado inicial

    func testInitialState() {
        XCTAssertTrue(viewModel.messages.isEmpty)
        XCTAssertFalse(viewModel.isThinking)
        XCTAssertFalse(viewModel.isPanelOpen)
        XCTAssertNil(viewModel.activeSuggestion)
        XCTAssertEqual(viewModel.pendingSuggestionsCount, 0)
    }

    // MARK: - Open Panel

    func testOpenPanelSetsPanelOpen() {
        viewModel.openPanel()

        XCTAssertTrue(viewModel.isPanelOpen)
    }

    func testOpenPanelClearsSuggestion() {
        viewModel.openPanel()

        XCTAssertNil(viewModel.activeSuggestion)
        XCTAssertEqual(viewModel.pendingSuggestionsCount, 0)
    }

    // MARK: - Send Message

    func testSendMessageAddsUserMessage() {
        viewModel.sendMessage("Hola")

        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertEqual(viewModel.messages.first?.text, "Hola")
        XCTAssertEqual(viewModel.messages.first?.sender, .user)
    }

    func testSendEmptyMessageDoesNothing() {
        viewModel.sendMessage("")

        XCTAssertTrue(viewModel.messages.isEmpty)
    }

    func testSendWhitespaceMessageDoesNothing() {
        viewModel.sendMessage("   ")

        XCTAssertTrue(viewModel.messages.isEmpty)
    }

    func testSendMessageTrimsWhitespace() {
        viewModel.sendMessage("  Hola  ")

        XCTAssertEqual(viewModel.messages.first?.text, "Hola")
    }

    func testSendMessageCallsAIService() async throws {
        viewModel.sendMessage("Test")

        // Wait for async response
        try await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertEqual(mockService.lastReceivedMessage, "Test")
        XCTAssertEqual(mockService.processMessageCallCount, 1)
    }

    func testSendMessageAddsAIResponse() async throws {
        mockService.responseToReturn = .textOnly("Respuesta de prueba")
        viewModel.sendMessage("Test")

        // Wait for async response
        try await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertEqual(viewModel.messages.count, 2)
        XCTAssertEqual(viewModel.messages.last?.text, "Respuesta de prueba")
        XCTAssertEqual(viewModel.messages.last?.sender, .coqueGuide)
    }

    // MARK: - Quick Actions

    func testHandleQuickAction() {
        let action = CGQuickAction(title: "Test", icon: "star", message: "Mensaje de prueba")
        viewModel.handleQuickAction(action)

        XCTAssertEqual(viewModel.messages.first?.text, "Mensaje de prueba")
    }

    // MARK: - Suggestions

    func testDismissSuggestion() {
        viewModel.dismissSuggestion()

        XCTAssertNil(viewModel.activeSuggestion)
    }
}
