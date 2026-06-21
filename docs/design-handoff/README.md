# Handoff: Ember — On-Device Health Monitor (iOS)

## Overview
**Ember** is an iOS health app that reads the user's Apple Health data and produces daily suggestions, a weekly status report, drill-down metric detail, and a conversational assistant — all powered by a **Gemma 3n** model running **entirely on-device** (no cloud, no account). Privacy is the core product promise: data never leaves the iPhone.

This package is the design spec for building the real app.

## About the Design Files
The files in this bundle are **design references created in HTML/React (Babel JSX)** — a high-fidelity interactive prototype showing the intended look and behavior. **They are not production code to ship.** The task is to **recreate these designs as a native iOS app** using **SwiftUI**, wiring them to **HealthKit** (real data) and **Google AI Edge / MediaPipe LLM Inference** (real on-device Gemma). Use the prototype for exact colors, type, spacing, layout, copy, and interaction behavior.

## Fidelity
**High-fidelity (hifi).** Final colors, typography, spacing, iconography, motion, and copy are all defined here and should be reproduced faithfully in SwiftUI.

---

## Tech Stack (target)
| Concern | Recommended |
|---|---|
| UI | SwiftUI (iOS 17+) |
| Health data | **HealthKit** — `HKHealthStore`, read-only authorization |
| On-device LLM | **Google AI Edge / MediaPipe `LlmInference`** with a quantized **Gemma 3n** `.task` model bundled or downloaded on first run |
| Voice input | `AVAudioRecorder` + Apple **Speech** (`SFSpeechRecognizer`) for transcription, or Gemma 3n audio input if used |
| Charts | Swift **Charts** framework (bars, line/spark), or custom `Shape`/`Canvas` for the rings |
| Persistence | `UserDefaults`/`SwiftData` for onboarding flag, goals, tweak prefs |
| Distribution | Xcode → device build / TestFlight (Apple Developer Program required) |

### HealthKit data types to request (read)
- `HKQuantityTypeIdentifier.stepCount`
- `HKQuantityTypeIdentifier.restingHeartRate`, `.heartRateVariabilitySDNN`, `.heartRate`
- `HKCategoryTypeIdentifier.sleepAnalysis`
- `HKQuantityTypeIdentifier.activeEnergyBurned`
- `HKQuantityTypeIdentifier.appleExerciseTime`, `.appleStandHours`, `.distanceWalkingRunning`, `.flightsClimbed`

Add `NSHealthShareUsageDescription` to Info.plist. Add `NSMicrophoneUsageDescription` + `NSSpeechRecognitionUsageDescription` for voice.

### Gemma integration notes
- "Edge Gallery" is Google's **sample** app — do **not** ship it. Use the same underlying **MediaPipe LLM Inference API** (`MediaPipeTasksGenAI`) inside Ember.
- Load a quantized Gemma 3n model (`.task`), instantiate `LlmInference`, and call it for: (a) the weekly summary, (b) daily suggestions, (c) chat responses.
- All inference is local. The "Generated on-device", "Active · Running locally", and storage (3.1 GB) UI reflect real model state — surface actual model status/size.

---

## Design Tokens

### Color (dark theme, warm near-black base)
| Token | Value | Use |
|---|---|---|
| `--bg` | `#0c0b0a` | App background |
| `--bg2` | `#141210` | Secondary background |
| `--surface` (Elevated) | `#1a1714` | Cards |
| `--surface` (Outlined) | `rgba(255,255,255,0.025)` | Cards (outlined variant) |
| `--text` | `#f4f0ea` | Primary text |
| `--text-2` | `rgba(244,240,234,0.62)` | Secondary text |
| `--text-3` | `rgba(244,240,234,0.38)` | Tertiary / mono labels |
| `--good` | `#5ec98a` | Positive trends |
| `--good-soft` | `rgba(94,201,138,0.14)` | Positive pill bg |
| `--hair` | `rgba(255,255,255,0.07)` | Hairline dividers |
| `--hair-strong` | `rgba(255,255,255,0.14)` | Stronger borders |
| Heart metric | `#e8596a` | Heart-rate accents |
| Sleep metric | `#8a8fe6` | Sleep accents |
| Text-on-accent | `#1a1410` | Dark text on accent buttons |

### Accent themes (user-switchable; **Rouge is default**)
| Name | accent | accent2 | soft (16–22% alpha) |
|---|---|---|---|
| **Rouge** (default) | `#fb3b5a` | `#ff8a8f` | `rgba(251,59,90,0.22)` |
| Amber | `#ff6a3d` | `#ffb13c` | `rgba(255,106,61,0.22)` |
| Iris | `#a85cff` | `#d98aff` | `rgba(168,92,255,0.22)` |
| Mint | `#10e08a` | `#67f0c4` | `rgba(16,224,138,0.20)` |
`accent-line` = same hue at ~0.45 alpha (border on soft chips).

### Typography
- **UI font:** SF Pro Display / system (`-apple-system`). In SwiftUI use the system font.
- **Mono font:** SF Mono / `ui-monospace` — used for small uppercase labels, timestamps, units, technical/“on-device” tags (tracking `+0.04–0.08em`, often UPPERCASE).
- Scale (px → use as pt): large title 27–28 / 740 weight / `-0.025em`; screen H1 21–24; big number 30–44 / 760; card value 20–25 / 700; body 14–15.5 / 1.5–1.6 line-height; secondary 12.5–13.5; mono label 10.5–13.
- Numbers: tabular figures for timers/counters.

### Shape / spacing / shadow
- Card radius: **`--radius` = 22px default** (user-tunable 10–30). Pills/chips: 999. Icon tiles: 9–13.
- Card border: `1px rgba(255,255,255,0.07)` (Elevated) or `0.10` (Outlined).
- Card shadow (Elevated): `0 4px 24px -12px rgba(0,0,0,0.6)`.
- Screen horizontal padding: 16px; section gaps: 16px; header side padding 20px.
- Accent “glow”: `0 0 0 1px <soft>, 0 8px 30px -12px <soft>`.

### Motion (durations / easing)
- Screen enter: translateY(8px)→0 over .35s `cubic-bezier(.4,0,.2,1)` (no opacity fade — content always visible).
- Ring fill: `stroke-dashoffset` 1s `cubic-bezier(.4,0,.2,1)`.
- Bars grow: height .7s same easing.
- `pulseDot` (live status dots): scale 1→0.55, opacity 1→0.3, 1.6s ease-in-out infinite.
- `glowPulse` (active model / report icon): box-shadow pulse, 2.6s.
- `sheen`: diagonal highlight sweep across the “report ready” card, 3.4s.
- `flicker` (streak flame): scale 1→1.18 + slight rotate, 2s.
- `waveBar` (recording waveform): height 8→52px, .9s, staggered delays.
- `typeDot` (chat typing): 3 dots, translateY + opacity, 1s staggered.
- Respect `prefers-reduced-motion` (Reduce Motion): base states are the visible end-states, so disabling animation must keep everything visible.

---

## Screens / Views

### 0. Onboarding (3 steps, shown once)
- **Step 1 — Welcome:** Ember logo (rounded-square accent tile with a ring glyph), wordmark “Ember” (38pt/760), tagline “Private health intelligence…”, accent mono line “100% on-device · nothing leaves your phone” with lock icon. CTA **Get started**, secondary **Skip for now**.
- **Step 2 — Connect Apple Health:** white rounded tile with red heart, title “Connect Apple Health”, 4 data-type rows (Steps & Distance / Heart Rate & HRV / Sleep Analysis / Active Energy) each with colored icon + green check. CTA **Allow access** → triggers real `HKHealthStore.requestAuthorization`.
- **Step 3 — On-device model setup:** progress ring 0→100% (animated), title “Setting up Gemma on-device” → “Ready to go”, body about loading Gemma 3n via on-device runtime, chip “Gemma 3n · Edge Gallery”. CTA disabled until 100%, then **Enter Ember**. In production this reflects real model download/init progress.
- Progress dots at top (active dot is a 22px pill). State: `step` (0–2), `setup` (0–100). Persist completion (`UserDefaults` `onboarded`).

### 1. Today (Home dashboard)
- Header: date (mono) + **streak chip** (flame icon, “5-day streak”, accent-soft pill, flame flickers) on the right; H1 “Good morning, {name} 👋”.
- **Weekly report ready** card (accent glow + sheen sweep + floating icon): accent icon tile, “Your weekly report is ready”, sub “● On track · score 78 · {range}”, chevron → navigates to Weekly. Pulsing live dot.
- **Steps focus** card: progress ring (steps/goal, gradient accent2→accent) with footprints icon + “7.4k / of 10k” inside; right side large step count + “2,580 steps to your goal — about a 22-min walk.”
- **Metric grid** (2×2 tiles): Resting HR (58 bpm, heart `#e8596a`, ▼3% good), Last night's sleep (7h 12m, moon `#8a8fe6`, ▼6% bad), Active energy (412 kcal, flame accent2, ▲4% good), Exercise (28 min, accent, “28/30”). Tiles tap → Detail.
- **This week** mini card: “57,680 steps · 7 days” + ▲9%, bar chart of 7 days vs 10k goal line.
- **Today's suggestion** card (taps → Insights): sparkle icon, one Gemma suggestion paragraph, “Gemma · on-device” chip.
- Footer mono line: shield icon “Synced from Apple Health · processed on device”.

### 2. Weekly (the hero — Weekly Status Report)
Scrollable report:
1. Header “WEEKLY REPORT” (mono) + date range H1.
2. **Status hero** card (glow): score ring (78/100, gradient), “On track” pill (green dot), “Your health score rose +6 points…”.
3. **AI Summary**: “Summary · on-device” chip + **Regenerate** (spins refresh icon, dims text ~1.4s while “Analyzing…”), paragraph summary. In production this calls Gemma.
4. **This week vs last**: 4 metric rows (Avg Steps / Resting HR / Avg Sleep / Active Energy), each = icon tile, label, value+unit, sparkline, delta pill. Rows tap → Detail.
5. **Daily steps** card: avg + delta + 7-bar chart with dashed “GOAL 10k” line (bars meeting goal are accent-filled, others grey).
6. **Highlights** (green) and **Watch-outs** (accent) cards: icon header + bulleted lines.
7. **Focus next week**: 3 recommendation cards (icon tile + title + body).
8. **Diet recommendations** teaser: dashed card, “SOON” tag, lock icon — *future feature, intentionally disabled.*
9. Footer mono: “Analyzed locally · Gemma 3n · {range}”.

### 3. Insights (scannable bullet feed)
- Header “Updated 2h ago” + H1 “Insights”.
- **Summary graph** card: “INSIGHTS THIS WEEK / 12 generated” + sparkline + 3 category mini-stats (Activity 5 / Heart 4 / Sleep 3, each with colored dot).
- **Filter chips:** All / Activity / Heart / Sleep (selected = accent fill, dark text).
- **Bullet list** (single card, hairline-separated rows). Each row: glowing colored category dot + **bold one-line headline** (15pt/650) + muted detail line (13pt) + meta line (mono: `CATEGORY · tag · time`); pinned item shows “NOW” tag. Rows tap → relevant Detail. Designed for fast scanning — headline first.
- Footer “All insights generated on-device” chip.

### 4. Ask (Chat with Gemma)
- Header: glowing accent chip (cpu icon), “Ask Gemma”, green live status “On-device · Gemma 3n”.
- **Message thread:** AI bubbles (surface, left, bottom-left corner 5px), user bubbles (accent fill, dark text, right, bottom-right corner 5px). Voice messages show a “🎙 Voice · transcribed on device” sub-label.
- **Typing indicator:** 3 animated dots in an AI bubble while generating (prototype delay ~1.1s; real = Gemma streaming).
- **Suggested prompts** (only before first user message): accent-soft pills (“Why was my sleep low this week?”, etc.).
- **Composer:** rounded input “Ask about your health…”; trailing button is **mic** when empty, **send (arrow-up)** when text present. Enter sends.
- **Voice overlay** (mic tapped): blurred fullscreen, “● RECORDING”, mm:ss timer, live waveform bars, on-device framing, cancel (✕) + confirm (✓). Confirm → inserts transcribed message tagged as voice. Wire to `AVAudioRecorder` + Speech/Gemma.

### 5. Settings
- Profile row (avatar initial on accent, name, “34 · 178 cm · Goal: 10k steps”, chevron).
- **ON-DEVICE INTELLIGENCE** card: accent-soft header with cpu tile, “Gemma 3n” + green “Active”, mono “via Edge Gallery · 4-bit · 3.1 GB”, lock note “…never leaves the device”, **storage bar** (3.1 / 8 GB, 39%, accent gradient, animates in). Rows: “Process on device only” (toggle, on), “Re-run weekly analysis” (last run time), “Model & storage”. *Reflect real model state in production.*
- **DATA SOURCES** card: Apple Health (white apple icon, “Connected · 12 data types”, green “Linked”), data-types row (synced time).
- **PREFERENCES** card: Daily suggestions (toggle), Goals, About Ember (v1.0 beta).
- Footer “Ember · Private health intelligence”.

### Tab bar (5 tabs)
Today · Weekly · Insights · Ask · Settings. Active = accent icon + label; icons: house / calendar-grid / sparkle / chat-bubble / sliders. Sits above the home indicator with a fade gradient; hidden during Detail and overrides scroll on Ask (chat manages its own scroll).

### Detail (pushed view, back button top-left)
Reused for Steps / Heart Rate / Sleep: icon tile + title + goal subtitle; big colored value; bar-chart trend (last bar outlined/highlighted; colored when no goal); 2×2 stat tiles; a Gemma note card with on-device chip.

---

## Interactions & Behavior
- **Navigation:** bottom tab switches root views; metric taps push a Detail view (back chevron returns); scroll resets to top on view change.
- **Onboarding** gates the app until complete; “Replay onboarding” available (in prototype via Tweaks; in app put under Settings/dev).
- **Regenerate** (Weekly) and **chat send** show loading states then content — back these with real Gemma calls.
- **Voice** flow: tap mic → record overlay → confirm → transcribe → send.
- **Empty/missing data:** if HealthKit returns no data or access denied, show a connect/permission state (not in prototype — add it).
- **Reduce Motion:** disable looping/entrance animations; keep all content visible.

## State Management
- `onboarded: Bool` (persisted)
- `selectedTab`, `detailMetric: enum? {steps, hr, sleep}`
- Theme prefs: `accent (Rouge/Amber/Iris/Mint)`, `cardStyle (Elevated/Outlined)`, `cornerRadius`, `privacyBanner: Bool` (persist)
- Chat: `[Message]` (role, text, isVoice), `isTyping`, `isRecording`, `recordSeconds`
- Health data models: today snapshot, weekly aggregates + 7-day series per metric, derived deltas vs last week
- Model state: `modelStatus`, `modelSizeBytes`, `lastAnalysisDate`

## Data the prototype mocks (replace with HealthKit + Gemma)
All numbers in the prototype are **placeholder mock data** (see `components.jsx` `DATA`). Source from HealthKit; generate all summaries/suggestions/chat from Gemma. The weekly “score 78”, deltas, highlights, watch-outs, and focus items are illustrative — define a real scoring/prompting approach.

## Assets
No external image assets — all icons are simple inline SVG line glyphs (recreate as SF Symbols where possible: `house`, `calendar`, `sparkles`, `message`, `slider.horizontal.3`, `heart.fill`, `figure.walk`, `moon.fill`, `flame.fill`, `cpu`, `lock.fill`, `shield`, `mic.fill`, `checkmark`, `arrow.up`). The Ember logo is a rounded-square accent tile containing a ring — recreate as a simple vector.

## Files (design references in this bundle)
- `Health Monitor.html` — entry point; loads everything, defines global CSS tokens/animations.
- `app.jsx` — theming (ACCENTS), navigation, tab bar, Tweaks, scroll/banner logic.
- `components.jsx` — icons, Ring, Sparkline, BarChart, Card, chips, **`DATA` mock**.
- `screens-weekly.jsx` — Weekly Status Report (hero).
- `screens.jsx` — Home, Insights (bullets), Detail, Settings.
- `chat.jsx` — Ask Gemma chat + voice overlay (`gemmaReply` = canned replies to swap for real Gemma).
- `onboarding.jsx` — 3-step onboarding + Logo.
- `ios-frame.jsx`, `tweaks-panel.jsx` — prototype-only scaffolding (device bezel + tweak controls); **not needed in the native app**.

> Note: the device bezel, status bar, and Tweaks panel exist only to present the prototype in a browser. In the real app, the screen *content* is what you build; the OS provides the chrome.

## Screenshots (`screenshots/`)
Reference renders of every screen (iPhone frame, Rouge accent):
| File | Screen |
|---|---|
| `01-onboarding.png` | Onboarding — welcome step |
| `02-home.png` | Today / home dashboard |
| `03-weekly-report.png` | Weekly Status Report (hero) |
| `04-insights.png` | Insights — bullet feed + summary graph |
| `05-ask-empty.png` | Ask Gemma — empty state + suggested prompts |
| `06-ask-chat.png` | Ask Gemma — conversation |
| `07-voice-recording.png` | Voice recording overlay |
| `08-settings.png` | Settings — on-device model + data sources |
