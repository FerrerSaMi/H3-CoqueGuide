//
//  CGFloatingButton.swift
//  CoqueGuideAI
//
//  Botón flotante reutilizable que activa el panel de CoqueGuide.
//  Se puede colocar en cualquier vista de la app mediante `.overlay`.
//

import SwiftUI

// MARK: - Botón flotante

/// Botón circular que muestra el avatar de CoqueGuide.
/// Incluye badge de notificaciones y animación de rebote cuando
/// llega una sugerencia proactiva.
struct CGFloatingButton: View {

    @ObservedObject var viewModel: CGViewModel
    let onTap: () -> Void

    @State private var isBouncing: Bool = false

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {

                // Avatar de CoqueGuide
                Image("Coque")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.25), radius: 5, x: 0, y: 3)
                    .overlay(
                        Circle()
                            .stroke(Color.accentColor.opacity(0.4), lineWidth: 2)
                    )
                    .scaleEffect(isBouncing ? 1.12 : 1.0)
                    .animation(
                        isBouncing
                            ? .spring(response: 0.35, dampingFraction: 0.45)
                                .repeatCount(2, autoreverses: true)
                            : .default,
                        value: isBouncing
                    )

                // Badge de sugerencias pendientes
                if viewModel.pendingSuggestionsCount > 0 {
                    badgeView
                        .transition(.scale(scale: 0.5).combined(with: .opacity))
                }
            }
        }
        .buttonStyle(CGPressableButtonStyle())
        .accessibilityLabel("CoqueGuide")
        .accessibilityHint("Abre el asistente del museo")
        // Rebota al aparecer una nueva sugerencia proactiva
        .onChange(of: viewModel.activeSuggestion?.id) { _, newID in
            guard newID != nil else { return }
            triggerBounce()
        }
    }

    // MARK: - Subvistas

    private var badgeView: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 20, height: 20)
                .shadow(color: Color.accentColor.opacity(0.5), radius: 4, x: 0, y: 2)

            Text("\(min(viewModel.pendingSuggestionsCount, 9))")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
        }
        .offset(x: 3, y: -3)
    }

    // MARK: - Animación

    private func triggerBounce() {
        isBouncing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            isBouncing = false
        }
    }
}

// MARK: - Estilo de botón con efecto press

private struct CGPressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Overlay reutilizable para cualquier vista

/// Extensión que permite agregar el overlay de CoqueGuide a cualquier vista
/// con una sola línea de código.
extension View {

    /// Añade el botón flotante de CoqueGuide y el banner de sugerencias
    /// en la esquina inferior derecha de la vista.
    ///
    /// Uso:
    /// ```swift
    /// MyView()
    ///     .coqueGuideOverlay(viewModel: coqueGuideVM)
    /// ```
    func coqueGuideOverlay(viewModel: CGViewModel, hideFloatingButton: Bool = false, navigator: CGNavigationCoordinator) -> some View {
        self.modifier(CGOverlayModifier(viewModel: viewModel, hideFloatingButton: hideFloatingButton, navigator: navigator))
    }
}

// MARK: - ViewModifier del overlay

struct CGOverlayModifier: ViewModifier {

    @ObservedObject var viewModel: CGViewModel
    let hideFloatingButton: Bool
    let navigator: CGNavigationCoordinator

    // Posición persistida del botón flotante (offset desde la esquina inferior derecha)
    @AppStorage("cgFloatingButtonOffsetX") private var savedOffsetX: Double = 0
    @AppStorage("cgFloatingButtonOffsetY") private var savedOffsetY: Double = 0
    @State private var dragTranslation: CGSize = .zero

    private let buttonSize: CGFloat = 64
    private let horizontalPadding: CGFloat = 20
    private let verticalPadding: CGFloat = 88

    func body(content: Content) -> some View {
        GeometryReader { proxy in
            content
                .overlay(alignment: .bottomTrailing) {
                    VStack(alignment: .trailing, spacing: 10) {

                        // Banner de sugerencia proactiva (aparece encima del botón)
                        if let suggestion = viewModel.activeSuggestion {
                            CGSuggestionBanner(
                                suggestion: suggestion,
                                onAccept: { viewModel.acceptSuggestion(suggestion) },
                                onDismiss: { viewModel.dismissSuggestion() }
                            )
                            .frame(maxWidth: 260)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        // Botón flotante principal (draggable)
                        if !hideFloatingButton {
                            CGFloatingButton(viewModel: viewModel) {
                                viewModel.openPanel()
                            }
                            .offset(
                                x: clampedOffsetX(in: proxy.size) + dragTranslation.width,
                                y: clampedOffsetY(in: proxy.size) + dragTranslation.height
                            )
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 8)
                                    .onChanged { value in
                                        dragTranslation = value.translation
                                    }
                                    .onEnded { value in
                                        let proposedX = savedOffsetX + value.translation.width
                                        let proposedY = savedOffsetY + value.translation.height
                                        savedOffsetX = clamp(proposedX,
                                                             min: minOffsetX(in: proxy.size),
                                                             max: 0)
                                        savedOffsetY = clamp(proposedY,
                                                             min: minOffsetY(in: proxy.size),
                                                             max: 0)
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            dragTranslation = .zero
                                        }
                                    }
                            )
                            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: savedOffsetX)
                            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: savedOffsetY)
                        }
                    }
                    .padding(.trailing, horizontalPadding)
                    .padding(.bottom, verticalPadding)
                    .animation(.spring(response: 0.45, dampingFraction: 0.75), value: viewModel.activeSuggestion?.id)
                }
        }
        .sheet(isPresented: Binding(
            get: { viewModel.isPanelOpen },
            set: { viewModel.isPanelOpen = $0 }
        )) {
            CGPanelView(viewModel: viewModel)
                .environment(navigator)
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
        }
    }

    // MARK: - Clamping del offset

    /// Mínimo offset X permitido (mueve el botón hacia la izquierda del safe area).
    private func minOffsetX(in size: CGSize) -> CGFloat {
        -(size.width - buttonSize - horizontalPadding * 2)
    }

    /// Mínimo offset Y permitido (mueve el botón hacia arriba del safe area).
    private func minOffsetY(in size: CGSize) -> CGFloat {
        -(size.height - buttonSize - verticalPadding - 40)
    }

    private func clampedOffsetX(in size: CGSize) -> CGFloat {
        clamp(savedOffsetX, min: minOffsetX(in: size), max: 0)
    }

    private func clampedOffsetY(in size: CGSize) -> CGFloat {
        clamp(savedOffsetY, min: minOffsetY(in: size), max: 0)
    }

    private func clamp(_ value: Double, min lower: CGFloat, max upper: CGFloat) -> Double {
        Swift.min(Swift.max(value, Double(lower)), Double(upper))
    }
}
