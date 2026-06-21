import SwiftUI

// ─────────────────────────────────────────────────────────────
// Ember — private, on-device health intelligence.
// ─────────────────────────────────────────────────────────────
@main
struct EmberApp: App {
    @State private var env = AppEnvironment.live()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(env)
        }
    }
}
