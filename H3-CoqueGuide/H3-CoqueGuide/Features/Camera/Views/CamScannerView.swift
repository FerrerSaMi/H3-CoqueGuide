//
//  CamScannerView.swift
//  H3-CoqueGuide
//
//  Created by Angel De Jesus Sanchez Figueroa on 15/03/26.
//

import SwiftUI
import AVFoundation
import UIKit

// MARK: - CamScannerView

struct CamScannerView: View {

    // MARK: Environment
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var coqueGuideVM: CGViewModel

    // MARK: ViewModel
    @StateObject private var viewModel = CamScannerViewModel()

    // MARK: - Body

    var body: some View {
        ZStack {
            // 1. Live camera feed
            CameraPreview(session: viewModel.camera.session)
                .ignoresSafeArea()

            // 2. Scanner frame overlay
            ScannerFrameOverlay(isScanning: viewModel.isScanning)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // 3. UI layers
            VStack(spacing: 0) {
                topBar
                Spacer()
                bottomArea
            }

            // 4. Permission denied
            if viewModel.camera.isPermissionDenied {
                permissionDeniedOverlay
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .ignoresSafeArea(edges: .bottom)
        .preferredColorScheme(.dark)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(.black.opacity(0.45))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Cerrar escáner")

            Spacer()

            VStack(spacing: 2) {
                Text("ESCÁNER")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.6))
                Text("Apunta al objeto del museo")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
            }

            Spacer()

            // Flash toggle
            Button {
                viewModel.toggleFlash()
            } label: {
                Image(systemName: viewModel.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(viewModel.isFlashOn ? .yellow : .white)
                    .frame(width: 38, height: 38)
                    .background(.black.opacity(0.45))
                    .clipShape(Circle())
            }
            .accessibilityLabel(viewModel.isFlashOn ? "Apagar flash" : "Encender flash")
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Bottom Area

    private var bottomArea: some View {
        VStack(spacing: 0) {
            if let obj = viewModel.detectedObject {
                infoPanel(obj)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 4)
            }
            shutterButton
                .padding(.bottom, 16)
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: viewModel.detectedObject != nil)
    }

    // MARK: - Info Panel

    private func infoPanel(_ obj: MuseumObject) -> some View {
        VStack(alignment: .leading, spacing: 14) {

            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(obj.title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                    Text(obj.era)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.orange)
                        .tracking(1.5)
                }
                Spacer()
                Text("\(Int(obj.confidence * 100))%")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.orange)
                    .clipShape(Capsule())
                    .accessibilityLabel("Confianza: \(Int(obj.confidence * 100)) por ciento")
            }

            // Descripción
            Text(obj.description)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.88))
                .lineSpacing(3)
                .lineLimit(viewModel.isPanelExpanded ? nil : 3)

            // Barra de progreso de lectura (visible solo mientras habla)
            if viewModel.speech.isSpeaking {
                SpeechProgressBar(progress: viewModel.speech.progress)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .accessibilityLabel("Progreso de lectura")
                    .accessibilityValue("\(Int(viewModel.speech.progress * 100)) por ciento")
            }

            // Acciones
            HStack(spacing: 12) {
                Button {
                    viewModel.togglePanelExpanded()
                } label: {
                    Text(viewModel.isPanelExpanded ? "Ver menos" : "Ver más")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.orange)
                }
                .accessibilityHint("Expande o contrae la descripción del objeto")

                Spacer()

                speakButton(for: obj)
            }

            // CTA a Coque (solo cuando la pieza fue reconocida)
            if !obj.isUnknown {
                askCoqueButton(for: obj)
            }
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .animation(.easeInOut(duration: 0.2), value: viewModel.speech.isSpeaking)
    }

    // MARK: - Ask Coque Button

    private func askCoqueButton(for obj: MuseumObject) -> some View {
        Button {
            viewModel.speech.stop()
            let prompt = "Cuéntame más sobre \(obj.title)."
            coqueGuideVM.openPanelWithMessage(prompt)
            dismiss()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .bold))
                Text("Pregúntale a Coque")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Color.orange, Color.orange.opacity(0.78)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .accessibilityLabel("Pregúntale a Coque sobre \(obj.title)")
        .accessibilityHint("Cierra el escáner y abre el asistente con el contexto de la pieza")
    }

    // MARK: - Speak Button

    private func speakButton(for obj: MuseumObject) -> some View {
        Button {
            viewModel.toggleSpeech(for: obj.description)
        } label: {
            HStack(spacing: 6) {
                ZStack {
                    Image(systemName: "speaker.wave.2.fill")
                        .opacity(viewModel.speech.isSpeaking ? 0 : 1)
                    Image(systemName: "stop.fill")
                        .opacity(viewModel.speech.isSpeaking ? 1 : 0)
                }
                .font(.system(size: 13))
                .animation(.easeInOut(duration: 0.18), value: viewModel.speech.isSpeaking)

                Text(viewModel.speech.isSpeaking ? "Detener" : "Escuchar")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(viewModel.speech.isSpeaking ? Color.white : Color.orange)
            .clipShape(Capsule())
            .animation(.easeInOut(duration: 0.2), value: viewModel.speech.isSpeaking)
        }
        .accessibilityLabel(viewModel.speech.isSpeaking ? "Detener lectura" : "Escuchar descripción")
    }

    // MARK: - Shutter Button

    private var shutterButton: some View {
        Button { viewModel.triggerScan() } label: {
            ZStack {
                Circle()
                    .strokeBorder(.white.opacity(0.5), lineWidth: 3)
                    .frame(width: 72, height: 72)
                Circle()
                    .fill(viewModel.isScanning ? Color.orange : Color.white)
                    .frame(width: 58, height: 58)
                    .scaleEffect(viewModel.isScanning ? 0.88 : 1.0)
                    .animation(.easeInOut(duration: 0.35), value: viewModel.isScanning)

                if viewModel.isScanning {
                    ProgressView().tint(.black).scaleEffect(1.1)
                }
            }
        }
        .disabled(viewModel.isScanning)
        .accessibilityLabel("Escanear objeto")
        .accessibilityHint("Toma una foto y clasifica el objeto detectado")
    }

    // MARK: - Permission Denied Overlay

    private var permissionDeniedOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.slash.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)

            Text("Sin acceso a la cámara")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)

            Text("Activa el permiso en Configuración para usar el escaneo de objetos.")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Abrir Configuración")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.orange)
                    .clipShape(Capsule())
            }
            .accessibilityHint("Abre la configuración del sistema para activar el permiso de cámara")
        }
        .padding(28)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(.white.opacity(0.15), lineWidth: 1)
        )
        .padding(32)
    }
}

// MARK: - Speech Progress Bar

private struct SpeechProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.15))
                    .frame(height: 3)
                Capsule()
                    .fill(Color.orange)
                    .frame(width: geo.size.width * progress, height: 3)
                    .animation(.linear(duration: 0.1), value: progress)
            }
        }
        .frame(height: 3)
    }
}

// MARK: - Preview

#Preview {
    CamScannerView()
        .environmentObject(CGViewModel())
}
