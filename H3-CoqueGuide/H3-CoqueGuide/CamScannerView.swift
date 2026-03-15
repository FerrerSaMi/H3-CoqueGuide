//
//  CamScanner.swift
//  
//
//  Created by Angel De Jesus Sanchez Figueroa on 15/03/26.
//

import SwiftUI
import AVFoundation

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
