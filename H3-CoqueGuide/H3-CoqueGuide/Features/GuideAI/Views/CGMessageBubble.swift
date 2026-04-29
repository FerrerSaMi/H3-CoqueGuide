//
//  CGMessageBubble.swift
//  CoqueGuideAI
//
//  Burbuja de mensaje individual para el historial de conversación.
//  Soporta mensajes del usuario (derecha) y de CoqueGuide (izquierda).
//

import SwiftUI

// MARK: - Burbuja de mensaje

struct CGMessageBubble: View {

    let message: CGMessage
    /// VM compartido para acceder al servicio TTS y al estado de lectura.
    @ObservedObject var viewModel: CGViewModel
    /// Observamos directamente el SpeechService para que la UI reaccione
    /// a cambios de `isPaused` (no se propagan automáticamente vía viewModel).
    @ObservedObject var speech: SpeechService

    private var isUser: Bool { message.sender == .user }
    private var isThisMessageActive: Bool { viewModel.currentSpeakingMessageID == message.id }
    private var isThisMessagePlaying: Bool { isThisMessageActive && !speech.isPaused }
    private var isThisMessagePaused: Bool { isThisMessageActive && speech.isPaused }

    /// Ícono según el estado de TTS de este mensaje.
    private var ttsIconName: String {
        if isThisMessagePlaying { return "pause.fill" }
        if isThisMessagePaused { return "play.fill" }
        return "speaker.wave.2.fill"
    }

    /// Etiqueta de accesibilidad acorde al estado.
    private var ttsAccessibilityLabel: String {
        if isThisMessagePlaying { return L10n.chatStopListening }
        return L10n.chatListenMessage
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {

            // Avatar de CoqueGuide (solo en mensajes del asistente)
            if !isUser {
                Image("Coque")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color(.separator), lineWidth: 0.5))
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {

                // Burbuja con texto. Parseamos markdown ligero (negritas, itálicas)
                // así Coque puede usar **énfasis** y se renderiza, no aparece literal.
                if let text = message.text, !text.isEmpty {
                    Text(parseMarkdown(text))
                        .font(.body)
                        .foregroundStyle(isUser ? .white : .primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Group {
                                if isUser {
                                    Color.accentColor
                                } else {
                                    Color(.secondarySystemGroupedBackground)
                                }
                            }
                        )
                        .clipShape(
                            BubbleShape(isUser: isUser)
                        )
                        .shadow(
                            color: isUser
                                ? Color.accentColor.opacity(0.25)
                                : Color.black.opacity(0.06),
                            radius: 4, x: 0, y: 2
                        )
                        .frame(
                            maxWidth: 280,
                            alignment: isUser ? .trailing : .leading
                        )
                }

                // Tarjetas de acción (solo mensajes del asistente)
                if !message.cards.isEmpty {
                    if message.cards.count == 1 {
                        // Una sola tarjeta: mostrar directamente
                        CGActionCardView(card: message.cards[0])
                    } else {
                        // Múltiples tarjetas: usar slider/tabview
                        TabView {
                            ForEach(message.cards) { card in
                                CGActionCardView(card: card)
                                    .tag(card.id)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .automatic))
                        .frame(height: 140)
                    }
                }

                // Timestamp + botón de TTS (solo asistente con texto)
                HStack(spacing: 8) {
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    if !isUser, let text = message.text, !text.isEmpty {
                        Button {
                            viewModel.toggleSpeak(message: message)
                        } label: {
                            Image(systemName: ttsIconName)
                                .scalingFont(size: 14, weight: .semibold)
                                .foregroundStyle(isThisMessageActive ? Color.orange : .secondary)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(isThisMessageActive ? Color.orange.opacity(0.18) : Color(.tertiarySystemFill))
                                )
                                .overlay(
                                    Circle()
                                        .stroke(isThisMessageActive ? Color.orange.opacity(0.4) : Color.clear, lineWidth: 1)
                                )
                                .contentTransition(.symbolEffect(.replace))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(ttsAccessibilityLabel)
                    }
                }
                .padding(.horizontal, 6)
            }

            // Empuja el mensaje del asistente a la izquierda
            if !isUser {
                Spacer(minLength: 40)
            }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }

    /// Parsea markdown ligero (negritas, itálicas, links inline). Si falla,
    /// devuelve el texto plano sin asteriscos para no mostrar `**foo**` literal.
    private func parseMarkdown(_ text: String) -> AttributedString {
        if let attributed = try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            return attributed
        }
        return AttributedString(text)
    }
}

// MARK: - Forma de burbuja con punta

/// Forma personalizada que añade la "punta" característica de los globos de chat.
private struct BubbleShape: Shape {

    let isUser: Bool

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18
        let tipWidth: CGFloat = 7
        let tipHeight: CGFloat = 9

        var path = Path()

        if isUser {
            // Burbuja del usuario: punta en esquina inferior derecha
            let drawRect = CGRect(
                x: rect.minX,
                y: rect.minY,
                width: rect.width - tipWidth,
                height: rect.height
            )

            // Esquinas redondeadas excepto la inferior derecha
            path.move(to: CGPoint(x: drawRect.minX + radius, y: drawRect.minY))
            path.addLine(to: CGPoint(x: drawRect.maxX - radius, y: drawRect.minY))
            path.addArc(
                center: CGPoint(x: drawRect.maxX - radius, y: drawRect.minY + radius),
                radius: radius,
                startAngle: .degrees(-90),
                endAngle: .degrees(0),
                clockwise: false
            )
            path.addLine(to: CGPoint(x: drawRect.maxX, y: drawRect.maxY - radius))
            path.addArc(
                center: CGPoint(x: drawRect.maxX - radius, y: drawRect.maxY - radius),
                radius: radius,
                startAngle: .degrees(0),
                endAngle: .degrees(90),
                clockwise: false
            )
            // Punta
            path.addLine(to: CGPoint(x: drawRect.maxX, y: drawRect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: drawRect.maxY + tipHeight * 0.5))
            path.addLine(to: CGPoint(x: drawRect.maxX, y: drawRect.maxY))
            path.addLine(to: CGPoint(x: drawRect.minX + radius, y: drawRect.maxY))
            path.addArc(
                center: CGPoint(x: drawRect.minX + radius, y: drawRect.maxY - radius),
                radius: radius,
                startAngle: .degrees(90),
                endAngle: .degrees(180),
                clockwise: false
            )
            path.addLine(to: CGPoint(x: drawRect.minX, y: drawRect.minY + radius))
            path.addArc(
                center: CGPoint(x: drawRect.minX + radius, y: drawRect.minY + radius),
                radius: radius,
                startAngle: .degrees(180),
                endAngle: .degrees(270),
                clockwise: false
            )

        } else {
            // Burbuja del asistente: punta en esquina inferior izquierda
            let drawRect = CGRect(
                x: tipWidth,
                y: rect.minY,
                width: rect.width - tipWidth,
                height: rect.height
            )

            path.move(to: CGPoint(x: drawRect.minX + radius, y: drawRect.minY))
            path.addLine(to: CGPoint(x: drawRect.maxX - radius, y: drawRect.minY))
            path.addArc(
                center: CGPoint(x: drawRect.maxX - radius, y: drawRect.minY + radius),
                radius: radius,
                startAngle: .degrees(-90),
                endAngle: .degrees(0),
                clockwise: false
            )
            path.addLine(to: CGPoint(x: drawRect.maxX, y: drawRect.maxY - radius))
            path.addArc(
                center: CGPoint(x: drawRect.maxX - radius, y: drawRect.maxY - radius),
                radius: radius,
                startAngle: .degrees(0),
                endAngle: .degrees(90),
                clockwise: false
            )
            path.addLine(to: CGPoint(x: drawRect.minX + radius, y: drawRect.maxY))
            path.addArc(
                center: CGPoint(x: drawRect.minX + radius, y: drawRect.maxY - radius),
                radius: radius,
                startAngle: .degrees(90),
                endAngle: .degrees(180),
                clockwise: false
            )
            // Punta
            path.addLine(to: CGPoint(x: drawRect.minX, y: drawRect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: drawRect.maxY + tipHeight * 0.5))
            path.addLine(to: CGPoint(x: drawRect.minX, y: drawRect.maxY))
            path.addLine(to: CGPoint(x: drawRect.minX, y: drawRect.minY + radius))
            path.addArc(
                center: CGPoint(x: drawRect.minX + radius, y: drawRect.minY + radius),
                radius: radius,
                startAngle: .degrees(180),
                endAngle: .degrees(270),
                clockwise: false
            )
        }

        path.closeSubpath()
        return path
    }
}

// MARK: - Indicador de escritura (typing indicator)

/// Tres puntos animados que indican que CoqueGuide está preparando la respuesta.
struct CGTypingIndicator: View {

    @State private var animate = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {

            Image("Coque")
                .resizable()
                .scaledToFill()
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color(.separator), lineWidth: 0.5))

            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color(.systemGray3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(animate ? 1.4 : 0.8)
                        .opacity(animate ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.18),
                            value: animate
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { animate = true }
    }
}
