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
    private let availableLanguages = ["Español", "English", "Français", "Português", "Korean", "Arabic"]

    // MARK: - Body

    var body: some View {
        ZStack {
            CameraPreview(session: viewModel.camera.session)
                .ignoresSafeArea()

            if isIntroVisible {
                Color.black.opacity(0.42)
                    .ignoresSafeArea()
                    .transition(.opacity)

                VStack {
                    Spacer()

                    SimpleCardView(
                        title: "Cómo usar el escáner",
                        description: "Apunta al objeto del museo con la cámara y pulsa Continuar. El escáner te mostrará la etiqueta del objeto y la confianza del modelo en el resultado.",
                        actionTitle: "Continuar"
                    ) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            isIntroVisible = false
                        }
                        viewModel.onAppear()
                    }
                    .frame(maxWidth: 360)
                    .padding(.horizontal, 24)

                    Spacer()
                }
            }

            if !isIntroVisible {
                VStack {
                    Spacer()

                    VStack(spacing: 16) {
                        if let text = viewModel.extractedText {
                            VStack(alignment: .leading, spacing: 14) {
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

                                HStack {
                                    Text("Traducir a:")
                                        .font(.system(.caption, design: .default))
                                        .foregroundColor(.white.opacity(0.8))

                                    Spacer()

                                    Button(action: {
                                        showLanguagePicker = true
                                    }) {
                                        Text(viewModel.selectedTranslationLanguage)
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color.blue.opacity(0.25))
                                            .clipShape(Capsule())
                                    }
                                }

                                if let translated = viewModel.translatedText {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("Traducido")
                                            .font(.system(.headline, design: .default))
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .lineSpacing(4)

                                        Text(translated)
                                            .font(.system(.body, design: .default))
                                            .foregroundColor(.white)
                                            .lineSpacing(6)
                                            .multilineTextAlignment(.leading)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                } else {
                                    Button("Traducir") {
                                        Task { await viewModel.translateExtractedText() }
                                    }
                                    .foregroundColor(.white)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue.opacity(0.8))
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
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
                        }

                        HStack(spacing: 16) {
                            Button("Extraer Texto") {
                                Task { await viewModel.extractText() }
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green.opacity(0.7))
                            .cornerRadius(8)

                            shutterButton
                        }
                    }
                    .padding(.bottom, max(24, bottomSafeArea + 18))
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
        .onAppear {
            viewModel.loadVisitorProfile(from: modelContext)
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
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 94, height: 94)

                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 78, height: 78)

                Circle()
                    .fill(viewModel.isScanning ? Color.orange : Color.white)
                    .frame(width: 58, height: 58)
                    .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 4)

                if viewModel.isScanning {
                    ProgressView()
                        .tint(.black)
                        .scaleEffect(1.1)
                }
            }
            .frame(width: 94, height: 94)
        }
        .buttonStyle(ShutterScaleButtonStyle())
        .disabled(viewModel.isScanning)
        .accessibilityLabel("Escanear objeto")
        .accessibilityHint("Toma una foto y clasifica el objeto detectado")
    }
}

private struct ShutterScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.26, dampingFraction: 0.7, blendDuration: 0), value: configuration.isPressed)
    }
}

private struct BottomSafeAreaKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - Preview

#Preview {
    CamScannerView()
}
