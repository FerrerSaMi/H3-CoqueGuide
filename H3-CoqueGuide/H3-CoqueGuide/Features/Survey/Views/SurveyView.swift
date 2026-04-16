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
    @EnvironmentObject private var coqueGuideVM: CGViewModel
    @StateObject private var viewModel = SurveyViewModel()
    @State private var showSurveyRequiredAlert = false
    @State private var isDescriptionExpanded = false

    private let optionColors: [Color] = [
        Color.orange.opacity(0.95),
        Color.orange.opacity(0.82),
        Color.orange.opacity(0.72),
        Color.orange.opacity(0.62),
        Color.orange.opacity(0.88),
        Color.orange.opacity(0.76),
        Color.orange.opacity(0.68),
        Color.orange.opacity(0.58)
    ]

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            switch viewModel.currentScreen {
            case .home:
                homeContent

            case .question:
                questionContent

            case .description:
                descriptionContent
            }
        }
        .navigationTitle("Encuesta")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.loadExistingProfile(from: modelContext)
        }
        .alert("Primero cuéntame de ti ✨", isPresented: $showSurveyRequiredAlert) {
            Button("Hacer encuesta") {
                viewModel.startSurvey()
            }
            Button("Después", role: .cancel) { }
        } message: {
            Text("Contesta la encuesta para que Coque pueda crear una ruta personalizada con tus gustos, tu tiempo y tu estilo de visita.")
        }
    }
}

private extension SurveyView {
    var homeContent: some View {
        VStack(spacing: 24) {
            Spacer()

            Image("Coque")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
                .shadow(radius: 10)

            Text("Encuesta para mejor experiencia")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundStyle(.primary)

            Text("Elige una opción para comenzar")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 16) {
                Button {
                    viewModel.startSurvey()
                } label: {
                    homeButton(title: "Hacer encuesta", icon: "play.fill")
                }
                .buttonStyle(.plain)

                Button {
                    viewModel.openDescription()
                } label: {
                    homeButton(title: "Ver descripción del usuario", icon: "person.text.rectangle.fill")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    var questionContent: some View {
        VStack(spacing: 18) {
            HStack {
                Button {
                    viewModel.goBackOneStepOrHome()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .frame(width: 42, height: 42)
                        .background(Color.orange.opacity(0.22))
                        .clipShape(Circle())
                }

                Spacer()

                Text(viewModel.progressText)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Spacer()

                Color.clear
                    .frame(width: 42, height: 42)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            VStack(spacing: 10) {
                Text(viewModel.currentStep.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 22)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .fill(Color.orange.opacity(0.16))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.orange.opacity(0.35), lineWidth: 1)
                    )

                if viewModel.currentStep == .attractionPreference {
                    Text("Si eliges “Recomendado”, se elegirá una opción según tus respuestas.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
            }
            .padding(.horizontal, 20)

            if viewModel.isLoading {
                Spacer()
                ProgressView("Generando descripción...")
                    .font(.headline)
                Spacer()
            } else {
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible(), spacing: 14),
                        count: viewModel.currentStep.columns
                    ),
                    spacing: 14
                ) {
                    ForEach(Array(viewModel.currentStep.options.enumerated()), id: \.element) { index, option in
                        Button {
                            viewModel.selectOption(option, in: modelContext)
                        } label: {
                            optionCard(
                                title: option,
                                color: optionColors[index % optionColors.count],
                                isSelected: viewModel.optionIsSelected(option)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                Spacer()
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
    }

    var descriptionContent: some View {
        ScrollView {
            VStack(spacing: 22) {
                Image("Coque")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 170, height: 170)
                    .padding(.top, 10)
                    .shadow(radius: 12)

                Text("Descripción del usuario")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Group {
                    if viewModel.aiDescription.isEmpty {
                        Text("Todavía no hay una descripción generada. Primero realiza la encuesta.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding()
                    } else {
                        VStack(spacing: 0) {
                            Button {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isDescriptionExpanded.toggle()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "doc.text.magnifyingglass")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text(isDescriptionExpanded ? "Ocultar descripción" : "Ver descripción generada")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Image(systemName: isDescriptionExpanded ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundStyle(.orange)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: isDescriptionExpanded ? 0 : 18, style: .continuous)
                                        .fill(Color.orange.opacity(0.12))
                                )
                            }
                            .buttonStyle(.plain)

                            if isDescriptionExpanded {
                                Text(viewModel.aiDescription)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(20)
                                    .background(Color.orange.opacity(0.06))
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.orange.opacity(0.28), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 20)

                Button {
                    handleSendToCoque()
                } label: {
                    VStack(spacing: 6) {
                        Text("Mandársela a Coque")
                            .fontWeight(.semibold)

                        Text(viewModel.canSendToCoque ? "Abrirá el chat con tu ruta personalizada" : "Primero necesitas contestar la encuesta")
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .opacity(0.92)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(viewModel.canSendToCoque ? Color.orange : Color.orange.opacity(0.65))
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)

                Button {
                    viewModel.backToHome()
                } label: {
                    Text("Volver")
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.orange.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .frame(maxWidth: .infinity)
        }
    }

    func homeButton(title: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline)

            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.orange)
        )
        .shadow(color: .orange.opacity(0.24), radius: 8, x: 0, y: 6)
    }

    func optionCard(title: String, color: Color, isSelected: Bool) -> some View {
        VStack {
            Spacer()

            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .padding(.horizontal, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 115)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(color)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(isSelected ? Color.primary.opacity(0.45) : Color.clear, lineWidth: 3)
        )
        .shadow(color: .orange.opacity(0.16), radius: 8, x: 0, y: 5)
        .scaleEffect(isSelected ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.18), value: isSelected)
        
    }
    
    func handleSendToCoque() {
        guard viewModel.canSendToCoque else {
            showSurveyRequiredAlert = true
            return
        }

        let prompt = viewModel.makeCoqueRoutePrompt()
        // Envía el prompt como contexto silencioso: no aparecerá como burbuja
        // del usuario en el chat, solo se mostrará la respuesta de Coque.
        coqueGuideVM.openPanelWithSilentPrompt(prompt)
    }
}

#Preview {
    SurveyView()
}
