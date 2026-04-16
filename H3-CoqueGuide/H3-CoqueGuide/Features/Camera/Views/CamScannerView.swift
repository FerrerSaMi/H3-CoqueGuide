//
//  CamScannerView.swift
//  H3-CoqueGuide
//
//  Created by Angel De Jesus Sanchez Figueroa on 15/03/26.
//

import SwiftUI
import AVFoundation
import SwiftData

// MARK: - CamScannerView

struct CamScannerView: View {

    // MARK: ViewModel
    @StateObject private var viewModel = CamScannerViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var bottomSafeArea: CGFloat = 0
    @State private var isIntroVisible = true
    @State private var showLanguagePicker = false

    // MARK: - Available Languages
    private var availableLanguages: [String] {
        viewModel.googleTranslationService.getSupportedLanguages()
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            CameraPreview(session: viewModel.camera.session)
                .ignoresSafeArea()

            if isIntroVisible {
                Color.black.opacity(0.42)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(1)

                VStack {
                    Spacer()

                    SimpleCardView(
                        title: "Cómo usar el escáner",
                        description: "Apunta al objeto del museo con la cámara y pulsa Continuar. El escáner te mostrará la etiqueta del objeto y la confianza del modelo en el resultado.",
                        actionTitle: "Continuar"
                    ) {
                        // Animar la salida de la intro y entrada de la cámara
                        withAnimation(.easeIn(duration: 0.4)) {
                            isIntroVisible = false
                        }
                        // Pequeño delay antes de iniciar la cámara para una transición suave
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            viewModel.onAppear()
                        }
                    }
                    .frame(maxWidth: 360)
                    .padding(.horizontal, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(2)

                    Spacer()
                }
            }

            if !isIntroVisible {
                VStack {
                    Spacer()

                    VStack(spacing: 16) {
                        if let text = viewModel.extractedText {
                            AnimatedTextResultCard(text: text, translation: viewModel.translatedText, viewModel: viewModel)
                        }

                        HStack(spacing: 16) {
                            AnimatedActionButton(
                                title: "Extraer Texto",
                                systemImage: "text.viewfinder",
                                color: .green
                            ) {
                                Task { await viewModel.extractText() }
                            }
                            .opacity(viewModel.extractedText == nil ? 1 : 0.6)
                            .scaleEffect(viewModel.extractedText == nil ? 1 : 0.95)

                            shutterButton
                        }
                    }
                    .padding(.bottom, max(24, bottomSafeArea + 18))
                    .opacity(isIntroVisible ? 0 : 1)
                    .offset(y: isIntroVisible ? 50 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: isIntroVisible)
                }
                .frame(maxWidth: .infinity)
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(key: BottomSafeAreaKey.self, value: proxy.safeAreaInsets.bottom)
                    }
                )
                .onPreferenceChange(BottomSafeAreaKey.self) { bottomSafeArea = $0 }
            }
        }
        .overlay {
            if viewModel.showFallbackUI {
                CameraErrorFallbackView(
                    errorMessage: viewModel.cameraError ?? "Error desconocido de cámara",
                    onRetry: viewModel.retryCameraSetup
                )
                .transition(.opacity)
            }
        }
        .overlay {
            if viewModel.showScanResults && !viewModel.isScanning && viewModel.detectedObject != nil {
                ScanSuccessIndicator()
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .onAppear {
            viewModel.loadVisitorProfile(from: modelContext)
            // Animar la transición de la intro con un pequeño delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.8)) {
                    // La transición ya está manejada en el botón de continuar
                }
            }
        }
        .onDisappear { viewModel.onDisappear() }
        .sheet(isPresented: $showLanguagePicker) {
            NavigationView {
                List(availableLanguages, id: \.self) { language in
                    Button(action: {
                        viewModel.selectedTranslationLanguage = language
                        viewModel.saveTranslationLanguagePreference(to: modelContext)
                        showLanguagePicker = false
                    }) {
                        HStack {
                            Text(language)
                            Spacer()
                            if viewModel.selectedTranslationLanguage == language {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .navigationTitle("Seleccionar idioma")
                .navigationBarItems(trailing: Button("Cancelar") {
                    showLanguagePicker = false
                })
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Shutter Button

    private var shutterButton: some View {
        Button { viewModel.triggerScan() } label: {
            ZStack {
                // Pulsing outer ring
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    .frame(width: 110, height: 110)
                    .scaleEffect(viewModel.isScanning ? 1.2 : 1.0)
                    .opacity(viewModel.isScanning ? 0 : 0.6)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: viewModel.isScanning)

                // Main background
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 94, height: 94)
                    .scaleEffect(viewModel.isScanning ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.isScanning)

                // Inner ring
                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 78, height: 78)
                    .scaleEffect(viewModel.isScanning ? 0.95 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.8), value: viewModel.isScanning)

                // Fill circle
                Circle()
                    .fill(viewModel.isScanning ? Color.orange : Color.white)
                    .frame(width: 58, height: 58)
                    .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 4)
                    .scaleEffect(viewModel.isScanning ? 0.9 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: viewModel.isScanning)

                // Progress indicator
                if viewModel.isScanning {
                    ProgressView()
                        .tint(.black)
                        .scaleEffect(1.1)
                        .transition(.scale.combined(with: .opacity))
                }

                // Success checkmark (briefly shown after scan)
                if viewModel.detectedObject != nil && !viewModel.isScanning {
                    Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                        .transition(.scale.combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    // This will trigger the transition out
                                }
                            }
                        }
                }
            }
            .frame(width: 94, height: 94)
            .contentShape(Circle())
        }
        .buttonStyle(ShutterButtonStyle())
        .disabled(viewModel.isScanning)
        .accessibilityLabel("Escanear objeto")
        .accessibilityHint("Toma una foto y clasifica el objeto detectado")
    }
}

private struct ShutterButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .brightness(configuration.isPressed ? -0.1 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6, blendDuration: 0), value: configuration.isPressed)
    }
}

private struct BottomSafeAreaKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - Animated Components

struct AnimatedTextResultCard: View {
    let text: String
    let translation: String?
    let viewModel: CamScannerViewModel

    @State private var isVisible = false
    @State private var showTranslation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Texto detectado
            VStack(alignment: .leading, spacing: 10) {
                Text("Texto detectado")
                    .font(.system(.headline, design: .default))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineSpacing(4)

                Text(text)
                    .font(.system(.body, design: .default))
                    .foregroundColor(.white)
                    .lineSpacing(6)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: isVisible)

            // Selector de idioma
            HStack {
                Text("Traducir a:")
                    .font(.system(.caption, design: .default))
                    .foregroundColor(.white.opacity(0.75))

                Spacer()

                Button(action: {
                    // This would need to be passed from parent
                }) {
                    Text(viewModel.selectedTranslationLanguage)
                        .font(.system(.caption, design: .default))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.25))
                        .clipShape(Capsule())
                }
            }
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 15)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: isVisible)

            // Traducción o estados de carga/error
            Group {
                if let translated = translation {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Traducción")
                            .font(.system(.headline, design: .default))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .lineSpacing(4)

                        Text(translated)
                            .font(.system(.body, design: .default))
                            .foregroundColor(.white.opacity(0.95))
                            .lineSpacing(6)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .background(Color.blue.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .transition(.slide.combined(with: .opacity))
                } else if viewModel.isDownloadingTranslationModel {
                    VStack(spacing: 12) {
                        ProgressView(value: viewModel.translationDownloadProgress)
                            .progressViewStyle(.linear)
                            .tint(.white)
                            .frame(height: 4)

                        Text("Descargando modelo de traducción...")
                            .font(.system(.caption, design: .default))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.vertical, 12)
                    .transition(.slide.combined(with: .opacity))
                } else if let error = viewModel.translationError {
                    VStack(spacing: 8) {
                        Text("Error de traducción")
                            .font(.system(.caption, design: .default))
                            .foregroundColor(.red.opacity(0.8))

                        Text(error)
                            .font(.system(.caption2, design: .default))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)

                        Button("Reintentar") {
                            Task { await viewModel.translateExtractedText() }
                        }
                        .font(.system(.caption, design: .default))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.6))
                        .clipShape(Capsule())
                    }
                    .padding(.vertical, 8)
                    .transition(.slide.combined(with: .opacity))
                } else {
                    Button("Traducir") {
                        Task { await viewModel.translateExtractedText() }
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .transition(.slide.combined(with: .opacity))
                }
            }
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 10)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: isVisible)
        }
        .padding(22)
        .background(.ultraThinMaterial)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 18, x: 0, y: 8)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 30)
        .animation(.spring(response: 0.6, dampingFraction: 0.75), value: isVisible)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    isVisible = true
                }
            }
        }
    }
}

struct AnimatedActionButton: View {
    let title: String
    let systemImage: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false
    @State private var isVisible = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.1, dampingFraction: 0.8)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.1, dampingFraction: 0.8)) {
                    isPressed = false
                }
            }
            action()
        }) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(color.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isVisible)
        .onAppear {
            withAnimation {
                isVisible = true
            }
        }
    }
}
    let errorMessage: String
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.white.opacity(0.6))

                Text("Error de Cámara")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(errorMessage)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button(action: onRetry) {
                    Text("Reintentar")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 8)
            }
            .padding()
        }
    }
}

// MARK: - Scan Success Indicator

struct ScanSuccessIndicator: View {
    @State private var isVisible = false
    @State private var scale: CGFloat = 0.5

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.2))
                .frame(width: 120, height: 120)
                .scaleEffect(scale)
                .opacity(isVisible ? 1 : 0)

            Circle()
                .fill(Color.green.opacity(0.4))
                .frame(width: 80, height: 80)
                .scaleEffect(scale * 0.8)
                .opacity(isVisible ? 1 : 0)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
                .scaleEffect(scale)
                .opacity(isVisible ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                isVisible = true
                scale = 1
            }

            // Auto-hide after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeOut(duration: 0.3)) {
                    isVisible = false
                    scale = 0.5
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CamScannerView()
}
