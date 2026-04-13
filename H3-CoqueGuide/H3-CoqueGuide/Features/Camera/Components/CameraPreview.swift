//
//  CameraPreview.swift
//  
//
//  Created by Angel De Jesus Sanchez Figueroa on 15/03/26.
//

import SwiftUI
import AVFoundation

// MARK: - UIKit Preview Layer

final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

// MARK: - SwiftUI Wrapper

struct CameraPreview: UIViewRepresentable {

    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session      = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.backgroundColor           = .black
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.previewLayer.session = session
    }
}

// MARK: - Scanner Frame Overlay

/// Dibuja un rectángulo con esquinas estilizadas para guiar el escaneo.
struct ScannerFrameOverlay: View {

    var isScanning: Bool
    var cornerLength: CGFloat = 28
    var cornerWidth: CGFloat  = 3.5
    var color: Color          = Color("AccentBrand", bundle: nil)  // Fallback blanco si no existe

    @State private var pulse = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width  * 0.78
            let h = geo.size.height * 0.44
            let x = (geo.size.width  - w) / 2
            let y = (geo.size.height - h) / 2

            ZStack {
                // Dimming externo
                Color.black.opacity(0.42)
                    .mask(
                        Rectangle()
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .frame(width: w, height: h)
                                    .blendMode(.destinationOut)
                            )
                    )

                // Esquinas
                CornerMarks(cornerLength: cornerLength, lineWidth: cornerWidth, color: resolvedColor)
                    .frame(width: w, height: h)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    .opacity(pulse ? 0.6 : 1.0)
                    .scaleEffect(pulse ? 0.985 : 1.0)
                    .animation(
                        isScanning
                            ? .easeInOut(duration: 0.9).repeatForever(autoreverses: true)
                            : .default,
                        value: pulse
                    )
            }
            .ignoresSafeArea()
            .onAppear { if isScanning { pulse = true } }
            .onChange(of: isScanning) { scanning in pulse = scanning }
        }
    }

    private var resolvedColor: Color {
        // Si el asset no existe usa un naranja industrial coherente con el museo
        Color(UIColor { _ in UIColor(named: "AccentBrand") ?? UIColor(red: 0.98, green: 0.55, blue: 0.14, alpha: 1) })
    }
}

// MARK: - Corner Marks Shape

private struct CornerMarks: View {
    let cornerLength: CGFloat
    let lineWidth: CGFloat
    let color: Color

    var body: some View {
        Canvas { ctx, size in
            let corners: [(CGPoint, [CGPoint])] = [
                (CGPoint(x: 0, y: 0),        [CGPoint(x: cornerLength, y: 0), CGPoint(x: 0, y: cornerLength)]),
                (CGPoint(x: size.width, y: 0), [CGPoint(x: size.width - cornerLength, y: 0), CGPoint(x: size.width, y: cornerLength)]),
                (CGPoint(x: 0, y: size.height), [CGPoint(x: cornerLength, y: size.height), CGPoint(x: 0, y: size.height - cornerLength)]),
                (CGPoint(x: size.width, y: size.height), [CGPoint(x: size.width - cornerLength, y: size.height), CGPoint(x: size.width, y: size.height - cornerLength)])
            ]

            for (origin, ends) in corners {
                for end in ends {
                    var path = Path()
                    path.move(to: origin)
                    path.addLine(to: end)
                    ctx.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(color.opacity(0.18), lineWidth: 1)
        )
    }
}
