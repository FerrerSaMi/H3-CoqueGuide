//
//  CamScannerTests.swift
//  H3-CoqueGuideTests
//

import XCTest
@testable import H3_CoqueGuide

// MARK: - CamScannerTests
final class CamScannerTests: XCTestCase {

    // MARK: - CameraError Tests
    func testCameraErrorPermissionDenied() {
        let error = CameraError.permissionDenied

        XCTAssertEqual(error.errorDescription, "Permiso de cámara denegado.")
        XCTAssertEqual(error.localizedDescription, "Permiso de cámara denegado.")
    }
    // MARK: - CameraError Tests
    func testCameraErrorDeviceUnavailable() {
        let error = CameraError.deviceUnavailable

        XCTAssertEqual(error.errorDescription, "No se encontró la cámara trasera.")
        XCTAssertEqual(error.localizedDescription, "No se encontró la cámara trasera.")
    }
}
