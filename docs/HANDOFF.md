# Ember iOS — Session Handoff

Context brief for continuing the build in a fresh session. Read this top-to-bottom, then re-read the design handoff source files (paths below) before writing code.

---

## 1. What we're building

**Ember** — an iOS health app that reads Apple Health data and produces daily suggestions, a weekly status report, metric drill-downs, and a conversational assistant, all powered by a **Gemma 3n** model running **entirely on-device** (no cloud, no account). Privacy is the core product promise. Dark, warm near-black premium theme.

This is a **faithful native reproduction** of a high-fidelity HTML/React prototype (the "design handoff"). The visual design is fully specified — exact colors, type, spacing, copy, motion, and 8 screenshots. Very little to "design"; the job is to rebuild it natively and wire real data + a real on-device LLM.

## 2. Source materials (READ THESE FIRST in the new session)

- **Original zip (persistent):** `/Users/thomasjvarghese/Downloads/Prototype development request.zip`
- **Extracted copy (may be cleared on reboot):** `/tmp/prototype_request/HealthMonitor/design_handoff_ember_health/`
  - `README.md` — the spec: tech stack, HealthKit types, Gemma notes, **all design tokens**, every screen, interactions, state, mock data notes.
  - `design/components.jsx` — icons, `Ring`, `Sparkline`, `BarChart`, `Card`, chips, and the **`DATA` mock object** (exact numbers used in screenshots).
  - `design/app.jsx` — theming (`ACCENTS`), navigation, tab bar, privacy banner, scroll logic.
  - `design/screens.jsx` — Home (Today), Insights, Detail, Settings.
  - `design/screens-weekly.jsx` — Weekly Status Report (the hero screen).
  - `design/chat.jsx` — Ask Gemma chat + voice overlay (`gemmaReply` = canned replies to mirror).
  - `design/onboarding.jsx` — 3-step onboarding + `Logo`.
  - `design/ios-frame.jsx`, `design/tweaks-panel.jsx` — **prototype-only scaffolding; do NOT port** (browser bezel + tweak controls).
  - `screenshots/01..08-*.png` — reference renders of every screen (Rouge accent).

> Recommendation for the new session: copy the handoff into the repo for durable reference, e.g. `cp -R "/tmp/prototype_request/HealthMonitor/design_handoff_ember_health" docs/design-handoff` (or re-extract the zip from Downloads).

## 3. Decisions locked (from this session's Q&A)

- **Build scope:** Full SwiftUI UI (every screen pixel-faithful) **+ real HealthKit** read wiring **+ Gemma-ready**. The LLM sits behind a protocol with an on-device-style **mock provider as default** (so it runs immediately) plus a **real MediaPipe/Gemma implementation** guarded by `#if canImport(MediaPipeTasksGenAI)` (lights up when the user adds the package + model on-device).
- **Repo name:** `Ember` → `/Users/thomasjvarghese/Repos/Ember` (git already initialized).
- **App/target name:** `Ember`. **Bundle id (default):** `com.ember.health` (trivially changeable). **iOS deployment target:** 17.0. **Orientation:** portrait only. **Swift language mode:** 5.0 (avoids Swift 6 strict-concurrency build breaks).

## 4. Environment constraints (important)

- **At the time of this session, NO full Xcode was installed** — only Command Line Tools (no iOS SDK, no `xcodebuild` for iOS). **The user is NOW installing Xcode.** Once installed, the project can build.
- No CocoaPods, no XcodeGen/Tuist on PATH. Swift 6.3.2 toolchain present (CLT).
- **iOS has no Android-style "drag-and-install."** Every install path requires code-signing with the user's Apple ID via Xcode (or a sideload tool). A **free** Apple ID works (app valid 7 days; re-Run to refresh). Closest to "drag-install": open project → plug in iPhone → click **Run**.
- The Gemma 3n `.task` model is **multiple GB** — never commit it to git; it's downloaded/side-loaded on device.

## 5. Architecture (approved)

SwiftUI, iOS 17, `@Observable` state, protocol-based service layer with real + mock implementations, dependency-injected via Environment so previews/simulator use mocks and device uses real.

```
Ember/                      (repo root, git initialized)
  Ember.xcodeproj/          project.pbxproj (hand-authored, see §6)
  Ember/                    (app source — file-system-synchronized group)
    App/                    EmberApp entry, RootView (onboarding gate → TabView), AppEnvironment (provider container)
    DesignSystem/
      Theme.swift           every color/spacing/radius/type token; 4 accent themes (Rouge default)
      AccentTheme.swift     Rouge / Amber / Iris / Mint
      Motion.swift          reduce-motion-aware animation helpers
      Components/           Ring, Sparkline, BarChart, Card, GemmaChip, Delta, SectionLabel, EmberToggle, EmberLogo, EmberIcon (SF Symbol map)
    Models/                 TodaySnapshot, WeeklyReport, MetricSeries, Insight, ChatMessage, ModelStatus, enums (MetricKind, AccentTheme, CardStyle), MockData (the prototype DATA)
    Services/
      HealthDataProviding   protocol → HealthKitProvider (real HKHealthStore reads) + MockHealthProvider (seeded to screenshot numbers)
      LLMProviding          protocol (streaming chat, weekly summary, daily suggestion) → MockGemmaProvider (canned, keyword-routed, simulated streaming) + MediaPipeGemmaProvider (#if canImport; real LlmInference)
      SpeechTranscribing    protocol → SpeechProvider (AVAudioRecorder + SFSpeechRecognizer) + mock transcript
      SettingsStore         UserDefaults-backed (onboarded, accent, cardStyle, radius, privacyBanner, goals)
    Features/               Onboarding, Today, Weekly, Insights, Ask (chat + voice overlay), Settings, Detail
    Resources/
      Ember.entitlements    HealthKit entitlement
      Assets.xcassets/      AppIcon (1024 Ember logo) + AccentColor (#fb3b5a)
  docs/                     this handoff (+ optionally the design-handoff copy)
  README.md, .gitignore
```

## 6. Xcode project specifics (hand-authored, no Xcode was available to generate it)

- `project.pbxproj` uses **`PBXFileSystemSynchronizedRootGroup`** (objectVersion 77, `compatibilityVersion = "Xcode 16.0"`) pointing at the `Ember/` source folder → every file added is auto-included, no per-file refs.
- `GENERATE_INFOPLIST_FILE = YES` with build-setting usage strings:
  - `INFOPLIST_KEY_NSHealthShareUsageDescription`
  - `INFOPLIST_KEY_NSMicrophoneUsageDescription`
  - `INFOPLIST_KEY_NSSpeechRecognitionUsageDescription`
  - portrait-only, `UIStatusBarStyleLightContent`, launch screen generation on.
- `CODE_SIGN_ENTITLEMENTS = Ember/Resources/Ember.entitlements`, `CODE_SIGN_STYLE = Automatic`, `DEVELOPMENT_TEAM` empty (user sets their team in Xcode), `TARGETED_DEVICE_FAMILY = 1`, `SWIFT_VERSION = 5.0`, `IPHONEOS_DEPLOYMENT_TARGET = 17.0`, `PRODUCT_BUNDLE_IDENTIFIER = com.ember.health`.
- Entitlements: `com.apple.developer.healthkit = true` (HealthKit works with free provisioning).

## 7. Design tokens (compact — full table in handoff README §Design Tokens)

- **Base:** `--bg #0c0b0a`, `--bg2 #141210`, surface (Elevated) `#1a1714`, text `#f4f0ea`, text-2 `rgba(244,240,234,0.62)`, text-3 `0.38`, good `#5ec98a`, hair `rgba(255,255,255,0.07)`.
- **Accents (user-switchable, Rouge default):** Rouge `#fb3b5a`/`#ff8a8f`, Amber `#ff6a3d`/`#ffb13c`, Iris `#a85cff`/`#d98aff`, Mint `#10e08a`/`#67f0c4`. Soft = accent @ ~0.22 alpha; line = ~0.46.
- **Fixed metric colors:** heart `#e8596a`, sleep `#8a8fe6`. Dark-text-on-accent `#1a1410`.
- **Type:** system (SF Pro) for UI; **mono (SF Mono / ui-monospace)** for small UPPERCASE labels, units, timestamps, "on-device" tags. Large title 27–28/740, big number 30–44/760, card value 20–25/700, body 14–15.5, mono 10.5–13.
- **Shape:** card radius default **22** (user-tunable 10–30), pills 999, icon tiles 9–13. Card border `1px rgba(255,255,255,0.07)`. Elevated shadow `0 4px 24px -12px rgba(0,0,0,0.6)`. Screen H-padding 16, header side padding 20, section gap 16.
- **Motion:** screen enter translateY(8→0) .35s; ring fill stroke 1s; bars grow .7s; pulseDot 1.6s; glowPulse 2.6s; sheen 3.4s; flicker (flame) 2s; waveBar .9s staggered; typeDot 1s staggered. Easing `cubic-bezier(.4,0,.2,1)`. **Respect Reduce Motion** — base state = visible end-state.

## 8. Screens & data (compact)

5 tabs: **Today · Weekly · Insights · Ask · Settings**, plus **Onboarding** (3 steps, gates app) and **Detail** (pushed, reused for Steps/Heart/Sleep).

- **Onboarding:** Welcome (Ember logo + tagline + "100% on-device" lock line) → Connect Apple Health (4 data-type rows, triggers `HKHealthStore.requestAuthorization`) → On-device model setup (0→100% ring, "Setting up Gemma" → "Ready to go"). Persist `onboarded`.
- **Today:** date + 5-day streak chip; "Good morning, {name}"; weekly-report-ready glow card → Weekly; steps ring focus; 2×2 metric grid (Resting HR 58, Sleep 7h12m, Active 412kcal, Exercise 28min) → Detail; this-week bar mini card; Today's suggestion (Gemma) → Insights; on-device footer.
- **Weekly (hero):** "WEEKLY REPORT" + range; status hero ring (score 78/100, "On track"); AI summary + **Regenerate**; This-week-vs-last metric rows w/ sparklines → Detail; daily steps bar chart w/ goal line; Highlights (green) + Watch-outs (accent); Focus next week (3 cards); Diet teaser (SOON, disabled); on-device footer.
- **Insights:** "Updated 2h ago"; summary graph card (12 generated + sparkline + Activity5/Heart4/Sleep3); filter chips All/Activity/Heart/Sleep; bullet feed (glowing dot + headline + detail + mono meta, "NOW" pin) → Detail.
- **Ask:** glowing chip header "Ask Gemma · On-device · Gemma 3n"; message thread (AI left/surface, user right/accent); typing dots; suggested prompts (before first msg); composer (mic when empty, send when text); voice overlay (blur, RECORDING, timer, waveform, cancel/confirm → transcribe → send tagged as voice). `gemmaReply` is keyword-routed canned text to mirror in MockGemmaProvider.
- **Settings:** profile row; ON-DEVICE INTELLIGENCE card (Gemma 3n · Active · 4-bit · 3.1 GB, lock note, storage bar 3.1/8 GB 39%, "Process on device only" toggle, Re-run analysis, Model & storage); DATA SOURCES (Apple Health Linked); PREFERENCES (Daily suggestions, Goals, About v1.0 beta). Put accent/appearance theme controls + "Replay onboarding" here (Tweaks panel was browser-only).
- **Mock `DATA`** (exact values for the mock providers) is in `design/components.jsx` — steps 7420/goal 10000, restingHR 58, sleep 7h12m/7.2, activeEnergy 412, exercise 28/30; week range "Jun 13 – Jun 19", score 78, 4 metrics with 7-day series + deltas, stepsByDay, highlights/watch/focus arrays; 5 insights. Detail metric data in `screens.jsx` `METRIC_DETAIL`.

## 9. Progress so far (state on disk)

- ✅ `/Users/thomasjvarghese/Repos/Ember` created, **`git init` done**, full directory tree scaffolded (see §5).
- ⏳ **No source or config files written yet.** Next planned batch was: `project.pbxproj`, `Ember.entitlements`, asset-catalog `Contents.json` files, `.gitignore`, `README.md` — then DesignSystem → Models → Services → Features → App entry → AppIcon PNG.

## 10. Next steps for the new (elevated) session

1. Re-read §2 source files + screenshots.
2. (Optional) copy the design handoff into `docs/design-handoff/` for durable reference.
3. Write config files (§6), then build source bottom-up: DesignSystem → Models (+MockData) → Services → Features → App.
4. Generate `AppIcon.png` (1024×1024, opaque): rouge `#fb3b5a` field + dark `#1a1410` ring glyph (matches `Logo`). Use Python/Pillow or a Swift CoreGraphics script.
5. Once Xcode is installed: `xcodebuild -project Ember.xcodeproj -scheme Ember -sdk iphonesimulator build` to typecheck, fix errors, iterate. (A scheme may need to be created/shared, or use `-target Ember`.)
6. Write a thorough `README.md`: build steps, "Run to your iPhone" (free Apple ID, select Team, plug in, Run), how to enable real Gemma (add `MediaPipeTasksGenAI` via SPM/CocoaPods + provision the `.task` model), HealthKit permission notes.
7. Commit in logical chunks. Push to GitHub when the user asks.

## 11. Getting it on the phone (reality)

Needs Xcode once. Flow: open `Ember.xcodeproj` → select the **Ember** target → Signing & Capabilities → pick your Team (free Apple ID OK) → plug in iPhone (trust it, enable Developer Mode) → choose it as the run destination → **Run**. App installs and runs with mock health data + mock Gemma immediately. Real HealthKit prompts on device; real Gemma requires adding the MediaPipe package + the multi-GB model.

---
*Generated 2026-06-20. App = "Ember", internal prototype codename in some JSX is "Vesta" — ignore, product is Ember.*
