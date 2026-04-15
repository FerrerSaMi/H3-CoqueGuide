//
//  MapaView.swift
//  H3-CoqueGuide
//
//  Created by David Cantú Cabello on 15/03/26.
//

import SwiftUI
import UIKit

struct MapaView: View {
    private let pinButtonSize: CGFloat = 30
    @State private var showingFirstMap: Bool = true
    @State private var selectedLocationNumber: Int? = nil
    @State private var selectedLocationInfo: SelectedLocationInfo? = nil
    @State private var mapScale: CGFloat = 1.0
    @State private var lastMapScale: CGFloat = 1.0
    @State private var mapOffset: CGSize = .zero
    @State private var lastMapOffset: CGSize = .zero
    @State private var mapTransitionID = UUID()
    private let mapConfig = MapLocationsConfig.load()

    private var locations: [Int: String] {
        mapConfig.allLocations
    }

    private var currentLevelID: Int {
        showingFirstMap ? 1 : 2
    }

    private var currentLevel: MapLevel? {
        mapConfig.level(withID: currentLevelID)
    }

    private var currentMapName: String {
        currentLevel?.imageName ?? (showingFirstMap ? "MapaN1" : "MapaN2")
    }

    private var currentPins: [MapPin] {
        currentLevel?.normalizedPins ?? []
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header con selector de nivel
            levelSelector
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)

            // MARK: - Mapa
            mapCanvas
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                .padding(.horizontal, 16)

            // MARK: - Info del punto seleccionado
            if let info = selectedLocationInfo {
                locationInfoCard(info)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
            }

            Spacer()

            // MARK: - Instrucciones / Reset
            bottomBar
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Mapa del Museo")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedLocationInfo != nil)
    }

    // MARK: - Level Selector

    private var levelSelector: some View {
        HStack(spacing: 0) {
            levelTab(title: "Nivel 1", isSelected: showingFirstMap) {
                switchLevel(toFirst: true)
            }
            levelTab(title: "Nivel 2", isSelected: !showingFirstMap) {
                switchLevel(toFirst: false)
            }
        }
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func levelTab(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(isSelected ? .white : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSelected ? Color.orange : Color.clear)
                )
                .padding(2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private func switchLevel(toFirst: Bool) {
        guard showingFirstMap != toFirst else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            showingFirstMap = toFirst
            selectedLocationNumber = nil
            selectedLocationInfo = nil
            resetMapTransform()
            mapTransitionID = UUID()
        }
    }

    // MARK: - Map Canvas

    private var mapCanvas: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let imageRect = aspectFitRect(
                container: size,
                imageAspectRatio: imageAspectRatio(for: currentMapName)
            )

            ZStack(alignment: .topLeading) {
                Image(currentMapName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size.width, height: size.height)
                    .id(mapTransitionID)
                    .transition(.opacity)

                ForEach(currentPins) { pin in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            if selectedLocationNumber == pin.number {
                                selectedLocationNumber = nil
                                selectedLocationInfo = nil
                            } else {
                                selectedLocationNumber = pin.number
                                if let name = locations[pin.number] {
                                    selectedLocationInfo = SelectedLocationInfo(id: pin.number, name: name)
                                }
                            }
                        }
                    } label: {
                        pinView(pin: pin)
                    }
                    .buttonStyle(.plain)
                    .position(
                        x: imageRect.minX + (pin.x * imageRect.width),
                        y: imageRect.minY + (pin.y * imageRect.height)
                    )
                }
            }
            .frame(width: size.width, height: size.height)
            .scaleEffect(mapScale)
            .offset(mapOffset)
            .contentShape(Rectangle())
            .gesture(dragGesture)
            .simultaneousGesture(zoomGesture)
            .animation(.easeInOut(duration: 0.2), value: mapScale)
            .animation(.easeInOut(duration: 0.2), value: mapOffset)
        }
        .frame(height: 420)
    }

    // MARK: - Pin View

    private func pinView(pin: MapPin) -> some View {
        let isSelected = selectedLocationNumber == pin.number
        return ZStack {
            // Pulso exterior animado
            if isSelected {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: pinButtonSize + 14, height: pinButtonSize + 14)
                    .scaleEffect(isSelected ? 1.3 : 1.0)
                    .opacity(isSelected ? 0.0 : 0.5)
                    .animation(
                        .easeOut(duration: 1.2).repeatForever(autoreverses: false),
                        value: isSelected
                    )
            }

            Circle()
                .fill(isSelected ? Color.orange : Color.white)
                .frame(width: pinButtonSize, height: pinButtonSize)

            Circle()
                .stroke(isSelected ? Color.orange : Color.accentColor, lineWidth: 2.5)
                .frame(width: pinButtonSize, height: pinButtonSize)

            Text("\(pin.number)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(isSelected ? .white : Color.accentColor)
        }
        .shadow(color: isSelected ? Color.orange.opacity(0.4) : .black.opacity(0.18), radius: isSelected ? 6 : 2, x: 0, y: isSelected ? 3 : 1)
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isSelected)
    }

    // MARK: - Location Info Card

    private func locationInfoCard(_ info: SelectedLocationInfo) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 40, height: 40)

                Text("\(info.id)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Punto \(info.id)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Text(info.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }

            Spacer()

            Button {
                withAnimation {
                    selectedLocationNumber = nil
                    selectedLocationInfo = nil
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cerrar información")
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            Label("Pellizca para hacer zoom", systemImage: "hand.pinch")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    resetMapTransform()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Reset")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.12))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Gestures

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                mapOffset = CGSize(
                    width: lastMapOffset.width + value.translation.width,
                    height: lastMapOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastMapOffset = mapOffset
            }
    }

    private var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let nextScale = lastMapScale * value.magnification
                mapScale = min(max(nextScale, 1.0), 4.0)
            }
            .onEnded { _ in
                lastMapScale = mapScale
                if mapScale <= 1.01 {
                    mapScale = 1.0
                    lastMapScale = 1.0
                    mapOffset = .zero
                    lastMapOffset = .zero
                }
            }
    }

    private func resetMapTransform() {
        mapScale = 1.0
        lastMapScale = 1.0
        mapOffset = .zero
        lastMapOffset = .zero
    }

    // MARK: - Helpers

    private func imageAspectRatio(for imageName: String) -> CGFloat {
        guard let image = UIImage(named: imageName), image.size.height > 0 else {
            return 1.6
        }
        return image.size.width / image.size.height
    }

    private func aspectFitRect(container: CGSize, imageAspectRatio: CGFloat) -> CGRect {
        guard container.width > 0, container.height > 0, imageAspectRatio > 0 else {
            return CGRect(origin: .zero, size: container)
        }

        let containerAspect = container.width / container.height
        if containerAspect > imageAspectRatio {
            let height = container.height
            let width = height * imageAspectRatio
            let x = (container.width - width) / 2
            return CGRect(x: x, y: 0, width: width, height: height)
        } else {
            let width = container.width
            let height = width / imageAspectRatio
            let y = (container.height - height) / 2
            return CGRect(x: 0, y: y, width: width, height: height)
        }
    }
}

// MARK: - Models

struct MapPin: Identifiable {
    let number: Int
    let x: CGFloat
    let y: CGFloat

    var id: Int { number }
}

private struct SelectedLocationInfo: Identifiable {
    let id: Int
    let name: String
}

struct MapLocationsConfig: Decodable {
    let levels: [MapLevel]

    var allLocations: [Int: String] {
        var dictionary: [Int: String] = [:]
        for level in levels {
            for location in level.locations {
                dictionary[location.id] = location.name
            }
        }
        return dictionary
    }

    func level(withID id: Int) -> MapLevel? {
        levels.first(where: { $0.id == id })
    }

    static func load() -> MapLocationsConfig {
        guard let url = Bundle.main.url(forResource: "MapLocations", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(MapLocationsConfig.self, from: data) else {
            return .fallback
        }
        return decoded
    }

    static let fallback = MapLocationsConfig(levels: [
        MapLevel(
            id: 1,
            imageName: "MapaN1",
            locations: [
                MapLocation(id: 1, name: "Laboratorio de Innovación", x: 348, y: 810),
                MapLocation(id: 2, name: "Laboratorio Una Ventana a la Ciencia", x: 475, y: 810),
                MapLocation(id: 3, name: "Lobby", x: 595, y: 785),
                MapLocation(id: 4, name: "Vestíbulo de la Galería de la Historia", x: 555, y: 465),
                MapLocation(id: 5, name: "Vestíbulo de la Galería del Acero", x: 425, y: 535),
                MapLocation(id: 6, name: "Núcleo Científico", x: 372, y: 415),
                MapLocation(id: 7, name: "Salones (Newton, Galilei, Curie)", x: 278, y: 205),
                MapLocation(id: 8, name: "Explanada Estufas", x: 692, y: 305),
                MapLocation(id: 9, name: "Patio de Demostraciones", x: 692, y: 485),
                MapLocation(id: 10, name: "Andador a El Lingote", x: 812, y: 805),
                MapLocation(id: 11, name: "Salón Ciencia en Vivo", x: 922, y: 915),
                MapLocation(id: 12, name: "Salón Diseño y Simulación", x: 822, y: 915),
                MapLocation(id: 13, name: "Salón Manufactura Inteligente", x: 715, y: 915)
            ]
        ),
        MapLevel(
            id: 2,
            imageName: "MapaN2",
            locations: [
                MapLocation(id: 14, name: "Terraza verde", x: 162, y: 442),
                MapLocation(id: 15, name: "Salón Show del horno", x: 388, y: 355)
            ]
        )
    ])
}

struct MapLevel: Decodable {
    let id: Int
    let imageName: String
    let locations: [MapLocation]

    private var xAxisScaleFactor: CGFloat {
        id == 1 ? 1.70 : 1.30
    }

    var normalizedPins: [MapPin] {
        guard let image = UIImage(named: imageName), image.size.width > 0, image.size.height > 0 else {
            return []
        }

        return normalizedPins(forImageSize: image.size)
    }

    func normalizedPins(forImageSize imageSize: CGSize) -> [MapPin] {
        guard imageSize.width > 0, imageSize.height > 0 else {
            return []
        }

        return locations.map { location in
            MapPin(
                number: location.id,
                x: min(max((location.x * xAxisScaleFactor) / imageSize.width, 0), 1),
                y: min(max(location.y / imageSize.height, 0), 1)
            )
        }
    }
}

struct MapLocation: Decodable {
    let id: Int
    let name: String
    let x: CGFloat
    let y: CGFloat
}

#Preview {
    NavigationStack {
        MapaView()
    }
}
