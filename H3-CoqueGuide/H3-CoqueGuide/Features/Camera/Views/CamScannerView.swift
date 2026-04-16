//
//  CamScannerView.swift
//  H3-CoqueGuide
//
//  Created by Angel De Jesus Sanchez Figueroa on 15/03/26.
//

import SwiftUI
import AVFoundation

// MARK: - CamScannerView

struct CamScannerView: View {

    // MARK: ViewModel
    @StateObject private var viewModel = CamScannerViewModel()
    @State private var bottomSafeArea: CGFloat = 0
    @State private var isIntroVisible = true

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

                    shutterButton
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
        .onDisappear { viewModel.onDisappear() }
        .preferredColorScheme(.dark)
    }

    // MARK: - Shutter Button

    private var shutterButton: some View {
        Button { viewModel.triggerScan() } label: {
            ZStack {
                Circle()
                    .strokeBorder(Color.white.opacity(0.5), lineWidth: 3)
                    .frame(width: 72, height: 72)
                Circle()
                    .fill(viewModel.isScanning ? Color.orange : Color.white)
                    .frame(width: 58, height: 58)
                    .scaleEffect(viewModel.isScanning ? 0.88 : 1.0)
                    .animation(.easeInOut(duration: 0.35), value: viewModel.isScanning)

                if viewModel.isScanning {
                    ProgressView()
                        .tint(.black)
                        .scaleEffect(1.1)
                }
            }
        }
        .disabled(viewModel.isScanning)
        .accessibilityLabel("Escanear objeto")
        .accessibilityHint("Toma una foto y clasifica el objeto detectado")
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
