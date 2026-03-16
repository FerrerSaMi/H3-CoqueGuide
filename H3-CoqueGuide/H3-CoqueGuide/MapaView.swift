//
//  MapaView.swift
//  H3-CoqueGuide
//
//  Created by David Cantú Cabello on 15/03/26.
//

import SwiftUI

struct MapaView: View {
    @State private var showingFirstMap: Bool = true
    @State private var selectedLocationNumber: Int? = nil

    private let locations: [Int: String] = [
        1: "Laboratorio de Innovacion",
        2: "Laboratorio Una Ventana a la Ciencia",
        3: "Lobby",
        4: "Vestibulo de la Galeria de la Historia",
        5: "Vestibulo de la Galeria del Acero",
        6: "Nucleo Cientifico",
        7: "Salon Isaac Newton / Salon Galileo Galilei / Salon Marie Curie",
        8: "Explanada Estufas",
        9: "Patio de Demostraciones",
        10: "Andador a El Lingote",
        11: "Salon Ciencia en Vivo",
        12: "Salon Diseno y Simulacion",
        13: "Salon Manufactura Inteligente",
        14: "Terraza verde",
        15: "Salon Show del horno"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    Button {
                        showingFirstMap.toggle()
                    } label: {
                        Text(showingFirstMap ? "Cambiar a Nivel 2" : "Cambiar a Nivel 1")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)

                    Spacer()
                }

                Image(showingFirstMap ? "MapaN1" : "MapaN2")
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Text("Selecciona un numero del mapa")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                    ForEach(1...15, id: \.self) { number in
                        Button {
                            selectedLocationNumber = number
                        } label: {
                            Text("\(number)")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(selectedLocationNumber == number ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                                .foregroundStyle(selectedLocationNumber == number ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }

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
}

#Preview {
    NavigationStack {
        MapaView()
    }
}
