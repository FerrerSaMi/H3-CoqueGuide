//
//  SurveyView.swift
//  H3-CoqueGuide
//
//  Created by Santiago ferrer on 13/03/26.
//

import SwiftUI
import SwiftData

struct SurveyView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = SurveyViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Encuesta para mejor experiencia")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)

                GroupBox("TUS DATOS") {
                    VStack(spacing: 14) {
                        TextField("Escribe aqui tu nombre", text: $viewModel.name)
                            .textFieldStyle(.roundedBorder)

                        TextField("Escribe tu edad (ej: 21)", text: $viewModel.ageText)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("¿Qué prefieres para tu paseo por Horno3?")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            ForEach(viewModel.allPreferences, id: \.self) { preference in
                                Button {
                                    viewModel.togglePreference(preference)
                                } label: {
                                    HStack {
                                        Image(systemName: viewModel.selectedPreferences.contains(preference) ? "checkmark.square.fill" : "square")
                                        Text(preference)
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        TextField("Cuanto tiempo tienes (ej: 2 horas y media)", text: $viewModel.availableTime)
                            .textFieldStyle(.roundedBorder)

                        TextField("¿Buscas algo en específico?", text: $viewModel.specificSearch, axis: .vertical)
                            .lineLimit(3...5)
                            .textFieldStyle(.roundedBorder)

                        Picker("Idioma preferido", selection: $viewModel.preferredLanguage) {
                            ForEach(viewModel.languageOptions, id: \.self) { language in
                                Text(language).tag(language)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding(.top, 8)
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    Task {
                        await viewModel.saveSurvey(in: modelContext)
                    }
                } label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("Guardar y generar descripcion del usuario")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)

                Button("Volver a tomar encuesta") {
                    Task {
                        await viewModel.saveSurvey(in: modelContext)
                    }
                }
                .buttonStyle(.bordered)

                if !viewModel.aiDescription.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Descripcion:")
                            .font(.headline)

                        Text(viewModel.aiDescription)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .navigationTitle("Encuesta")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.loadExistingProfile(from: modelContext)
        }
    }
}

#Preview {
    SurveyView()
}
