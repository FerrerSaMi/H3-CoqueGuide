//
//  MuseumTranslationService.swift
//  H3-CoqueGuide
//
//  Traduce las descripciones del catálogo de objetos del museo desde español
//  al idioma del dispositivo, vía POST /translate (Gemini server-side).
//
//  Cachea por sesión: cada (label, idioma) se traduce una sola vez.
//

import Foundation

@MainActor
final class MuseumTranslationService {

    static let shared = MuseumTranslationService()
    private init() {}

    // MARK: - Cache en memoria

    /// Clave: "<label>::<lang>" → tupla traducida.
    private var cache: [String: (title: String, era: String, description: String)] = [:]

    /// Traduce los campos de un objeto del museo al idioma del dispositivo.
    /// Si el idioma es español, devuelve los campos originales sin tocar.
    /// Si la traducción falla por cualquier razón, devuelve los originales (fallback seguro).
    func translateForDevice(
        label: String,
        title: String,
        era: String,
        description: String
    ) async -> (title: String, era: String, description: String) {
        let lang = AppLanguage.device.rawValue
        if lang == "es" {
            return (title, era, description)
        }

        let key = "\(label)::\(lang)"
        if let cached = cache[key] {
            return cached
        }

        struct Payload: Encodable {
            let title: String
            let era: String
            let description: String
            let target_language: String
        }
        struct Response: Decodable {
            let ok: Bool
            let title: String?
            let era: String?
            let description: String?
            let error: String?
        }

        do {
            let response: Response = try await BackendHTTPClient.shared.post(
                "translate",
                body: Payload(
                    title: title,
                    era: era,
                    description: description,
                    target_language: lang
                )
            )
            guard response.ok else {
                return (title, era, description)
            }
            let translated = (
                response.title ?? title,
                response.era ?? era,
                response.description ?? description
            )
            cache[key] = translated
            return translated
        } catch {
            print("⚠️ MuseumTranslationService: \(error.localizedDescription) — usando original ES.")
            return (title, era, description)
        }
    }
}
