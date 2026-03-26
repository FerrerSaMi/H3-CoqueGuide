//
//  MapaView.swift
//  H3-CoqueGuide
//
//  Created by David Cantú Cabello on 15/03/26.
//

import SwiftUI
import UIKit

struct MapaView: View {
    private let pinButtonSize: CGFloat = 27
    @State private var showingFirstMap: Bool = true
    @State private var selectedLocationNumber: Int? = nil
    @State private var mapScale: CGFloat = 1.0
    @State private var lastMapScale: CGFloat = 1.0
    @State private var mapOffset: CGSize = .zero
    @State private var lastMapOffset: CGSize = .zero
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
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    Button {
                        showingFirstMap.toggle()
                        resetMapTransform()
                    } label: {
                        Text(showingFirstMap ? "Cambiar a Nivel 2" : "Cambiar a Nivel 1")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        resetMapTransform()
                    } label: {
                        Label("Reset Zoom", systemImage: "arrow.counterclockwise")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)

                    Spacer()
                }

                mapCanvas
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )

                if let selectedLocationNumber,
                   let locationName = locations[selectedLocationNumber] {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Punto \(selectedLocationNumber)")
                            .font(.headline)
                        Text(locationName)
                            .font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .navigationTitle("Mapa")
        .navigationBarTitleDisplayMode(.inline)
    }

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

                ForEach(currentPins) { pin in
                    Button {
                        selectedLocationNumber = pin.number
                    } label: {
                        ZStack {
                            Circle()
                                .fill(selectedLocationNumber == pin.number ? Color.accentColor : Color.white)
                                .frame(width: pinButtonSize, height: pinButtonSize)

                            Circle()
                                .stroke(Color.accentColor, lineWidth: 2)
                                .frame(width: pinButtonSize, height: pinButtonSize)

                            Text("\(pin.number)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(selectedLocationNumber == pin.number ? Color.white : Color.accentColor)
                        }
                        .shadow(color: .black.opacity(0.18), radius: 2, x: 0, y: 1)
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
        MagnificationGesture()
            .onChanged { value in
                let nextScale = lastMapScale * value
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
        withAnimation(.easeInOut(duration: 0.2)) {
            mapScale = 1.0
            lastMapScale = 1.0
            mapOffset = .zero
            lastMapOffset = .zero
        }
    }

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

private struct MapPin: Identifiable {
    let number: Int
    let x: CGFloat
    let y: CGFloat

    var id: Int { number }
}

private struct MapLocationsConfig: Decodable {
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

private struct MapLevel: Decodable {
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

        return locations.map { location in
            MapPin(
                number: location.id,
                x: min(max((location.x * xAxisScaleFactor) / image.size.width, 0), 1),
                y: min(max(location.y / image.size.height, 0), 1)
            )
        }
    }
}

private struct MapLocation: Decodable {
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
