//
//  ScreenTimeModifier.swift
//  H3-CoqueGuide
//
//  Mide el tiempo que el usuario pasa en una pantalla y lo reporta como
//  evento `screen_time` con metadata `{ screen, seconds }`.
//
//  Uso:
//      SomeView()
//          .trackScreenTime("map")
//

import SwiftUI

struct ScreenTimeModifier: ViewModifier {
    let screen: String

    @State private var appearedAt: Date?

    func body(content: Content) -> some View {
        content
            .onAppear {
                appearedAt = Date()
            }
            .onDisappear {
                guard let start = appearedAt else { return }
                let seconds = Int(Date().timeIntervalSince(start))
                appearedAt = nil
                // Ignoramos aperturas fugaces (< 1s) para no inundar la tabla.
                guard seconds >= 1 else { return }
                AnalyticsService.shared.track("screen_time", metadata: [
                    "screen": screen,
                    "seconds": seconds,
                ])
            }
    }
}

extension View {
    func trackScreenTime(_ screen: String) -> some View {
        modifier(ScreenTimeModifier(screen: screen))
    }
}
