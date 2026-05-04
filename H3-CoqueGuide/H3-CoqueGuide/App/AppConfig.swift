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
    ///   - Debug:   IP LAN del Mac corriendo `npm run dev` (mismo Wi-Fi).
    ///              Cambiar por `http://localhost:8080` si se corre en simulador.
    ///   - Release: Vercel Serverless (placeholder hasta que se deploye).
    static let backendBaseURL: URL = {
        #if DEBUG
        return URL(string: "http://192.168.10.176:8080")!
        #else
        // TODO: reemplazar por la URL de producción que asigna Vercel.
        //       Va a tener forma `https://<proyecto>.vercel.app`.
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
