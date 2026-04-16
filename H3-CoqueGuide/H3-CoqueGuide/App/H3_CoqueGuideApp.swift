
import SwiftUI
import SwiftData

@main
struct H3_CoqueGuideApp: App {
    var body: some Scene {
        WindowGroup {
            LandingView()
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
