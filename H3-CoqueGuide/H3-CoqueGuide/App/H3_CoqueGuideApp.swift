
import SwiftUI
import SwiftData

@main
struct H3_CoqueGuideApp: App {
    var body: some Scene {
        WindowGroup {
            LandingView()
        }
        .modelContainer(for: [ExcursionUserProfile.self])
    }
}
