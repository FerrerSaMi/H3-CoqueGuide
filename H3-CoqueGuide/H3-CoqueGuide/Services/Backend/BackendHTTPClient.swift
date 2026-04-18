//
//  BackendHTTPClient.swift
//  H3-CoqueGuide
//
//  Cliente HTTP genérico para hablar con el backend Node propio.
//  Maneja construcción de URL, encoding JSON, decoding y errores uniformes.
//
//  NO contiene lógica de Gemini ni endpoints específicos — es solo transporte.
//  Cada servicio de features (chat, profile, analytics) usa este cliente.
//

import Foundation

// MARK: - Errores del cliente

enum BackendError: LocalizedError {
    case invalidURL
    case http(statusCode: Int, body: String)
    case decoding(Error)
    case transport(Error)
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:                 return "URL inválida del backend."
        case .http(let code, _):          return "El servidor respondió con HTTP \(code)."
        case .decoding(let err):          return "Respuesta del servidor no parseable: \(err.localizedDescription)"
        case .transport(let err):         return "Error de red: \(err.localizedDescription)"
        case .serverError(let message):   return message
        }
    }
}

// MARK: - Cliente

final class BackendHTTPClient {

    static let shared = BackendHTTPClient()

    private let session: URLSession
    private let baseURL: URL
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(baseURL: URL = AppConfig.backendBaseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
    }

    // MARK: - GET

    /// GET a `path` y decodifica a `Response`.
    func get<Response: Decodable>(
        _ path: String,
        as: Response.Type = Response.self
    ) async throws -> Response {
        let request = try makeRequest(path: path, method: "GET", body: nil as EmptyBody?)
        return try await send(request)
    }

    // MARK: - POST

    /// POST con body JSON genérico. El body se encoda con `JSONEncoder` (ISO8601 para fechas).
    func post<Body: Encodable, Response: Decodable>(
        _ path: String,
        body: Body,
        as: Response.Type = Response.self
    ) async throws -> Response {
        let request = try makeRequest(path: path, method: "POST", body: body)
        return try await send(request)
    }

    // MARK: - Privado

    private func makeRequest<Body: Encodable>(
        path: String,
        method: String,
        body: Body?
    ) throws -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30

        if let body {
            request.httpBody = try encoder.encode(body)
        }

        return request
    }

    private func send<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw BackendError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw BackendError.http(statusCode: -1, body: "")
        }

        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            // Si el backend respondió con {"ok":false,"error":"..."} intentamos extraer el mensaje.
            if let envelope = try? JSONDecoder().decode(ErrorEnvelope.self, from: data) {
                throw BackendError.serverError(envelope.error ?? "Error desconocido del servidor.")
            }
            throw BackendError.http(statusCode: http.statusCode, body: body)
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw BackendError.decoding(error)
        }
    }
}

// MARK: - Helpers

/// Body vacío para requests sin cuerpo (usado en GET).
private struct EmptyBody: Encodable {}

/// Sobre de error común que devuelve el backend: `{ "ok": false, "error": "..." }`.
private struct ErrorEnvelope: Decodable {
    let ok: Bool?
    let error: String?
}
