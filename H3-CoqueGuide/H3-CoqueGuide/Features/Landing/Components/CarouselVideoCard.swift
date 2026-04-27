//
//  CarouselVideoCard.swift
//  H3-CoqueGuide
//
//  Tarjeta del carrusel de la pantalla principal con video en bucle.
//

import SwiftUI
import AVKit
import Combine

struct CarouselVideoCard: View {
    let videoName: String
    let title: String
    let subtitle: String
    let fallbackImageName: String?
    let onTap: (() -> Void)?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LoopingVideoPlayerView(videoName: videoName, fallbackImageName: fallbackImageName)

            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0),
                    Color.black.opacity(0.65)
                ]),
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        .accessibilityLabel("\(title). \(subtitle)")
        .onTapGesture {
            onTap?()
        }
    }
}

private struct LoopingVideoPlayerView: View {
    @StateObject private var controller: LoopingVideoPlayerController

    init(videoName: String, fallbackImageName: String?) {
        _controller = StateObject(
            wrappedValue: LoopingVideoPlayerController(
                videoName: videoName,
                fallbackImageName: fallbackImageName
            )
        )
    }

    var body: some View {
        Group {
            if let player = controller.player {
                VideoPlayer(player: player)
                    .allowsHitTesting(false)
                    .onAppear {
                        controller.play()
                    }
                    .onDisappear {
                        controller.pause()
                    }
            } else if let fallbackImageName = controller.fallbackImageName {
                Image(fallbackImageName)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.black
            }
        }
        .clipped()
        .onAppear {
            controller.prepare()
            controller.play()
        }
        .onDisappear {
            controller.pause()
        }
    }
}

private final class LoopingVideoPlayerController: ObservableObject {
    @Published var player: AVQueuePlayer?
    let fallbackImageName: String?

    private let videoName: String
    private var looper: AVPlayerLooper?

    init(videoName: String, fallbackImageName: String?) {
        self.videoName = videoName
        self.fallbackImageName = fallbackImageName
    }

    func prepare() {
        guard player == nil else { return }
        guard let url = videoURL(named: videoName) else { return }

        let item = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer()
        queuePlayer.isMuted = true
        queuePlayer.actionAtItemEnd = .none
        looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        player = queuePlayer
    }

    func play() {
        DispatchQueue.main.async {
            self.player?.play()
        }
    }

    func pause() {
        player?.pause()
    }

    private func videoURL(named name: String) -> URL? {
        // Primero intentar cargar como NSDataAsset (desde Assets.xcassets)
        if let dataAsset = NSDataAsset(name: name) {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(name).mp4")
            try? dataAsset.data.write(to: url)
            return url
        }
        
        // Fallback: buscar directamente en el bundle
        let allowedExtensions = ["mp4", "mov", "m4v"]
        for fileExtension in allowedExtensions {
            if let url = Bundle.main.url(forResource: name, withExtension: fileExtension) {
                return url
            }
        }
        return nil
    }
}
