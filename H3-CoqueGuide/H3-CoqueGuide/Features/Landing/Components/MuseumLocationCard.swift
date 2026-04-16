//
//  MuseumLocationCard.swift
//  H3-CoqueGuide
//
//  Tarjeta con mini mapa y ubicación del Museo del Acero Horno3.
//

import SwiftUI
import MapKit

struct MuseumLocationCard: View {

    // Coordenadas del Museo del Acero Horno3
    private let museumCoordinate = CLLocationCoordinate2D(
        latitude: 25.6785,
        longitude: -100.2842
    )

    private let museumAddress = "Av. Fundidora 501, Col. Obrera, 64010 Monterrey, N.L."

    @State private var cameraPosition: MapCameraPosition

    init() {
        let coordinate = CLLocationCoordinate2D(latitude: 25.6785, longitude: -100.2842)
        _cameraPosition = State(initialValue: .region(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
            )
        ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.12))
                        .frame(width: 40, height: 40)

                    Image(systemName: "mappin.and.ellipse")
                        .scalingFont(size: 18, weight: .semibold)
                        .foregroundStyle(.red)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.locationFindUs)
                        .font(.headline)
                        .fontWeight(.bold)

                    Text("Museo del Acero Horno3")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Mini mapa
            Map(position: $cameraPosition, interactionModes: []) {
                Marker("Horno3", systemImage: "building.columns.fill", coordinate: museumCoordinate)
                    .tint(.orange)
            }
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .allowsHitTesting(false)

            // Dirección
            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                    .scalingFont(size: 12, relativeTo: .caption)
                    .foregroundStyle(.secondary)

                Text(museumAddress)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            // Botón "Cómo llegar"
            Button {
                openInMaps()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                        .scalingFont(size: 14, weight: .semibold)

                    Text(L10n.locationHowToGetThere)
                        .scalingFont(size: 15, weight: .semibold, relativeTo: .subheadline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.orange)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.locationOpenInMapsA11y)
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    // MARK: - Abrir en Apple Maps

    private func openInMaps() {
        let placemark = MKPlacemark(coordinate: museumCoordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "Museo del Acero Horno3"
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}
