//
//  OnboardingView.swift
//  H3-CoqueGuide
//
//  Onboarding de primera apertura. Se muestra una sola vez — persiste
//  el flag en `hasSeenOnboarding` (UserDefaults).
//
//  Estética: gradiente naranja de Coque sobre fondo semántico del
//  sistema para que se sienta nativo iOS en dark mode.
//

import SwiftUI

// MARK: - Onboarding raíz

struct OnboardingView: View {

    /// Callback cuando el usuario termina o salta el onboarding.
    /// - Parameter wantsSurvey: `true` si tocó "Comenzar encuesta" en la
    ///   última pantalla; el llamador debería navegar al tab de encuesta.
    let onFinish: (_ wantsSurvey: Bool) -> Void

    @State private var currentPage: Int = 0

    private let totalPages = 3

    var body: some View {
        ZStack {
            // Fondo semántico: en light es casi blanco, en dark casi negro.
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {

                // Barra superior con "Saltar"
                topBar

                // Contenido paginable
                TabView(selection: $currentPage) {
                    OnboardingWelcomePage()
                        .tag(0)

                    OnboardingCapabilitiesPage()
                        .tag(1)

                    OnboardingSurveyPage()
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Indicador de paso + botón primario
                bottomBar
            }
        }
        .accessibilityAddTraits(.isModal)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Spacer()
            Button {
                finish(wantsSurvey: false)
            } label: {
                Text(L10n.onboardingSkip)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            }
            .accessibilityHint(L10n.onboardingSkipHint)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 18) {
            // Indicador de pasos (dots)
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? Color.accentColor : Color.secondary.opacity(0.25))
                        .frame(width: index == currentPage ? 24 : 8, height: 8)
                        .animation(.easeInOut(duration: 0.25), value: currentPage)
                }
            }
            .accessibilityElement()
            .accessibilityLabel(L10n.onboardingStepLabel(current: currentPage + 1, total: totalPages))

            // Botón primario
            primaryButton
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    @ViewBuilder
    private var primaryButton: some View {
        switch currentPage {
        case 0, 1:
            Button {
                withAnimation {
                    currentPage += 1
                }
            } label: {
                primaryButtonLabel(text: L10n.onboardingNext)
            }
            .buttonStyle(.plain)
        default:
            VStack(spacing: 10) {
                Button {
                    finish(wantsSurvey: true)
                } label: {
                    primaryButtonLabel(text: L10n.onboardingStartSurvey)
                }
                .buttonStyle(.plain)

                Button {
                    finish(wantsSurvey: false)
                } label: {
                    Text(L10n.onboardingSkipSurvey)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func primaryButtonLabel(text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.93, green: 0.45, blue: 0.15),
                             Color(red: 0.85, green: 0.35, blue: 0.10)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color(red: 0.93, green: 0.45, blue: 0.15).opacity(0.3), radius: 6, x: 0, y: 3)
    }

    // MARK: - Finish

    private func finish(wantsSurvey: Bool) {
        AnalyticsService.shared.track("onboarding_completed", metadata: [
            "wants_survey": wantsSurvey,
            "last_page": currentPage,
        ])
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        onFinish(wantsSurvey)
    }
}

// MARK: - Página 1: Bienvenida

private struct OnboardingWelcomePage: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image("Coque")
                .resizable()
                .scaledToFill()
                .frame(width: 180, height: 180)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(
                        LinearGradient(
                            colors: [Color(red: 0.93, green: 0.45, blue: 0.15),
                                     Color(red: 0.85, green: 0.35, blue: 0.10)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
                )
                .shadow(color: Color(red: 0.93, green: 0.45, blue: 0.15).opacity(0.3), radius: 12, x: 0, y: 6)

            VStack(spacing: 12) {
                Text(L10n.onboardingWelcomeTitle)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)

                Text(L10n.onboardingWelcomeSubtitle)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Página 2: Capacidades

private struct OnboardingCapabilitiesPage: View {
    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 8) {
                Text(L10n.onboardingCapabilitiesTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)

                Text(L10n.onboardingCapabilitiesSubtitle)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)

            VStack(spacing: 18) {
                capabilityRow(
                    icon: "qrcode.viewfinder",
                    title: L10n.onboardingCapScanTitle,
                    subtitle: L10n.onboardingCapScanSubtitle
                )
                capabilityRow(
                    icon: "sparkles",
                    title: L10n.onboardingCapAskTitle,
                    subtitle: L10n.onboardingCapAskSubtitle
                )
                capabilityRow(
                    icon: "map.fill",
                    title: L10n.onboardingCapMapTitle,
                    subtitle: L10n.onboardingCapMapSubtitle
                )
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private func capabilityRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Página 3: Encuesta

private struct OnboardingSurveyPage: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.93, green: 0.45, blue: 0.15).opacity(0.15),
                                     Color(red: 0.85, green: 0.35, blue: 0.10).opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)

                Image(systemName: "checklist")
                    .font(.system(size: 64, weight: .regular))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.93, green: 0.45, blue: 0.15),
                                     Color(red: 0.85, green: 0.35, blue: 0.10)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 12) {
                Text(L10n.onboardingSurveyTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)

                Text(L10n.onboardingSurveySubtitle)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)
            }

            Spacer()
        }
    }
}

#Preview {
    OnboardingView { _ in }
}
