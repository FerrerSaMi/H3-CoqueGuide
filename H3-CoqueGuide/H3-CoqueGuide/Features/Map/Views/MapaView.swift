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
    @State private var showServices: Bool = true
    @Environment(NavigationState.self) private var navigationState
    private let mapConfig = MapLocationsConfig.load()

    private var locations: [Int: MapLocation] {
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
        let allPins = currentLevel?.normalizedPins ?? []
        return showServices ? allPins : allPins.filter { $0.type != .service }
    }

    var body: some View {
        mapBody
            .onAppear { AnalyticsService.shared.track("map_opened") }
            .trackScreenTime("map")
            .onChange(of: navigationState.selectedMapLocationID) { _, newLocationID in
                if let locationID = newLocationID {
                    selectLocationFromGallery(locationID: locationID)
                }
            }
    }
    
    // MARK: - Navegación desde carrusel
    
    private func selectLocationFromGallery(locationID: Int) {
        if let location = locations[locationID] {
            // Determinar el nivel correcto
            if let mapLevel = mapConfig.levels.first(where: { $0.locations.contains(where: { $0.id == locationID }) }) {
                showingFirstMap = mapLevel.id == 1
            }
            
            // Seleccionar la ubicación
            selectedLocationNumber = locationID
            selectedLocationInfo = SelectedLocationInfo(
                id: location.id, name: location.name,
                type: location.locationType
            )
            
            // Resetear después de navegar
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                navigationState.selectedMapLocationID = nil
            }
        }
    }

    private var mapBody: some View {
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

            // MARK: - Instrucciones / Reset / Toggle servicios
            bottomBar
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(L10n.mapTitle)
        .navigationBarTitleDisplayMode(.inline)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedLocationInfo != nil)
    }

    // MARK: - Level Selector

    private var levelSelector: some View {
        HStack(spacing: 0) {
            levelTab(title: L10n.mapLevel1, isSelected: showingFirstMap) {
                switchLevel(toFirst: true)
            }
            levelTab(title: L10n.mapLevel2, isSelected: !showingFirstMap) {
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
                                if let location = locations[pin.number] {
                                    selectedLocationInfo = SelectedLocationInfo(
                                        id: pin.number,
                                        name: location.name,
                                        type: location.locationType
                                    )
                                }
                            }
                        }
                    } label: {
                        pinView(pin: pin)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(pin.type == .service ? L10n.mapServiceNamed(locations[pin.number]?.name ?? "") : L10n.mapPoint(pin.number))
                    .position(
                        x: imageRect.minX + (pin.x * imageRect.width),
                        y: imageRect.minY + (pin.y * imageRect.height)
                    )
                }

                // Overlay cuando el nivel no tiene pins (config corrupta o vacía).
                // Evita que el usuario vea un mapa sin nada y no sepa si falló algo.
                if currentPins.isEmpty {
                    emptyPinsOverlay
                        .position(x: size.width / 2, y: size.height / 2)
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
        let accentColor = pin.type.accentColor
        return ZStack {
            // Pulso exterior animado
            if isSelected {
                Circle()
                    .fill(accentColor.opacity(0.2))
                    .frame(width: pinButtonSize + 14, height: pinButtonSize + 14)
                    .scaleEffect(isSelected ? 1.3 : 1.0)
                    .opacity(isSelected ? 0.0 : 0.5)
                    .animation(
                        .easeOut(duration: 1.2).repeatForever(autoreverses: false),
                        value: isSelected
                    )
            }

            Circle()
                .fill(isSelected ? accentColor : Color.white)
                .frame(width: pinButtonSize, height: pinButtonSize)

            Circle()
                .stroke(accentColor, lineWidth: 2.5)
                .frame(width: pinButtonSize, height: pinButtonSize)

            // Mostrar ícono representativo en lugar de número
            Image(systemName: pin.locationIcon)
                .scalingFont(size: 14, weight: .bold)
                .foregroundStyle(isSelected ? .white : accentColor)
        }
        .shadow(color: isSelected ? accentColor.opacity(0.4) : .black.opacity(0.18), radius: isSelected ? 6 : 2, x: 0, y: isSelected ? 3 : 1)
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isSelected)
    }

    // MARK: - Location Info Card

    private func locationInfoCard(_ info: SelectedLocationInfo) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(info.type.accentColor)
                    .frame(width: 40, height: 40)

                if let symbol = info.type.symbolName {
                    Image(systemName: symbol)
                        .scalingFont(size: 18, weight: .bold)
                        .foregroundStyle(.white)
                } else {
                    Text("\(info.id)")
                        .scalingFont(size: 16, weight: .bold, design: .rounded)
                        .foregroundStyle(.white)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(info.type == .service ? L10n.mapService : L10n.mapPoint(info.id))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    Image(systemName: info.locationIcon)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(info.type.accentColor)
                    
                    Text(info.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
            }

            Spacer()

            Button {
                withAnimation {
                    selectedLocationNumber = nil
                    selectedLocationInfo = nil
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .scalingFont(size: 22)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.mapCloseInfo)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
    }

    // MARK: - Empty Pins Overlay

    /// Se muestra encima del mapa cuando el nivel no tiene ningún pin.
    /// Botón "Recargar" cambia `mapTransitionID` para forzar un re-render
    /// (y darle oportunidad a que `MapLocationsConfig` vuelva a leerse si
    /// en el futuro el config pasa a ser async).
    private var emptyPinsOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 32, weight: .regular))
                .foregroundStyle(.secondary)

            Text(L10n.mapEmptyPinsTitle)
                .font(.subheadline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)

            Text(L10n.mapEmptyPinsMessage)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button {
                withAnimation {
                    mapTransitionID = UUID()
                }
            } label: {
                Text(L10n.mapEmptyPinsReload)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .frame(maxWidth: 260)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 10) {
            // Toggle de servicios
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showServices.toggle()
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "figure.dress.line.vertical.figure")
                        .scalingFont(size: 12, weight: .semibold)
                    Text(L10n.mapServices)
                        .scalingFont(size: 12, weight: .semibold, relativeTo: .caption)
                }
                .foregroundStyle(showServices ? .white : .blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(showServices ? Color.blue : Color.blue.opacity(0.12))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(showServices ? L10n.mapHideServices : L10n.mapShowServices)

            Spacer()

            Label(L10n.mapPinchToZoom, systemImage: "hand.pinch")
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
                        .scalingFont(size: 12, weight: .semibold)
                    Text(L10n.mapReset)
                        .scalingFont(size: 12, weight: .semibold, relativeTo: .caption)
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

/// Tipo de ubicación del mapa. Determina el estilo visual del pin.
enum LocationType: String, Decodable {
    case attraction
    case service
    case shop

    var accentColor: Color {
        switch self {
        case .attraction: return .orange
        case .service:    return .blue
        case .shop:       return .yellow
        }
    }

    /// SF Symbol mostrado dentro del pin. `nil` significa que se muestra el número.
    var symbolName: String? {
        switch self {
        case .attraction: return nil
        case .service:    return "figure.dress.line.vertical.figure"
        case .shop:       return "bag.fill"
        }
    }
}

struct MapPin: Identifiable {
    let number: Int
    let name: String
    let x: CGFloat
    let y: CGFloat
    let type: LocationType

    var id: Int { number }
    
    /// Ícono representativo basado en el nombre del lugar
    var locationIcon: String {
        let name = self.name.lowercased()
        
        // Búsquedas específicas PRIMERO (multi-palabra)
        if name.contains("ciencia en vivo") || name.contains("live") { return "video.fill" }
        if name.contains("show del horno") || name.contains("furnace show") { return "flame.fill" }
        
        // Galerías
        if name.contains("historia") { return "book.fill" }
        if name.contains("acero") || name.contains("steel") { return "gearshape.fill" }
        if name.contains("horno") || name.contains("furnace") { return "flame.fill" }
        if name.contains("planeta") || name.contains("tierra") || name.contains("earth") { return "globe" }
        
        // Laboratorios
        if name.contains("laboratorio") || name.contains("laboratory") { return "flask.fill" }
        if name.contains("ventana") { return "telescope" }
        if name.contains("ciencia") || name.contains("science") { return "microscope" }
        if name.contains("núcleo") || name.contains("nucleo") { return "atom" }
        
        // Espacios
        if name.contains("terraza") || name.contains("green") { return "leaf.fill" }
        if name.contains("mirador") || name.contains("viewpoint") { return "binoculars.fill" }
        if name.contains("lobby") || name.contains("vestíbulo") { return "door.left.hand.open" }
        if name.contains("patio") { return "tree.fill" }
        if name.contains("explanada") { return "square.fill" }
        
        // Salones
        if name.contains("salón") || name.contains("salon") { return "building.2.fill" }
        if name.contains("newton") || name.contains("galilei") || name.contains("curie") { return "lightbulb.fill" }
        if name.contains("simulación") || name.contains("simulation") { return "play.circle.fill" }
        if name.contains("manufactura") || name.contains("manufacturing") { return "wrench.and.screwdriver.fill" }
        if name.contains("diseño") || name.contains("design") { return "paintbrush.fill" }
        if name.contains("lingote") { return "cube.fill" }
        if name.contains("andador") { return "arrow.right" }
        
        // Servicios
        if type == .service {
            if name.contains("baño") || name.contains("restroom") { return "figure.dress.line.vertical.figure" }
        }
        
        // Tiendas
        if type == .shop {
            if name.contains("guardaropa") || name.contains("coat") { return "hanger" }
            return "bag.fill"
        }
        
        // Default
        return "mappin.circle.fill"
    }
}

private struct SelectedLocationInfo: Identifiable, Equatable {
    let id: Int
    let name: String
    let type: LocationType
    
    /// Ícono representativo basado en el nombre del lugar
    var locationIcon: String {
        let name = self.name.lowercased()
        
        // Búsquedas específicas PRIMERO (multi-palabra)
        if name.contains("ciencia en vivo") || name.contains("live") { return "video.fill" }
        if name.contains("show del horno") || name.contains("furnace show") { return "flame.fill" }
        
        // Galerías
        if name.contains("historia") { return "book.fill" }
        if name.contains("acero") || name.contains("steel") { return "gearshape.fill" }
        if name.contains("horno") || name.contains("furnace") { return "flame.fill" }
        if name.contains("planeta") || name.contains("tierra") || name.contains("earth") { return "globe" }
        
        // Laboratorios
        if name.contains("laboratorio") || name.contains("laboratory") { return "flask.fill" }
        if name.contains("ventana") { return "telescope" }
        if name.contains("ciencia") || name.contains("science") { return "microscope" }
        if name.contains("núcleo") || name.contains("nucleo") { return "atom" }
        
        // Espacios
        if name.contains("terraza") || name.contains("green") { return "leaf.fill" }
        if name.contains("mirador") || name.contains("viewpoint") { return "binoculars.fill" }
        if name.contains("lobby") || name.contains("vestíbulo") { return "door.left.hand.open" }
        if name.contains("patio") { return "tree.fill" }
        if name.contains("explanada") { return "square.fill" }
        
        // Salones
        if name.contains("salón") || name.contains("salon") { return "building.2.fill" }
        if name.contains("newton") || name.contains("galilei") || name.contains("curie") { return "lightbulb.fill" }
        if name.contains("simulación") || name.contains("simulation") { return "play.circle.fill" }
        if name.contains("manufactura") || name.contains("manufacturing") { return "wrench.and.screwdriver.fill" }
        if name.contains("diseño") || name.contains("design") { return "paintbrush.fill" }
        
        // Servicios
        if type == .service {
            if name.contains("baño") || name.contains("restroom") { return "figure.dress.line.vertical.figure" }
        }
        
        // Tiendas
        if type == .shop {
            if name.contains("guardaropa") || name.contains("coat") { return "hanger" }
            return "bag.fill"
        }
        
        // Default
        return "mappin.circle.fill"
    }
}

struct MapLocationsConfig: Decodable {
    let levels: [MapLevel]

    var allLocations: [Int: MapLocation] {
        var dictionary: [Int: MapLocation] = [:]
        for level in levels {
            for location in level.locations {
                dictionary[location.id] = location
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
                MapLocation(id: 1, name: "Laboratorio de Innovación", type: nil, x: 348, y: 810),
                MapLocation(id: 2, name: "Laboratorio Una Ventana a la Ciencia", type: nil, x: 475, y: 810),
                MapLocation(id: 3, name: "Lobby", type: nil, x: 595, y: 785),
                MapLocation(id: 4, name: "Vestíbulo de la Galería de la Historia", type: nil, x: 555, y: 465),
                MapLocation(id: 5, name: "Vestíbulo de la Galería del Acero", type: nil, x: 425, y: 535),
                MapLocation(id: 6, name: "Núcleo Científico", type: nil, x: 372, y: 415),
                MapLocation(id: 7, name: "Salones (Newton, Galilei, Curie)", type: nil, x: 278, y: 205),
                MapLocation(id: 8, name: "Explanada Estufas", type: nil, x: 692, y: 305),
                MapLocation(id: 9, name: "Patio de Demostraciones", type: nil, x: 692, y: 485),
                MapLocation(id: 10, name: "Andador a El Lingote", type: nil, x: 812, y: 805),
                MapLocation(id: 11, name: "Salón Ciencia en Vivo", type: nil, x: 922, y: 915),
                MapLocation(id: 12, name: "Salón Diseño y Simulación", type: nil, x: 822, y: 915),
                MapLocation(id: 13, name: "Salón Manufactura Inteligente", type: nil, x: 715, y: 915),
                MapLocation(id: 14, name: "Baños Nivel 1", type: "service", x: 475, y: 700)
            ]
        ),
        MapLevel(
            id: 2,
            imageName: "MapaN2",
            locations: [
                MapLocation(id: 15, name: "Terraza verde", type: nil, x: 162, y: 442),
                MapLocation(id: 16, name: "Salón Show del horno", type: nil, x: 388, y: 355)
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
                name: location.name,
                x: min(max((location.x * xAxisScaleFactor) / imageSize.width, 0), 1),
                y: min(max(location.y / imageSize.height, 0), 1),
                type: location.locationType
            )
        }
    }
}

struct MapLocation: Decodable {
    let id: Int
    let name: String
    /// Tipo (raw string). Ver `locationType` para el enum resuelto.
    let type: String?
    let x: CGFloat
    let y: CGFloat

    /// Tipo resuelto con fallback a `.attraction` si falta o no es reconocido.
    var locationType: LocationType {
        guard let type, let parsed = LocationType(rawValue: type) else {
            return .attraction
        }
        return parsed
    }
}

#Preview {
    NavigationStack {
        MapaView()
    }
}
