import SwiftUI

// ─────────────────────────────────────────────────────────────
// Navigation state — bottom tab + pushed metric Detail.
// ─────────────────────────────────────────────────────────────
@Observable
final class AppRouter {
    enum Tab: String, CaseIterable, Hashable {
        case today, weekly, insights, ask, settings
    }

    var tab: Tab = .today
    var detail: MetricKind? = nil

    init() {
        #if DEBUG
        // Debug-only deep link for screenshot/verification, set via launch args
        // (e.g. `-ember.debugTab weekly`, `-ember.debugDetail hr`). No effect in Release.
        let defaults = UserDefaults.standard
        if let raw = defaults.string(forKey: "ember.debugTab"), let t = Tab(rawValue: raw) {
            tab = t
        }
        if let raw = defaults.string(forKey: "ember.debugDetail"), let m = MetricKind(rawValue: raw) {
            detail = m
        }
        #endif
    }

    func select(_ t: Tab) { detail = nil; tab = t }
    func open(_ metric: MetricKind) { detail = metric }
    func closeDetail() { detail = nil }
}

// ─────────────────────────────────────────────────────────────
// RootView — onboarding gate → main shell (custom tab bar +
// floating privacy banner + pushed Detail).
// ─────────────────────────────────────────────────────────────
struct RootView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var router = AppRouter()

    var body: some View {
        let theme = env.settings.theme
        ZStack {
            theme.bg.ignoresSafeArea()

            if env.settings.onboarded {
                shell
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .environment(\.theme, theme)
        .environment(router)
        .tint(theme.accentColor)
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.4), value: env.settings.onboarded)
    }

    @ViewBuilder
    private var shell: some View {
        currentScreen
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if router.detail == nil {
                    TabBar(router: router)
                }
            }
    }

    @ViewBuilder
    private var currentScreen: some View {
        if let metric = router.detail {
            DetailView(metric: metric)
                .id(metric)
                .transition(.move(edge: .trailing).combined(with: .opacity))
        } else {
            switch router.tab {
            case .today:    TodayView().id(AppRouter.Tab.today)
            case .weekly:   WeeklyView().id(AppRouter.Tab.weekly)
            case .insights: InsightsView().id(AppRouter.Tab.insights)
            case .ask:      AskView().id(AppRouter.Tab.ask)
            case .settings: SettingsView().id(AppRouter.Tab.settings)
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────
// Bottom tab bar — custom, with a fade gradient over content.
// ─────────────────────────────────────────────────────────────
struct TabBar: View {
    @Environment(\.theme) private var theme
    let router: AppRouter

    private let items: [(tab: AppRouter.Tab, label: String, glyph: Glyph)] = [
        (.today, "Today", .home),
        (.weekly, "Weekly", .weekly),
        (.insights, "Insights", .spark),
        (.ask, "Ask", .chat),
        (.settings, "Settings", .sliders),
    ]

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            ForEach(items, id: \.tab) { item in
                let on = router.tab == item.tab
                Button { router.select(item.tab) } label: {
                    VStack(spacing: 4) {
                        Icon(item.glyph, size: 23,
                             color: on ? theme.accentColor : theme.text3,
                             stroke: on ? 2.3 : 2,
                             fill: on && item.tab == .today)
                        Text(item.label)
                            .font(.ui(10.5, on ? 680 : 540))
                            .foregroundStyle(on ? theme.accentColor : theme.text3)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 6)
        .background(
            LinearGradient(colors: [theme.bg, theme.bg, theme.bg.opacity(0)],
                           startPoint: .bottom, endPoint: .top)
        )
    }
}
