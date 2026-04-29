//
//  SpeechService.swift
//  H3-CoqueGuide
//
//  Created by Angel De Jesus Sanchez Figueroa on 25/03/26.
//

import AVFoundation
import Combine
import NaturalLanguage
 
// MARK: - SpeechService
 
/// Servicio de Text-to-Speech usando AVSpeechSynthesizer.
/// Detecta automáticamente el idioma del sistema (es-MX / es-ES / etc.)
/// y ajusta la voz disponible más apropiada.
final class SpeechService: NSObject, ObservableObject {
 
    // MARK: Published
    @Published var isSpeaking = false
    @Published var isPaused = false
    @Published var progress: Double = 0.0

    /// Callback opcional que dispara cuando la lectura termina **naturalmente**
    /// (didFinish), no cuando es cancelada explícitamente con `stop()` o
    /// preempted por una nueva llamada a `speak()`. Útil para que el caller
    /// limpie estado solo cuando el audio terminó por sí solo.
    var onNaturalFinish: (() -> Void)?
 
    // MARK: Private
    private let synthesizer = AVSpeechSynthesizer()
    private var totalLength: Int = 0
    private var spokenLength: Int = 0
 
    override init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
    }
 
    // MARK: - Public API
 
    /// Inicia o detiene la lectura del texto.
    func toggle(_ text: String) {
        if synthesizer.isSpeaking {
            stop()
        } else {
            speakInternal(text)
        }
    }
 
    /// Detiene la reproducción inmediatamente.
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        reset()
    }

    /// Pausa la reproducción en el límite de palabra para que se escuche natural
    /// al reanudar. Si no hay nada hablando o ya está pausado, no hace nada.
    func pause() {
        guard synthesizer.isSpeaking, !synthesizer.isPaused else { return }
        synthesizer.pauseSpeaking(at: .word)
        DispatchQueue.main.async { self.isPaused = true }
    }

    /// Reanuda una reproducción pausada. Si no estaba pausado, no hace nada.
    func resume() {
        guard synthesizer.isPaused else { return }
        synthesizer.continueSpeaking()
        DispatchQueue.main.async { self.isPaused = false }
    }
 
    /// Inicia la reproducción del texto. Si ya hay algo sonando, lo detiene
    /// primero. Usar este método cuando se sabe que se quiere arrancar (en
    /// lugar de `toggle`, que decide play/stop según estado actual).
    func speak(_ text: String) {
        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
        }
        speakInternal(text)
    }

    // MARK: - Private

    private func speakInternal(_ text: String) {
        guard !text.isEmpty else { return }

        totalLength  = text.count
        spokenLength = 0
        progress     = 0

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice       = resolvedVoice(forText: text)
        utterance.rate        = AVSpeechUtteranceDefaultSpeechRate * 0.92   // ligeramente más pausado
        utterance.pitchMultiplier = 1.05
        utterance.volume      = 1.0
        utterance.preUtteranceDelay = 0.15

        synthesizer.speak(utterance)

        DispatchQueue.main.async { self.isSpeaking = true }
    }

    /// Detecta el idioma dominante del texto (con NaturalLanguage) y elige
    /// la mejor voz disponible para ese idioma. Prioriza voz "mejorada" o
    /// "premium" si el usuario la tiene descargada.
    ///
    /// Por qué no usamos `Locale.current`: el texto puede estar traducido a un
    /// idioma distinto al del sistema, o estar todavía en español mientras la
    /// traducción asíncrona no llega. Detectar desde el texto es robusto.
    private func resolvedVoice(forText text: String) -> AVSpeechSynthesisVoice? {
        let detected = detectLanguageCode(in: text) ?? fallbackLanguageCode()
        return bestVoice(for: detected)
            ?? AVSpeechSynthesisVoice(language: "\(detected)-\(regionGuess(for: detected))")
            ?? AVSpeechSynthesisVoice(language: detected)
            ?? AVSpeechSynthesisVoice(language: "es-MX")
    }

    /// Detecta el código de idioma ISO (en, es, fr, pt, ko, ar...) del texto.
    private func detectLanguageCode(in text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return recognizer.dominantLanguage?.rawValue
    }

    /// Idioma del sistema como último recurso si la detección falla.
    private func fallbackLanguageCode() -> String {
        Locale.current.language.languageCode?.identifier ?? "es"
    }

    /// Mejor región por defecto para un código de idioma cuando no se puede inferir
    /// del sistema (ej: en → US, es → MX, fr → FR).
    private func regionGuess(for langCode: String) -> String {
        switch langCode {
        case "es": return "MX"
        case "en": return "US"
        case "fr": return "FR"
        case "pt": return "BR"
        case "ko": return "KR"
        case "ar": return "SA"
        default:   return Locale.current.region?.identifier ?? "US"
        }
    }

    /// Busca la mejor voz instalada que arranque con el código de idioma dado.
    private func bestVoice(for langCode: String) -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices().filter {
            $0.language.lowercased().hasPrefix(langCode.lowercased())
        }
        if let premium = voices.first(where: { $0.quality == .premium }) { return premium }
        if let enhanced = voices.first(where: { $0.quality == .enhanced }) { return enhanced }
        return voices.first(where: { $0.quality == .default }) ?? voices.first
    }
 
    private func configureAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(
            .playback,
            mode: .spokenAudio,
            options: [.duckOthers, .allowBluetooth]
        )
        try? AVAudioSession.sharedInstance().setActive(true)
    }
 
    private func reset() {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.isPaused   = false
            self.progress   = 0
        }
    }
}
 
// MARK: - AVSpeechSynthesizerDelegate
 
extension SpeechService: AVSpeechSynthesizerDelegate {
 
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = true }
    }
 
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        reset()
        DispatchQueue.main.async { self.onNaturalFinish?() }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        reset()
        // No notificamos onNaturalFinish: la cancelación viene de nosotros.
    }
 
    /// Actualiza el progreso de lectura en tiempo real.
    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {
        guard totalLength > 0 else { return }
        let end = characterRange.location + characterRange.length
        DispatchQueue.main.async {
            self.spokenLength = end
            self.progress = min(Double(end) / Double(self.totalLength), 1.0)
        }
    }
}
