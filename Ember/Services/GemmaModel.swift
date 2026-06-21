import Foundation

// ─────────────────────────────────────────────────────────────
// Locates an on-device LLM model the app can load — a LiteRT-LM
// `.litertlm` (preferred) or a MediaPipe `.task` bundle.
//
// iOS apps are sandboxed, so the model must live inside Ember:
//   • dropped into the app's Documents folder (Files app → On My
//     iPhone → Ember), optionally under a `Models/` subfolder, or
//   • bundled with the app, or
//   • downloaded into Documents/Models on first run.
//
// `AppEnvironment.intelligence()` uses this to switch on the real
// LiteRTLMProvider automatically when a model exists.
// ─────────────────────────────────────────────────────────────
enum GemmaModel {

    /// Recognized on-device model file extensions.
    static let modelExtensions: Set<String> = ["litertlm", "task"]

    /// Path to the first model file found, or nil if none is installed.
    static func installedModelPath() -> String? {
        let fm = FileManager.default

        // 1) Bundled with the app.
        for ext in modelExtensions {
            if let bundled = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil)?.first {
                return bundled.path
            }
        }

        // 2) Imported/downloaded into the app's Documents (or a Models/ subfolder).
        guard let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let candidates = [docs.appendingPathComponent("Models", isDirectory: true), docs]
        for dir in candidates {
            if let files = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil),
               let model = files.first(where: { modelExtensions.contains($0.pathExtension.lowercased()) }) {
                return model.path
            }
        }
        return nil
    }

    /// Whether a model is currently installed.
    static var isInstalled: Bool { installedModelPath() != nil }
}
