//
//  H3_CoqueGuideApp.swift
//  H3-CoqueGuide
//
//  Created by David Cantú Cabello on 12/03/26.
//


import SwiftUI
import SwiftData

@main
struct H3_CoqueGuideApp: App {
    var body: some Scene {
        WindowGroup {
            LandingView()
        }
        .modelContainer(for: [CoqueGuide.self])
    }
}

