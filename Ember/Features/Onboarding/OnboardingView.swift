import SwiftUI

// ─────────────────────────────────────────────────────────────
// Onboarding — Welcome → Your name → Connect Apple Health →
// On-device model setup. Gates the app; persists completion.
// The Connect step triggers the real HealthKit authorization.
// ─────────────────────────────────────────────────────────────
struct OnboardingView: View {
    @Environment(\.theme) private var theme
    @Environment(AppEnvironment.self) private var env
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var nameFocused: Bool

    private enum Step: Int, CaseIterable { case welcome, name, health, model }

    @State private var step: Step = .welcome
    @State private var setup = 0          // model-setup progress 0…100

    private var ctaTitle: String {
        switch step {
        case .welcome: return "Get started"
        case .name:    return "Continue"
        case .health:  return "Allow access"
        case .model:   return setup < 100 ? "Setting up…" : "Enter Ember"
        }
    }
    private var ctaDisabled: Bool { step == .model && setup < 100 }

    var body: some View {
        @Bindable var settings = env.settings

        VStack(spacing: 0) {
            progressDots
                .padding(.top, 20)

            Spacer(minLength: 24)

            Group {
                switch step {
                case .welcome: welcome
                case .name:    nameStep(name: $settings.userName)
                case .health:  connectHealth
                case .model:   modelSetup
                }
            }

            Spacer(minLength: 24)

            cta
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: step) { await runSetupIfNeeded() }
        .onChange(of: step) { _, newStep in nameFocused = (newStep == .name) }
    }

    // MARK: Progress dots

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(Step.allCases, id: \.self) { s in
                Capsule()
                    .fill(s == step ? theme.accentColor : Color.white.opacity(0.16))
                    .frame(width: s == step ? 22 : 6, height: 6)
                    .animation(.easeInOut(duration: 0.3), value: step)
            }
        }
    }

    // MARK: Step 0 — Welcome

    private var welcome: some View {
        VStack(spacing: 0) {
            EmberLogo(size: 76)
            Text("Ember")
                .font(.ui(38, 760))
                .tracking(-0.035 * 38)
                .padding(.top, 28)
            Text("Private health intelligence. Your Apple Health data, understood by an AI that runs entirely on your iPhone.")
                .font(.ui(16.5))
                .foregroundStyle(theme.text2)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: 300)
                .padding(.top, 14)
            HStack(spacing: 7) {
                Icon(.lock, size: 14, color: theme.accentColor, stroke: 1.9)
                Text("100% on-device · nothing leaves your phone")
                    .font(.mono(12.5))
                    .foregroundStyle(theme.accentColor)
            }
            .padding(.top, 22)
        }
    }

    // MARK: Step 1 — Your name

    private func nameStep(name: Binding<String>) -> some View {
        let trimmed = name.wrappedValue.trimmingCharacters(in: .whitespaces)
        let initial = trimmed.first.map { String($0).uppercased() } ?? ""
        return VStack(spacing: 0) {
            ZStack {
                Circle().fill(theme.accentColor).frame(width: 72, height: 72)
                if initial.isEmpty {
                    Image(systemName: "person.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(Theme.darkOnAccent.opacity(0.55))
                } else {
                    Text(initial).font(.ui(30, 700)).foregroundStyle(Theme.darkOnAccent)
                }
            }

            Text("What should we call you?")
                .font(.ui(27, 730))
                .tracking(-0.03 * 27)
                .multilineTextAlignment(.center)
                .padding(.top, 28)
                .padding(.bottom, 8)
            Text("So Ember can greet you and keep your insights personal.")
                .font(.ui(14.5))
                .foregroundStyle(theme.text2)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: 300)
                .padding(.bottom, 24)

            TextField("Your name", text: name)
                .focused($nameFocused)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit(advance)
                .font(.ui(17, 540))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: 320)
                .background(theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(nameFocused ? theme.accentLine : theme.cardBorder, lineWidth: 1)
                )
        }
    }

    // MARK: Step 2 — Connect Apple Health

    private var connectHealth: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.white)
                    .frame(width: 64, height: 64)
                Icon(.heart, size: 34, color: Theme.heart, stroke: 2, fill: true)
            }
            .padding(.bottom, 26)

            Text("Connect Apple Health")
                .font(.ui(27, 730))
                .tracking(-0.03 * 27)
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)
            Text("Ember reads these to build your daily and weekly insights.")
                .font(.ui(14.5))
                .foregroundStyle(theme.text2)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: 300)
                .padding(.bottom, 26)

            VStack(spacing: 10) {
                dataTypeRow(.steps, "Steps & Distance", theme.accentColor, fill: false)
                dataTypeRow(.heart, "Heart Rate & HRV", Theme.heart, fill: true)
                dataTypeRow(.moon, "Sleep Analysis", Theme.sleep, fill: false)
                dataTypeRow(.flame, "Active Energy", theme.accent2Color, fill: false)
            }
        }
    }

    private func dataTypeRow(_ glyph: Glyph, _ label: String, _ color: Color, fill: Bool) -> some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 32, height: 32)
                Icon(glyph, size: 17, color: color, stroke: 2, fill: fill)
            }
            Text(label).font(.ui(15, 540))
            Spacer()
            Icon(.check, size: 17, color: theme.good, stroke: 2.4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(theme.cardBorder, lineWidth: 1))
    }

    // MARK: Step 3 — On-device model setup

    private var modelSetup: some View {
        VStack(spacing: 0) {
            Ring(size: 140, stroke: 10, value: Double(setup), maxValue: 100,
                 gradient: [theme.accent2Color, theme.accentColor]) {
                if setup < 100 {
                    VStack(spacing: 0) {
                        Text("\(setup)%").font(.ui(30, 750)).tracking(-0.03 * 30)
                        Text("preparing").font(.mono(10.5)).foregroundStyle(theme.text3)
                    }
                } else {
                    Icon(.check, size: 46, color: theme.accentColor, stroke: 2.6)
                }
            }

            Text(setup < 100 ? "Setting up Gemma on-device" : "Ready to go")
                .font(.ui(25, 730))
                .tracking(-0.03 * 25)
                .multilineTextAlignment(.center)
                .padding(.top, 28)
                .padding(.bottom, 8)

            Text(setup < 100
                 ? "Loading the Gemma 3n model via Edge Gallery. This runs locally — no account, no cloud."
                 : "Your on-device model is active. Ember will analyze your health data privately, right here.")
                .font(.ui(14.5))
                .foregroundStyle(theme.text2)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: 300)

            GemmaChip(label: "Gemma 3n · Edge Gallery")
                .padding(.top, 18)
        }
    }

    // MARK: CTA

    private var cta: some View {
        VStack(spacing: 10) {
            Button(action: advance) {
                Text(ctaTitle)
                    .font(.ui(16.5, 680))
                    .foregroundStyle(ctaDisabled ? theme.text3 : Theme.darkOnAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(ctaDisabled ? Color.white.opacity(0.1) : theme.accentColor,
                               in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(ctaDisabled)

            if step != .model {
                Button(action: finish) {
                    Text("Skip for now")
                        .font(.ui(14))
                        .foregroundStyle(theme.text3)
                        .padding(8)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Actions

    private func advance() {
        nameFocused = false
        Task {
            if step == .health {
                _ = await env.health.requestAuthorization()
            }
            if let next = Step(rawValue: step.rawValue + 1) {
                withAnimation(.easeInOut(duration: 0.25)) { step = next }
            } else {
                finish()
            }
        }
    }

    private func finish() {
        env.settings.completeOnboarding()
    }

    private func runSetupIfNeeded() async {
        guard step == .model else { return }
        setup = 0
        if reduceMotion { setup = 100; return }
        while setup < 100 {
            try? await Task.sleep(nanoseconds: 45_000_000)
            if Task.isCancelled { return }
            setup = min(100, setup + 4)
        }
    }
}
