//
//  CGPanelView.swift
//  CoqueGuideAI
//
//  Panel principal de conversación de CoqueGuide.
//  Se presenta como un sheet desde cualquier pantalla de la app.
//

import SwiftUI

// MARK: - Panel principal

struct CGPanelView: View {

    @ObservedObject var viewModel: CGViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // MARK: Encabezado del asistente
                CGPanelHeader()

                Divider()

                // MARK: Historial de mensajes
                messagesScrollView

                Divider()

                // MARK: Acciones rápidas
                CGQuickActionsView(actions: CGQuickAction.defaults) { action in
                    viewModel.handleQuickAction(action)
                    isInputFocused = false
                }
                .padding(.vertical, 10)

                Divider()

                // MARK: Campo de entrada
                CGInputBar(
                    text: $inputText,
                    isFocused: $isInputFocused,
                    isThinking: viewModel.isThinking,
                    onSend: submitMessage
                )
            }
            .navigationBarHidden(true)
            .background(Color(.systemGroupedBackground))
        }
    }

    // MARK: - Scroll de mensajes

    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(viewModel.messages) { message in
                        CGMessageBubble(message: message)
                            .id(message.id)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    if viewModel.isThinking {
                        CGTypingIndicator()
                            .id("typing")
                            .transition(.opacity)
                    }

                    // Ancla invisible para el scroll automático
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.messages.count)
                .animation(.easeInOut(duration: 0.25), value: viewModel.isThinking)
            }
            .scrollDismissesKeyboard(.interactively)
            // Scroll al nuevo mensaje
            .onChange(of: viewModel.messages.count) { _, _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo("bottom")
                }
            }
            // Scroll al indicador de escritura
            .onChange(of: viewModel.isThinking) { _, isThinking in
                if isThinking {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo("typing")
                    }
                }
            }
        }
    }

    // MARK: - Enviar mensaje

    private func submitMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        viewModel.sendMessage(text)
    }
}

// MARK: - Encabezado del panel

private struct CGPanelHeader: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack(spacing: 12) {

            // Avatar
            Image("Coque")
                .resizable()
                .scaledToFill()
                .frame(width: 42, height: 42)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.accentColor.opacity(0.4), lineWidth: 2)
                )

            // Nombre y estado
            VStack(alignment: .leading, spacing: 2) {
                Text("CoqueGuide")
                    .font(.headline)
                    .fontWeight(.semibold)

                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 7, height: 7)
                    Text("Asistente activo")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Ícono decorativo
            Image(systemName: "sparkles")
                .font(.system(size: 18))
                .foregroundStyle(Color.accentColor)
                .padding(.trailing, 4)

            // Botón cerrar
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Color(.systemGray3))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Barra de entrada de texto

private struct CGInputBar: View {

    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let isThinking: Bool
    let onSend: () -> Void

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isThinking
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {

            TextField("Escribe tu pregunta…", text: $text, axis: .vertical)
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color(.separator), lineWidth: 0.5)
                )
                .focused(isFocused)
                .disabled(isThinking)
                .onSubmit(onSend)

            // Botón de enviar
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(canSend ? Color.accentColor : Color(.systemGray4))
                    .animation(.easeInOut(duration: 0.2), value: canSend)
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color(.systemGroupedBackground))
    }
}
