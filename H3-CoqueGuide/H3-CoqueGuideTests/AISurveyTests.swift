//
//  AISurveyTests.swift
//  H3-CoqueGuideTests
//

import XCTest
@testable import H3_CoqueGuide

final class SurveyTests: XCTestCase {

    //estado inicial del formulario
    func testInitialStateSurvey() {
        let vm = SurveyViewModel()

        //campos vacios
        XCTAssertTrue(vm.name.isEmpty)
        XCTAssertTrue(vm.ageText.isEmpty)
        XCTAssertTrue(vm.availableTime.isEmpty)
        XCTAssertTrue(vm.specificSearch.isEmpty)

        //sin preferencias seleccionadas
        XCTAssertTrue(vm.selectedPreferences.isEmpty)

        //valores por default
        XCTAssertFalse(vm.preferredLanguage.isEmpty)
        XCTAssertFalse(vm.selectedCoquePersonality.isEmpty)

        //opciones disponibles
        XCTAssertFalse(vm.allPreferences.isEmpty)
    }

    //logica de seleccion de preferencias
    func testPreferenceSelectionLogic() {
        let vm = SurveyViewModel()

        //tomar una preferencia REAL del modelo
        guard let preference = vm.allPreferences.first else {
            XCTFail("No hay preferencias disponibles")
            return
        }

        //seleccionar
        vm.togglePreference(preference)
        XCTAssertTrue(vm.selectedPreferences.contains(preference))

        //deseleccionar
        vm.togglePreference(preference)
        XCTAssertFalse(vm.selectedPreferences.contains(preference))
    }
}