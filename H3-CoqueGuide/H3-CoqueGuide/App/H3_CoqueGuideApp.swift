
import SwiftUI
import SwiftData

@main
struct H3_CoqueGuideApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .prewarmKeyboardOnAppear()
                // Respeta la configuración de tamaño de texto del iPhone
                // (Ajustes → Accesibilidad → Tamaño del texto) pero limita
                // los tamaños extremos que romperían los layouts actuales.
                // Los usuarios con necesidad de tamaños AX4+ siguen viendo
                // texto grande, solo capped al máximo soportable.
                .dynamicTypeSize(.small ... .accessibility3)
        }
        .modelContainer(for: [ExcursionUserProfile.self])
    }
}

/// Raíz del app: presenta onboarding la primera vez y luego `LandingView`.
/// En aperturas subsecuentes entra directo a la landing.
private struct RootView: View {

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false

    /// Tab que LandingView debe seleccionar al aparecer (3 = encuesta, 0 = inicio).
    /// Lo setea el onboarding si el usuario toca "Comenzar encuesta".
    @State private var initialTab: Int = 0

    @State private var showingOnboarding: Bool = false

    var body: some View {
        LandingView(initialTab: $initialTab)
            .fullScreenCover(isPresented: $showingOnboarding) {
                OnboardingView { wantsSurvey in
                    if wantsSurvey {
                        initialTab = 3   // tab de encuesta
                    }
                    showingOnboarding = false
                }
            }
            .onAppear {
                if !hasSeenOnboarding {
                    showingOnboarding = true
                }
            }
    }
}
