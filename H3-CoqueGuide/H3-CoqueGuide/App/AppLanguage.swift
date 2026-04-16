//
//  AppLanguage.swift
//  H3-CoqueGuide
//
//  Detección del idioma del dispositivo y mapeo a las instrucciones que
//  entiende el servicio de IA. Se usa para:
//   - Pasar el idioma detectado al system prompt de Gemini cuando no hay
//     un perfil de visitante con idioma explícito.
//   - Permitir que el resto de la app (UI, titles, labels) reaccione al
//     idioma actual en conjunto con el String Catalog (Localizable.xcstrings).
//

import Foundation

enum AppLanguage: String, CaseIterable {
    case spanish    = "es"
    case english    = "en"
    case french     = "fr"
    case portuguese = "pt"
    case korean     = "ko"
    case arabic     = "ar"

    // MARK: - Detección del idioma del dispositivo

    /// Idioma detectado a partir de la configuración del iPhone.
    /// Cae a español si el código no corresponde a ningún idioma soportado.
    ///
    /// Se resuelve **una sola vez** en el primer acceso y se cachea durante
    /// toda la sesión. Esto es seguro porque iOS reinicia la app cuando el
    /// usuario cambia el idioma del sistema en Ajustes, así que el valor
    /// nunca cambia mientras la app está viva.
    ///
    /// Evita pagar `Locale.current.language.languageCode` en cada render
    /// de cada `Text` de la UI (L10n se consulta cientos de veces).
    static let device: AppLanguage = {
        let code = Locale.current.language.languageCode?.identifier
            ?? Locale.current.identifier.components(separatedBy: "_").first
            ?? "es"
        return AppLanguage(rawValue: code) ?? .spanish
    }()

    // MARK: - Mapeo desde el perfil del visitante

    /// Convierte el idioma almacenado en el perfil del visitante a AppLanguage.
    /// Si no coincide con nada conocido, cae al idioma del dispositivo.
    static func fromProfile(_ name: String?) -> AppLanguage {
        switch name {
        case "Español":   return .spanish
        case "English":   return .english
        case "Français":  return .french
        case "Português": return .portuguese
        case "Korean", "한국어": return .korean
        case "Arabic", "العربية": return .arabic
        default:          return .device
        }
    }

    // MARK: - Nombre visible

    /// Nombre legible del idioma (para mostrar en UI si hace falta).
    var displayName: String {
        switch self {
        case .spanish:    return "Español"
        case .english:    return "English"
        case .french:     return "Français"
        case .portuguese: return "Português"
        case .korean:     return "한국어"
        case .arabic:     return "العربية"
        }
    }

    // MARK: - Instrucción para el system prompt de Gemini

    /// Instrucción tajante para el LLM de responder en este idioma.
    var geminiInstruction: String {
        switch self {
        case .spanish:
            return "Responde siempre en español mexicano."
        case .english:
            return "You MUST respond ONLY in English. Do not use Spanish at all."
        case .french:
            return "Tu DOIS répondre UNIQUEMENT en français. N'utilise pas l'espagnol."
        case .portuguese:
            return "Você DEVE responder APENAS em português. Não use espanhol."
        case .korean:
            return "반드시 한국어로만 답변하세요. 스페인어를 사용하지 마세요."
        case .arabic:
            return "يجب أن تجيب باللغة العربية فقط. لا تستخدم الإسبانية."
        }
    }
}
