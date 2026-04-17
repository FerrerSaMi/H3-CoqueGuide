//
//  AppConfig.swift
//  H3-CoqueGuide
//
//  Configuración central de la app: URLs del backend, flags de entorno, etc.
//  Todo lo que antes vivía como hardcoded en servicios debería centralizarse aquí.
//

import Foundation

enum AppConfig {

    // MARK: - Backend

    /// URL base del backend H3-CoqueGuide.
    ///   - Debug:   localhost (tu Mac corriendo `npm run dev`).
    ///   - Release: Cloud Run (placeholder hasta que se deploye).
    ///
    /// Cuando el deploy a Cloud Run esté listo, solo cambia la cadena de RELEASE.
    static let backendBaseURL: URL = {
        #if DEBUG
        return URL(string: "http://localhost:8080")!
        #else
        // TODO: reemplazar cuando tengamos la URL de Cloud Run.
        return URL(string: "https://coqueguide-backend.example.com")!
        #endif
    }()

    // MARK: - Device

    /// Identificador estable del dispositivo mientras la app esté instalada.
    /// Se usa como `device_id` en analytics y en requests al backend.
    static var deviceID: String {
        UIDevice.current.identifierForVendor?.uuidString ?? "unknown-device"
    }
}

// UIKit solo para identifierForVendor. El resto de la app sigue siendo SwiftUI.
#if canImport(UIKit)
import UIKit
#endif
