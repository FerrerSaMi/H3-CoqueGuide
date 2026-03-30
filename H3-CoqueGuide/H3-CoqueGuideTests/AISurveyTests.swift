//
//  AISurveyTests.swift
//  H3-CoqueGuideTests
//


import XCTest
@testable import H3_CoqueGuide

@MainActor
final class AISurveyTest: XCTestCase {

    func testInitialStateIsCorrect() {
        let viewModel = SurveyViewModel()

        XCTAssertEqual(viewModel.currentScreen, .home)
        XCTAssertEqual(viewModel.currentStepIndex, 0)

        XCTAssertEqual(viewModel.gender, "")
        XCTAssertEqual(viewModel.ageRange, "")
        XCTAssertEqual(viewModel.plannedTime, "")
        XCTAssertEqual(viewModel.attractionPreference, "")
        XCTAssertEqual(viewModel.resolvedAttractionPreference, "")
        XCTAssertEqual(viewModel.specificAttraction, "")
        XCTAssertEqual(viewModel.preferredLanguage, "Español")
        XCTAssertEqual(viewModel.selectedCoquePersonality, "Neutral")

        XCTAssertEqual(viewModel.aiDescription, "")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testStartSurveyResetsAnswersAndMovesToQuestionScreen() {
        let viewModel = SurveyViewModel()

        viewModel.gender = "Mujer"
        viewModel.ageRange = "19 - 29"
        viewModel.plannedTime = "1 - 2 horas"
        viewModel.attractionPreference = "Shows"
        viewModel.resolvedAttractionPreference = "Shows"
        viewModel.specificAttraction = "Mirador"
        viewModel.preferredLanguage = "English"
        viewModel.selectedCoquePersonality = "Divertido"
        viewModel.currentStepIndex = 4
        viewModel.currentScreen = .description
        viewModel.errorMessage = "Error previo"

        viewModel.startSurvey()

        XCTAssertEqual(viewModel.currentScreen, .question)
        XCTAssertEqual(viewModel.currentStepIndex, 0)

        XCTAssertEqual(viewModel.gender, "")
        XCTAssertEqual(viewModel.ageRange, "")
        XCTAssertEqual(viewModel.plannedTime, "")
        XCTAssertEqual(viewModel.attractionPreference, "")
        XCTAssertEqual(viewModel.resolvedAttractionPreference, "")
        XCTAssertEqual(viewModel.specificAttraction, "")
        XCTAssertEqual(viewModel.preferredLanguage, "Español")
        XCTAssertEqual(viewModel.selectedCoquePersonality, "Neutral")
        XCTAssertNil(viewModel.errorMessage)
    }
}

