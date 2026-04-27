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
    @State private var showIdealAttractionSheet = false
    @State private var idealAttractionForSheet: Attraction? = nil
    @State private var isComputingIdealInSurvey: Bool = false
    @State private var showIdealAttractionError: Bool = false
    @State private var idealAttractionErrorMessage: String = ""
    @Namespace private var animationNamespace

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
        .navigationTitle(L10n.surveyTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.loadExistingProfile(from: modelContext)
        }
        .alert(L10n.surveyAlertTitle, isPresented: $showSurveyRequiredAlert) {
            Button(L10n.surveyStart) {
                viewModel.startSurvey()
            }
            Button(L10n.surveyAlertLater, role: .cancel) { }
        } message: {
            Text(L10n.surveyAlertMessage)
        }
        .alert("Error", isPresented: $showIdealAttractionError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(idealAttractionErrorMessage)
        }
        .trackScreenTime("survey")
        .sheet(isPresented: $showIdealAttractionSheet) {
            if let attr = idealAttractionForSheet {
                IdealAttractionResultView(
                    attraction: attr,
                    onMap: {
                        NotificationCenter.default.post(name: .openMapFromIdealAttraction, object: nil)
                        showIdealAttractionSheet = false
                    },
                    onAskCoque: {
                        coqueGuideVM.openPanelWithMessage("Cuéntame sobre \(attr.name) en Horno3, por favor.")
                        showIdealAttractionSheet = false
                    }
                )
            }
        }
    }
}

private extension SurveyView {
    var progressFraction: Double {
        Double(viewModel.currentStepIndex + 1) / Double(max(1, viewModel.steps.count))
    }

    var homeContent: some View {
        VStack(spacing: 24) {
            Spacer()

            Image("Coque")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
                .shadow(radius: 10)

            Text(L10n.surveyHomeTitle)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundStyle(.primary)

            Text(L10n.surveyHomeSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 16) {
                Button {
                    viewModel.startSurvey()
                } label: {
                    homeButton(title: L10n.surveyStart, icon: "play.fill")
                }
                .buttonStyle(PressableButtonStyle())

                Button {
                    viewModel.openDescription()
                } label: {
                    homeButton(title: L10n.surveyViewDescription, icon: "person.text.rectangle.fill")
                }
                .buttonStyle(PressableButtonStyle())
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    var questionContent: some View {
        VStack(spacing: 18) {
            HStack {
                Button {
                    withAnimation(.spring(response: 0.36, dampingFraction: 0.78)) {
                        viewModel.goBackOneStepOrHome()
                    }
                } label: {
                    Image(systemName: "chevron.backward")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .frame(width: 42, height: 42)
                        .background(Color.orange.opacity(0.22))
                        .clipShape(Circle())
                }
                .buttonStyle(PressableButtonStyle())

                Spacer()

                VStack(spacing: 6) {
                    Text(viewModel.progressText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .id(viewModel.currentStepIndex)

                    AnimatedProgressBar(fraction: progressFraction, height: 6)
                        .frame(height: 6)
                        .padding(.horizontal, 6)
                        .transition(.opacity)
                }

                Spacer()

                Color.clear
                    .frame(width: 42, height: 42)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            VStack(spacing: 10) {
                Text(viewModel.currentStep.localizedTitle)
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
                    Text(L10n.surveyRecommendHint)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
            }
            .padding(.horizontal, 20)

            if viewModel.isLoading {
                Spacer()
                VStack(spacing: 12) {
                    FancyLoadingView(size: 56)
                    Text(L10n.surveyLoading)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible(), spacing: 14),
                        count: viewModel.currentStep.columns
                    ),
                    spacing: 14
                ) {
                    let rawOptions = viewModel.currentStep.options
                    let displayOptions = viewModel.currentStep.localizedOptions
                    ForEach(rawOptions.indices, id: \.self) { index in
                        let raw = rawOptions[index]
                        let display = displayOptions[index]
                        Button {
                            withAnimation(.spring(response: 0.36, dampingFraction: 0.78)) {
                                viewModel.selectOption(raw, in: modelContext)
                            }
                        } label: {
                            optionCard(
                                title: display,
                                color: optionColors[index % optionColors.count],
                                isSelected: viewModel.optionIsSelected(raw)
                            )
                        }
                        .buttonStyle(OptionCardStyle(isSelected: viewModel.optionIsSelected(raw)))
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
                    .pulsingGlow(Color.accentColor)

                Text(L10n.surveyDescriptionTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Group {
                    if viewModel.aiDescription.isEmpty {
                        Text(L10n.surveyDescriptionEmpty)
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
                                        .scalingFont(size: 16, weight: .semibold)
                                    Text(isDescriptionExpanded ? L10n.surveyHideDescription : L10n.surveyShowDescription)
                                        .scalingFont(size: 15, weight: .semibold, relativeTo: .subheadline)
                                    Spacer()
                                    Image(systemName: isDescriptionExpanded ? "chevron.up" : "chevron.down")
                                        .scalingFont(size: 13, weight: .semibold)
                                }
                                .foregroundStyle(.orange)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: isDescriptionExpanded ? 0 : 18, style: .continuous)
                                        .fill(Color.orange.opacity(0.12))
                                )
                            }
                            .buttonStyle(PressableButtonStyle())

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
                        Text(L10n.surveySendToCoque)
                            .fontWeight(.semibold)

                        Text(viewModel.canSendToCoque ? L10n.surveySendReady : L10n.surveySendNotReady)
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
                .buttonStyle(PressableButtonStyle())
                .padding(.horizontal, 20)

                // Botón para ver atracción ideal generado a partir de la encuesta
                Button {
                    handleViewIdealAttraction()
                } label: {
                    HStack {
                        Text("Ver atracción ideal")
                            .fontWeight(.semibold)
                            .foregroundStyle(viewModel.canSendToCoque ? .primary : .secondary)
                        Spacer()
                        if isComputingIdealInSurvey {
                            FancyLoadingView(size: 28)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(viewModel.canSendToCoque ? Color(.secondarySystemBackground) : Color(.tertiarySystemGroupedBackground))
                    )
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.horizontal, 20)

                Button {
                    viewModel.backToHome()
                } label: {
                    Text(L10n.surveyBack)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.orange.opacity(0.12))
                        )
                }
                .buttonStyle(PressableButtonStyle())
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
        .scaleEffect(isSelected ? 0.985 : 1.0)
        .animation(.spring(response: 0.28, dampingFraction: 0.75), value: isSelected)
        
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

    func handleViewIdealAttraction() {
        guard viewModel.canSendToCoque else {
            showSurveyRequiredAlert = true
            return
        }

        Task {
            guard !isComputingIdealInSurvey else { return }
            isComputingIdealInSurvey = true
            defer { isComputingIdealInSurvey = false }

            let descriptor = FetchDescriptor<ExcursionUserProfile>(
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )

            do {
                guard let profile = try modelContext.fetch(descriptor).first else {
                    showSurveyRequiredAlert = true
                    return
                }

                let aiService = SurveyAIService()

                do {
                    let id = try await aiService.generateIdealAttractionID(for: profile)
                    if let mapped = Attraction.attraction(for: id) {
                        idealAttractionForSheet = mapped
                    } else {
                        idealAttractionForSheet = viewModel.computeRecommendedAttraction()
                        idealAttractionErrorMessage = "La IA devolvió: \(id). Mostrando recomendación local."
                        showIdealAttractionError = true
                    }
                    showIdealAttractionSheet = true
                } catch let err as SurveyAIError {
                    switch err {
                    case .deviceNotEligible, .appleIntelligenceNotEnabled, .modelNotReady, .unavailable:
                        do {
                            let id = try await aiService.generateIdealAttractionViaBackend(for: profile)
                            if let mapped = Attraction.attraction(for: id) {
                                idealAttractionForSheet = mapped
                            } else {
                                idealAttractionForSheet = viewModel.computeRecommendedAttraction()
                                idealAttractionErrorMessage = "El servidor devolvió: \(id). Mostrando recomendación local."
                                showIdealAttractionError = true
                            }
                            showIdealAttractionSheet = true
                        } catch {
                            idealAttractionForSheet = viewModel.computeRecommendedAttraction()
                            idealAttractionErrorMessage = "No fue posible generar la atracción ideal: \(error.localizedDescription). Mostrando recomendación local."
                            showIdealAttractionError = true
                            showIdealAttractionSheet = true
                        }
                    default:
                        idealAttractionForSheet = viewModel.computeRecommendedAttraction()
                        idealAttractionErrorMessage = "No fue posible generar la atracción ideal: \(err.localizedDescription). Mostrando recomendación local."
                        showIdealAttractionError = true
                        showIdealAttractionSheet = true
                    }
                } catch {
                    idealAttractionForSheet = viewModel.computeRecommendedAttraction()
                    idealAttractionErrorMessage = "Error inesperado: \(error.localizedDescription). Mostrando recomendación local."
                    showIdealAttractionError = true
                    showIdealAttractionSheet = true
                }
            } catch {
                showSurveyRequiredAlert = true
            }
        }
    }
}

#Preview {
    SurveyView()
}
