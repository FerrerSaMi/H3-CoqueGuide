//
//  CGAIServiceTests.swift
//  H3-CoqueGuideTests
//
//  Unit tests para el servicio de IA simulado.
//

import XCTest
@testable import H3_CoqueGuide

final class CGAIServiceTests: XCTestCase {

    var service: CGSimulatedAIService!

    override func setUp() {
        super.setUp()
        service = CGSimulatedAIService()
    }

    // MARK: - Respuestas por categoría

    func testGreetingResponse() async {
        let response = await service.processMessage("hola")

        XCTAssertNotNil(response.text)
        XCTAssertFalse(response.text!.isEmpty)
        XCTAssertTrue(response.cards.isEmpty)
    }

    func testMapResponse() async {
        let response = await service.processMessage("mapa")

        XCTAssertNotNil(response.text)
        XCTAssertFalse(response.cards.isEmpty, "Map response should include action cards")
        XCTAssertEqual(response.cards.first?.cardType, .map)
    }

    func testEventsResponse() async {
        let response = await service.processMessage("eventos")

        XCTAssertNotNil(response.text)
        XCTAssertFalse(response.cards.isEmpty, "Events response should include event cards")
        XCTAssertEqual(response.cards.first?.cardType, .event)
    }

    func testScanResponse() async {
        let response = await service.processMessage("escanear")

        XCTAssertNotNil(response.text)
        XCTAssertFalse(response.cards.isEmpty, "Scan response should include scan card")
        XCTAssertEqual(response.cards.first?.cardType, .scan)
    }

    func testLanguageResponse() async {
        let response = await service.processMessage("idioma")

        XCTAssertNotNil(response.text)
        XCTAssertTrue(response.cards.isEmpty, "Language response should be text-only")
    }

    func testAccessibilityResponse() async {
        let response = await service.processMessage("accesibilidad")

        XCTAssertNotNil(response.text)
        XCTAssertTrue(response.cards.isEmpty)
    }

    func testAdmissionResponse() async {
        let response = await service.processMessage("horario")

        XCTAssertNotNil(response.text)
        XCTAssertTrue(response.cards.isEmpty)
    }

    func testMuseumInfoResponse() async {
        let response = await service.processMessage("museo horno3")

        XCTAssertNotNil(response.text)
        XCTAssertTrue(response.cards.isEmpty)
    }

    func testServicesResponse() async {
        let response = await service.processMessage("restaurante")

        XCTAssertNotNil(response.text)
        XCTAssertTrue(response.cards.isEmpty)
    }

    func testHelpResponse() async {
        let response = await service.processMessage("ayuda")

        XCTAssertNotNil(response.text)
        XCTAssertTrue(response.cards.isEmpty)
    }

    func testDefaultResponse() async {
        let response = await service.processMessage("xyz123abc")

        XCTAssertNotNil(response.text)
        XCTAssertTrue(response.cards.isEmpty)
    }

    // MARK: - CGAIResponse factories

    func testTextOnlyFactory() {
        let response = CGAIResponse.textOnly("Test")

        XCTAssertEqual(response.text, "Test")
        XCTAssertTrue(response.cards.isEmpty)
    }

    func testWithCardsFactory() {
        let card = CGActionCard(cardType: .info, title: "Info")
        let response = CGAIResponse.withCards("Texto", cards: [card])

        XCTAssertEqual(response.text, "Texto")
        XCTAssertEqual(response.cards.count, 1)
    }

    // MARK: - Protocolo

    func testConformsToProtocol() {
        let _: CGAIServiceProtocol = CGSimulatedAIService()
        // Si compila, conforma al protocolo
    }
}
