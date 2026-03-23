//
//  CamScanner.swift
//  
//
//  Created by Angel De Jesus Sanchez Figueroa on 15/03/26.
//

import SwiftUI
import AVFoundation
import UIKit

struct CamScannerView: View {

    @StateObject private var camera = CameraService()
    @State private var detectedText: String? = nil

    var body: some View {

        ZStack {

            CameraPreview(session: camera.session)
                .ignoresSafeArea()
                .onAppear {
                    camera.startSession()

                    // Simulación de detección por el momento, para el sprint 2 se dejara de simular
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        detectedText = "Horno 3 fue un alto horno utilizado para la producción de acero en Monterrey."
                    }
                }
                .onDisappear {
                    camera.stopSession()
                }

            if camera.isPermissionDenied {
                VStack(spacing: 12) {
                    Text("No hay acceso a la camara")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Activa el permiso en Configuracion para usar el escaneo.")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Button("Abrir Configuracion") {
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        UIApplication.shared.open(url)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(.black.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()
            }

            if let text = detectedText {

                VStack {

                    Spacer()

                    VStack(spacing: 12) {

                        Text(text)
                            .font(.body)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)

                        Button(action: {

                            // Dejamos la estructura del boton para el Sprint 2

                        }) {
                            Label("Escuchar", systemImage: "speaker.wave.2.fill")
                        }
                        .buttonStyle(.borderedProminent)

                    }
                    .padding()

                }
            }
        }
    }
}
