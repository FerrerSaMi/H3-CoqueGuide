//
//  PlaceholderView.swift
//  H3-CoqueGuide
//
//  Vista placeholder para secciones en desarrollo.
//

import SwiftUI

struct PlaceholderView: View {
    let title: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "hammer")
                .scalingFont(size: 48, relativeTo: .largeTitle)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            Text(L10n.landingPlaceholderComingSoon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
