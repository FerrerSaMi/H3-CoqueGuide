//
//  AnalyticsService.swift
//  H3-CoqueGuide
//
//  Servicio fire-and-forget que envía eventos de uso al backend propio
//  (POST /events). Adjunta automáticamente device_id, device_language,
//  app_version y visitor_id (si ya hay perfil).
//
//  En DEBUG imprime cada evento a consola para facilitar QA; en Release
//  esos prints se compilan fuera.
//

import Foundation

final class AnalyticsService {

    static let shared = AnalyticsService()

    /// `visitor_id` que devolvió el backend tras `POST /profile`. Se setea
    /// cuando LandingView detecta perfil existente, o cuando la encuesta
    /// termina de sincronizar al backend.
    private var visitorID: UUID?

    private let session: URLSession
    private let appVersion: String

    private init(session: URLSession = .shared) {
        self.session = session
        self.appVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "unknown"
    }

    // MARK: - Configuración

    func setVisitor(_ id: UUID?) {
        visitorID = id
    }

    // MARK: - Track

    /// Envía un evento al backend. `metadata` debe contener tipos JSON válidos
    /// (String, Int, Double, Bool, Array, Dict).
    func track(_ event: String, metadata: [String: Any] = [:]) {
        var body: [String: Any] = [
            "device_id": AppConfig.deviceID,
            "event_name": event,
            "metadata": metadata,
            "app_version": appVersion,
            "device_language": AppLanguage.device.rawValue,
        ]
        if let vid = visitorID {
            body["visitor_id"] = vid.uuidString
        }

        #if DEBUG
        if metadata.isEmpty {
            print("📊 analytics: \(event)")
        } else {
            print("📊 analytics: \(event) \(metadata)")
        }
        #endif

        Task.detached { [session, body] in
            await AnalyticsService.send(body, using: session)
        }
    }

    // MARK: - Privado

    private static func send(_ body: [String: Any], using session: URLSession) async {
        let url = AppConfig.backendBaseURL.appendingPathComponent("events")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (_, response) = try await session.data(for: request)
            #if DEBUG
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                let name = body["event_name"] as? String ?? "?"
                print("⚠️ analytics: HTTP \(http.statusCode) enviando '\(name)'")
            }
            #endif
        } catch {
            #if DEBUG
            print("⚠️ analytics: \(error.localizedDescription)")
            #endif
        }
    }
}
