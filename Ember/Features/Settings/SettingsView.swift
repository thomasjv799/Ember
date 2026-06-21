import SwiftUI

// ─────────────────────────────────────────────────────────────
// Settings — profile, on-device model card, data sources,
// preferences, plus appearance controls (the prototype's Tweaks
// panel was browser-only) and Replay onboarding.
// ─────────────────────────────────────────────────────────────
struct SettingsView: View {
    @Environment(\.theme) private var theme
    @Environment(AppEnvironment.self) private var env
    @State private var showModelSetup = false

    private var modelStatus: ModelStatus {
        if case .installed(let bytes) = env.modelManager.status {
            let gb = Double(bytes) / 1_073_741_824
            return ModelStatus(name: "Gemma 3n", stateLabel: "Active",
                               detail: String(format: "LiteRT-LM · on-device · %.1f GB", gb),
                               isActive: true, usedGB: gb, totalGB: 8, lastRun: "On-device")
        }
        return ModelStatus(name: "Gemma 3n", stateLabel: "Not loaded",
                           detail: "Set up the on-device model to enable AI",
                           isActive: false, usedGB: 0, totalGB: 8, lastRun: "—")
    }

    var body: some View {
        @Bindable var settings = env.settings
        let status = modelStatus

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                Text("Settings").font(.ui(27, 740)).tracking(-0.025 * 27)
                    .padding(.horizontal, DS.headerH)

                profile
                modelCard(status, onDevice: $settings.processOnDeviceOnly)
                dataSources
                preferences(dailySuggestions: $settings.dailySuggestions)
                appearance(radius: $settings.cornerRadius, banner: $settings.privacyBanner)
                footer
            }
            .padding(.top, 8)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .screenEnter()
        .privacyBanner()
        .sheet(isPresented: $showModelSetup) { ModelSetupView() }
    }

    // MARK: Profile

    private var profile: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(theme.accentColor).frame(width: 56, height: 56)
                Text(env.settings.initials).font(.ui(24, 700)).foregroundStyle(Theme.darkOnAccent)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(env.settings.displayName).font(.ui(19, 680))
                Text(MockData.profileLine).font(.ui(13)).foregroundStyle(theme.text3)
            }
            Spacer()
            Icon(.chevron, size: 18, color: theme.text3, stroke: 2)
        }
        .padding(.horizontal, DS.screenH + 4)
    }

    // MARK: On-device intelligence

    private func modelCard(_ status: ModelStatus, onDevice: Binding<Bool>) -> some View {
        section("On-device intelligence") {
            Card(pad: 0) {
                VStack(spacing: 0) {
                    modelHeader(status)
                    SettingsRow(glyph: .shield, title: "Process on device only",
                                detail: "No cloud, no network calls") {
                        EmberToggle(isOn: onDevice)
                    }
                    divider
                    Button { showModelSetup = true } label: {
                        SettingsRow(glyph: .chip,
                                    title: status.isActive ? "Model & storage" : "Set up Gemma model",
                                    detail: status.isActive
                                        ? "\(String(format: "%.1f", status.usedGB)) GB · manage or remove"
                                        : "Download or import a .litertlm") { chevron }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func modelHeader(_ status: ModelStatus) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 13) {
                ZStack {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(theme.accentColor).frame(width: 44, height: 44)
                    Icon(.chip, size: 23, color: Theme.darkOnAccent, stroke: 1.9)
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(status.name).font(.ui(16, 700))
                        HStack(spacing: 5) {
                            Circle().fill(status.isActive ? theme.good : theme.text3).frame(width: 6, height: 6)
                            Text(status.stateLabel).font(.mono(11.5)).foregroundStyle(status.isActive ? theme.good : theme.text3)
                        }
                    }
                    Text(status.detail).font(.mono(12.5)).foregroundStyle(theme.text2)
                }
                Spacer(minLength: 0)
            }

            HStack(alignment: .top, spacing: 8) {
                Icon(.lock, size: 15, color: theme.accentColor, stroke: 1.9)
                (Text("Your health data is analyzed on this iPhone and ")
                    + Text("never leaves the device").foregroundColor(theme.textColor).bold()
                    + Text("."))
                    .font(.ui(12.5)).foregroundStyle(theme.text2).lineSpacing(2)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.top, 14)

            storageBar(status).padding(.top, 14)
        }
        .padding(18)
        .background(theme.accentSoft)
        .overlay(alignment: .bottom) { Rectangle().fill(theme.hair).frame(height: 1) }
    }

    private func storageBar(_ status: ModelStatus) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text("STORAGE · \(String(format: "%.1f", status.usedGB)) / \(Int(status.totalGB)) GB")
                    .font(.mono(11)).tracking(0.04 * 11).foregroundStyle(theme.text3)
                Spacer()
                Text("\(status.storagePercent)%").font(.mono(11)).foregroundStyle(theme.accentColor)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.black.opacity(0.28))
                    Capsule()
                        .fill(LinearGradient(colors: [theme.accent2Color, theme.accentColor],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(status.storagePercent) / 100)
                }
            }
            .frame(height: 8)
        }
    }

    // MARK: Data sources

    private var dataSources: some View {
        section("Data sources") {
            Card(pad: 0) {
                VStack(spacing: 0) {
                    SettingsRow(glyph: .apple, iconBg: .white, iconColor: .black,
                                title: "Apple Health", detail: "Connected · 12 data types") {
                        HStack(spacing: 5) {
                            Circle().fill(theme.good).frame(width: 6, height: 6)
                            Text("Linked").font(.ui(12.5, 600)).foregroundStyle(theme.good)
                        }
                    }
                    divider
                    SettingsRow(glyph: .heart, iconBg: Theme.heart, fill: true,
                                title: "Steps, Heart, Sleep, Energy",
                                detail: "Read access · synced 2m ago") { chevron }
                }
            }
        }
    }

    // MARK: Preferences

    private func preferences(dailySuggestions: Binding<Bool>) -> some View {
        section("Preferences") {
            Card(pad: 0) {
                VStack(spacing: 0) {
                    SettingsRow(glyph: .bell, title: "Daily suggestions") {
                        EmberToggle(isOn: dailySuggestions)
                    }
                    divider
                    SettingsRow(glyph: .target, title: "Goals", detail: "Steps, sleep, energy") { chevron }
                    divider
                    SettingsRow(glyph: .info, title: "About Ember", detail: "Version 1.0 (beta)") { chevron }
                }
            }
        }
    }

    // MARK: Appearance (replaces the browser-only Tweaks panel)

    private func appearance(radius: Binding<Double>, banner: Binding<Bool>) -> some View {
        section("Appearance") {
            Card(pad: 16) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        rowLabel("Accent")
                        HStack(spacing: 14) {
                            ForEach(AccentTheme.allCases) { option in
                                Button { env.settings.accent = option } label: {
                                    Circle()
                                        .fill(option.accent)
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(theme.textColor,
                                                              lineWidth: env.settings.accent == option ? 2.5 : 0)
                                                .padding(-3)
                                        )
                                }.buttonStyle(.plain)
                            }
                            Spacer()
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        rowLabel("Cards")
                        HStack(spacing: 8) {
                            ForEach(CardStyle.allCases) { option in
                                let on = env.settings.cardStyle == option
                                Button { env.settings.cardStyle = option } label: {
                                    Text(option.rawValue)
                                        .font(.ui(13, 600))
                                        .foregroundStyle(on ? Theme.darkOnAccent : theme.text2)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(on ? theme.accentColor : .clear, in: Capsule())
                                        .overlay(Capsule().strokeBorder(on ? .clear : theme.hairStrong, lineWidth: 1))
                                }.buttonStyle(.plain)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            rowLabel("Corner radius")
                            Spacer()
                            Text("\(Int(radius.wrappedValue))px").font(.mono(12)).foregroundStyle(theme.text3)
                        }
                        Slider(value: radius, in: 10...30, step: 1).tint(theme.accentColor)
                    }

                    HStack {
                        rowLabel("On-device banner")
                        Spacer()
                        EmberToggle(isOn: banner)
                    }

                    Button { env.settings.replayOnboarding() } label: {
                        Text("Replay onboarding").font(.ui(14, 600)).foregroundStyle(theme.accentColor)
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Footer

    private var footer: some View {
        Text("Ember · Private health intelligence")
            .font(.mono(11)).foregroundStyle(theme.text3)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: Helpers

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel(title)
            content()
        }
        .padding(.horizontal, DS.screenH)
    }

    private func rowLabel(_ text: String) -> some View {
        Text(text).font(.ui(14, 540)).foregroundStyle(theme.textColor)
    }

    private var divider: some View { Rectangle().fill(theme.hair).frame(height: 1) }
    private var chevron: some View { Icon(.chevron, size: 16, color: theme.text3, stroke: 2) }
}

// ─────────────────────────────────────────────────────────────
// One settings row: icon tile, title/detail, trailing control.
// ─────────────────────────────────────────────────────────────
private struct SettingsRow<Right: View>: View {
    @Environment(\.theme) private var theme

    let glyph: Glyph
    var iconBg: Color? = nil
    var iconColor: Color = .white
    var fill: Bool = false
    let title: String
    var detail: String? = nil
    @ViewBuilder var right: () -> Right

    var body: some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconBg ?? Color.white.opacity(0.08))
                    .frame(width: 30, height: 30)
                Icon(glyph, size: 16, color: iconColor, stroke: 2, fill: fill)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.ui(15, 520))
                if let detail {
                    Text(detail).font(.ui(12.5)).foregroundStyle(theme.text3)
                }
            }
            Spacer(minLength: 8)
            right()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}
