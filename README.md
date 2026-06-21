# Ember

**Private health intelligence.** Ember reads your Apple Health data and produces daily
suggestions, a weekly status report, metric drill-downs, and a conversational assistant —
all powered by a **Gemma 3n** model running **entirely on-device**. No cloud, no account,
nothing leaves your iPhone.

A native SwiftUI reproduction of a high-fidelity design prototype, wired to real **HealthKit**
reads and a **Gemma-ready** on-device LLM layer. Dark, warm near-black premium theme.

<p>
  <em>Today · Weekly · Insights · Ask · Settings — plus Onboarding and a reusable metric Detail view.</em>
</p>

---

## Requirements

- **Xcode 16 or later** (built and verified against Xcode 26.5, iOS 26.5 simulator SDK).
- **iOS 17.0+** deployment target. iPhone only, portrait.
- A Mac. A free Apple ID is enough to run on your own device (see below).

## Quick start (simulator)

```bash
open Ember.xcodeproj      # then press ⌘R, or:

xcodebuild -project Ember.xcodeproj -scheme Ember \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
```

> If `xcodebuild` can't find the iOS SDK, your `xcode-select` may still point at the
> Command Line Tools. Either run `sudo xcode-select -s /Applications/Xcode.app` once, or
> prefix commands with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.

In the simulator the app runs immediately on **mock data** (seeded to the reference
screenshots) and a **mock on-device assistant**, so every screen is fully interactive
without any setup.

## Run it on your iPhone (free Apple ID)

iOS has no "drag-and-install" — every install is code-signed through Xcode. A free Apple ID
works (the app stays valid ~7 days; re-run to refresh).

1. Open `Ember.xcodeproj` in Xcode.
2. Select the **Ember** target → **Signing & Capabilities**.
3. Set **Team** to your Apple ID (use *Add an Account…* if needed).
4. If `com.ember.health` is taken, change **Bundle Identifier** to something unique
   (e.g. `com.yourname.ember`).
5. Plug in your iPhone, trust the Mac, and enable **Developer Mode**
   (Settings → Privacy & Security → Developer Mode).
6. Choose your iPhone as the run destination and press **▶ Run**.
7. First launch only: trust your developer certificate on the phone
   (Settings → General → VPN & Device Management).

On device, onboarding's **Allow access** step triggers the real HealthKit permission prompt;
grant read access and the dashboards fill with your own data.

## Enabling real on-device Gemma 3n

The assistant sits behind the `LLMProviding` protocol. `MockGemmaProvider` (keyword-routed,
simulated streaming) is the default so the app always runs. The real implementation,
`MediaPipeGemmaProvider`, compiles in automatically when the MediaPipe package is present
(guarded by `#if canImport(MediaPipeTasksGenAI)`), and
[`AppEnvironment.makeLLM()`](Ember/App/AppEnvironment.swift) **auto-selects it at launch** as
soon as a `.task` model is found — no code change needed.

1. **Add the MediaPipe package** (CocoaPods is the supported iOS path):
   ```bash
   brew install cocoapods     # if needed
   pod install                # uses the included Podfile
   open Ember.xcworkspace     # from now on open the WORKSPACE, not the .xcodeproj
   ```
2. **Get a model into Ember.** You need a quantized **Gemma 3n `.task`** file (multiple GB).
   iOS apps are sandboxed, so the model must live *inside Ember* — it can't read another app's
   files. Pick one:
   - **Files app:** copy the `.task` into *On My iPhone → Ember* (file sharing is enabled), or
   - **Bundle it:** drag the `.task` into the Xcode project (simplest, but a multi-GB app), or
   - **Download in-app:** fetch it into the app's `Documents/` on first run.

   > **About AI Edge Gallery:** it stores its models in *its own* sandbox, which Ember cannot read
   > directly. Export/share the `.task` out of Gallery and drop it into Ember via the Files app, or
   > download the `.task` straight from Kaggle / Hugging Face.

3. **Run on a device.** `makeLLM()` finds the `.task` (bundle, `Documents/`, or `Documents/Models/`)
   and switches to real Gemma. The MediaPipe LLM runtime does **not** run on the iOS simulator.
   **Never commit the model** — `*.task` is git-ignored.

If the build complains after adding the pod, the MediaPipe Swift API shifts between releases —
adjust the `LlmInference` calls in [`LLMProviding.swift`](Ember/Services/LLMProviding.swift) to
your installed version. The model status/storage in Settings reflects the real model once loaded.

## Architecture

SwiftUI · iOS 17 · `@Observable` state · protocol-based services with **mock + real**
implementations, dependency-injected via the SwiftUI environment (mocks in
simulator/previews, real providers on device).

```
Ember/
  App/            EmberApp entry, RootView (onboarding gate → tab shell), AppRouter,
                  AppEnvironment (provider container), AppChrome (tab bar / privacy banner)
  DesignSystem/   Theme + AccentTheme (Rouge/Amber/Iris/Mint) + Motion (reduce-motion aware)
    Components/   Ring, Sparkline, BarChart, Card, GemmaChip, Delta, SectionLabel,
                  EmberToggle, EmberLogo, EmberIcon (SF Symbol map), Pulses
  Models/         TodaySnapshot, WeeklyReport, Insight, ChatMessage, ModelStatus,
                  MetricDetail, enums, and MockData (exact prototype values)
  Services/       HealthDataProviding  → HealthKitProvider + MockHealthProvider
                  LLMProviding         → MediaPipeGemmaProvider (#if canImport) + MockGemmaProvider
                  SpeechTranscribing   → SpeechProvider (Speech framework) + MockSpeechProvider
                  SettingsStore        → UserDefaults-backed prefs (drives theming)
  Features/       Onboarding, Today, Weekly, Insights, Ask (chat + voice), Settings, Detail
  Resources/      Ember.entitlements (HealthKit), Assets.xcassets (AppIcon + AccentColor)
docs/             HANDOFF.md + design-handoff/ (the source spec, JSX, screenshots)
scripts/          make_appicon.swift (regenerates the 1024 app icon)
```

### Theming

Four accent themes (**Rouge** default, Amber, Iris, Mint), Elevated/Outlined cards, and a
tunable corner radius — all live, from **Settings → Appearance** (this replaces the
prototype's browser-only Tweaks panel). "Replay onboarding" lives there too.

### Privacy & permissions

Read-only HealthKit (`com.apple.developer.healthkit`), plus microphone + speech recognition
for the voice assistant. Usage strings are set via build settings (`GENERATE_INFOPLIST_FILE`).
All inference is local by design.

## Notes

- The Xcode project uses a **file-system-synchronized group**, so new files under `Ember/`
  are picked up automatically — no manual project edits.
- `make_appicon.swift` regenerates the icon:
  `swift scripts/make_appicon.swift Ember/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png`
- **Debug-only deep link:** in Debug builds you can boot straight into a screen for testing —
  `xcrun simctl launch booted com.ember.health -ember.debugTab weekly` (or
  `-ember.debugDetail hr`). No effect in Release.

## Credits

Built to a high-fidelity design handoff (see [`docs/`](docs/)). Product name **Ember**;
some prototype source carries the internal codename "Vesta" — ignore it.
