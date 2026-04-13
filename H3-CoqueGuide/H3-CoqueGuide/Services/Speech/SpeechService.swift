//
//  SpeechService.swift
//  H3-CoqueGuide
//
//  Created by Angel De Jesus Sanchez Figueroa on 25/03/26.
//

import AVFoundation
import Combine
 
// MARK: - SpeechService
 
/// Servicio de Text-to-Speech usando AVSpeechSynthesizer.
/// Detecta automáticamente el idioma del sistema (es-MX / es-ES / etc.)
/// y ajusta la voz disponible más apropiada.
final class SpeechService: NSObject, ObservableObject {
 
    // MARK: Published
    @Published var isSpeaking = false
    @Published var progress: Double = 0.0
 
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
            speak(text)
        }
    }
 
    /// Detiene la reproducción inmediatamente.
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        reset()
    }
 
    // MARK: - Private
 
    private func speak(_ text: String) {
        guard !text.isEmpty else { return }
 
        totalLength  = text.count
        spokenLength = 0
        progress     = 0
 
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice       = resolvedVoice()
        utterance.rate        = AVSpeechUtteranceDefaultSpeechRate * 0.92   // ligeramente más pausado
        utterance.pitchMultiplier = 1.05
        utterance.volume      = 1.0
        utterance.preUtteranceDelay = 0.15
 
        synthesizer.speak(utterance)
 
        DispatchQueue.main.async { self.isSpeaking = true }
    }
 
    /// Elige la mejor voz disponible según el locale del sistema.
    /// Prioriza voz "mejorada" o "premium" si el usuario la tiene descargada.
    private func resolvedVoice() -> AVSpeechSynthesisVoice? {
        let systemLocale = Locale.current
        let langCode     = systemLocale.language.languageCode?.identifier ?? "es"
        let regionCode   = systemLocale.region?.identifier ?? "MX"
 
        // Identificadores candidatos, de mayor a menor preferencia
        let candidates: [String] = [
            "\(langCode)-\(regionCode)",   // e.g. es-MX
            langCode == "es" ? (regionCode == "ES" ? "es-ES" : "es-MX") : "\(langCode)-\(regionCode)",
            "es-MX",
            "es-ES",
            "es-US",
            "es"
        ]
 
        // Intenta encontrar voz mejorada o premium primero
        for id in candidates {
            let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix(id.prefix(5)) }
            if let premium = voices.first(where: { $0.quality == .premium }) { return premium }
            if let enhanced = voices.first(where: { $0.quality == .enhanced }) { return enhanced }
            if let standard = voices.first(where: { $0.quality == .default }) { return standard }
        }
 
        // Fallback absoluto
        return AVSpeechSynthesisVoice(language: "es-MX")
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
    }
 
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        reset()
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
