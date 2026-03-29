//
//  AISurveyTests.swift
//  H3-CoqueGuideTests
//

import XCTest
@testable import H3_CoqueGuide

@MainActor
final class SurveyTests: XCTestCase {

    //Estado inicial del formulario
    func testInitialValues() {
        let viewModel = SurveyViewModel()

        XCTAssertEqual(viewModel.name, "")
        XCTAssertEqual(viewModel.ageText, "")
        XCTAssertTrue(viewModel.selectedPreferences.isEmpty)
        XCTAssertEqual(viewModel.availableTime, "")
        XCTAssertEqual(viewModel.specificSearch, "")

        XCTAssertEqual(viewModel.preferredLanguage, "Español")
        XCTAssertEqual(viewModel.selectedCoquePersonality, "Neutral")

        XCTAssertFalse(viewModel.allPreferences.isEmpty)
        XCTAssertFalse(viewModel.languageOptions.isEmpty)
        XCTAssertFalse(viewModel.coquePersonalityOptions.isEmpty)
    }

    //Interaccion del usuario, osea seleccion y cambios
    func testUserInteraction() {
        let viewModel = SurveyViewModel()

        //simular entrada de usuario
        viewModel.name = "Ana"
        viewModel.ageText = "25"
        viewModel.availableTime = "2 horas"
        viewModel.specificSearch = "Museos"
        viewModel.preferredLanguage = "English"
        viewModel.selectedCoquePersonality = "Chistes"

        XCTAssertEqual(viewModel.name, "Ana")
        XCTAssertEqual(viewModel.ageText, "25")
        XCTAssertEqual(viewModel.availableTime, "2 horas")
        XCTAssertEqual(viewModel.specificSearch, "Museos")
        XCTAssertEqual(viewModel.preferredLanguage, "English")
        XCTAssertEqual(viewModel.selectedCoquePersonality, "Chistes")

        //probar seleccion de preferencias
        viewModel.togglePreference("Ver")
        XCTAssertTrue(viewModel.selectedPreferences.contains("Ver"))

        viewModel.togglePreference("Ver")
        XCTAssertFalse(viewModel.selectedPreferences.contains("Ver"))
    }
}