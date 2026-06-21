import Foundation

// ─────────────────────────────────────────────────────────────
// Locates a quantized Gemma 3n `.task` model the app can load.
//
// iOS apps are sandboxed, so the model must live inside Ember:
//   • dropped into the app's Documents folder (Files app → On My
//     iPhone → Ember), optionally under a `Models/` subfolder, or
//   • bundled with the app, or
//   • downloaded into Documents on first run.
//
// `AppEnvironment.makeLLM()` uses this to switch to the real
// MediaPipe-backed Gemma provider automatically when a model exists.
// ─────────────────────────────────────────────────────────────
enum GemmaModel {

    /// Path to the first `.task` model found, or nil if none is installed.
    static func installedModelPath() -> String? {
        let fm = FileManager.default

        // 1) Bundled with the app.
        if let bundled = Bundle.main.urls(forResourcesWithExtension: "task", subdirectory: nil)?.first {
            return bundled.path
        }

        // 2) Imported into the app's Documents (or a Models/ subfolder).
        guard let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let candidates = [docs, docs.appendingPathComponent("Models", isDirectory: true)]
        for dir in candidates {
            if let files = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil),
               let model = files.first(where: { $0.pathExtension.lowercased() == "task" }) {
                return model.path
            }
        }
        return nil
    }

    /// Whether a model is currently installed (drives UI state if needed).
    static var isInstalled: Bool { installedModelPath() != nil }
}
