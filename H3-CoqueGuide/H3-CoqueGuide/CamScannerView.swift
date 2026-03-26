//
//  CamScanner.swift
//  
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

    // MARK: Services
    @StateObject private var camera = CameraService()
    @StateObject private var speech = SpeechService()

    // MARK: State
    @State private var detectedObject: MuseumObject? = nil
    @State private var isPanelExpanded = false
    @State private var isScanning = false

    // MARK: - Body

    var body: some View {
        ZStack {
            // 1. Live camera feed
            CameraPreview(session: camera.session)
                .ignoresSafeArea()

            // 2. Scanner frame overlay
            ScannerFrameOverlay(isScanning: isScanning)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // 3. UI layers
            VStack(spacing: 0) {
                topBar
                Spacer()
                bottomArea
            }

            // 4. Permission denied
            if camera.isPermissionDenied {
                permissionDeniedOverlay
            }
        }
        .onAppear {
            camera.startSession()
            startScanSimulation()
        }
        .onDisappear {
            camera.stopSession()
            speech.stop()           
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

            // Placeholder flash (Sprint 2)
            Button { } label: {
                Image(systemName: "bolt.slash.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(.black.opacity(0.45))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Bottom Area

    private var bottomArea: some View {
        VStack(spacing: 0) {
            if let obj = detectedObject {
                infoPanel(obj)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 12)
            }
            shutterButton
                .padding(.bottom, 44)
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: detectedObject != nil)
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
            }

            // Descripción
            Text(obj.description)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.88))
                .lineSpacing(3)
                .lineLimit(isPanelExpanded ? nil : 3)

            // Barra de progreso de lectura (visible solo mientras habla)
            if speech.isSpeaking {
                SpeechProgressBar(progress: speech.progress)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            // Acciones
            HStack(spacing: 12) {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isPanelExpanded.toggle()
                    }
                } label: {
                    Text(isPanelExpanded ? "Ver menos" : "Ver más")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.orange)
                }

                Spacer()

                speakButton(for: obj)
            }
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .animation(.easeInOut(duration: 0.2), value: speech.isSpeaking)
    }

    // MARK: - Speak Button

    private func speakButton(for obj: MuseumObject) -> some View {
        Button {
            speech.toggle(obj.description)
        } label: {
            HStack(spacing: 6) {
                ZStack {
                    Image(systemName: "speaker.wave.2.fill")
                        .opacity(speech.isSpeaking ? 0 : 1)
                    Image(systemName: "stop.fill")
                        .opacity(speech.isSpeaking ? 1 : 0)
                }
                .font(.system(size: 13))
                .animation(.easeInOut(duration: 0.18), value: speech.isSpeaking)

                Text(speech.isSpeaking ? "Detener" : "Escuchar")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(speech.isSpeaking ? Color.white : Color.orange)
            .clipShape(Capsule())
            .animation(.easeInOut(duration: 0.2), value: speech.isSpeaking)
        }
    }

    // MARK: - Shutter Button

    private var shutterButton: some View {
        Button { triggerScan() } label: {
            ZStack {
                Circle()
                    .strokeBorder(.white.opacity(0.5), lineWidth: 3)
                    .frame(width: 72, height: 72)
                Circle()
                    .fill(isScanning ? Color.orange : Color.white)
                    .frame(width: 58, height: 58)
                    .scaleEffect(isScanning ? 0.88 : 1.0)
                    .animation(.easeInOut(duration: 0.35), value: isScanning)

                if isScanning {
                    ProgressView().tint(.black).scaleEffect(1.1)
                }
            }
        }
        .disabled(isScanning)
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
        }
        .padding(28)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(.white.opacity(0.15), lineWidth: 1)
        )
        .padding(32)
    }

    // MARK: - Scan Logic

    /// Simulación Sprint 1. En Sprint 2 se reemplaza por llamada a CoqueGuideAI.
    private func startScanSimulation() {
        isScanning = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            isScanning = false
            withAnimation {
                detectedObject = MuseumObject.sampleHorno3
            }
        }
    }

    private func triggerScan() {
        guard !isScanning else { return }
        speech.stop()           // Cancela cualquier audio al re-escanear
        detectedObject  = nil
        isPanelExpanded = false
        startScanSimulation()
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

// MARK: - Museum Object Model

struct MuseumObject: Identifiable, Equatable {
    let id          = UUID()
    let title       : String
    let era         : String
    let description : String
    let confidence  : Double

    static let sampleHorno3 = MuseumObject(
        title: "Horno 3",
        era: "CA. 1950s",
        description: "El Horno 3 fue uno de los altos hornos centrales de la Fundidora de Fierro y Acero de Monterrey. Operó durante décadas como corazón siderúrgico del noreste de México, transformando mineral de hierro en acero mediante temperaturas superiores a los 1 500 °C. Su cierre en 1986 marcó el fin de una era industrial y el inicio de su reconversión en parque cultural.",
        confidence: 0.94
    )
}

// MARK: - Preview

#Preview {
    CamScannerView()
}
