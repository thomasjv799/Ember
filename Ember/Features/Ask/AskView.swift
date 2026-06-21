import SwiftUI

// ─────────────────────────────────────────────────────────────
// Ask — chat with the on-device Gemma assistant + voice capture.
// AI bubbles left, user bubbles right; streaming replies; voice
// overlay transcribes on-device and sends tagged as voice.
// ─────────────────────────────────────────────────────────────
struct AskView: View {
    @Environment(\.theme) private var theme
    @Environment(AppEnvironment.self) private var env

    @State private var messages: [ChatMessage] = []
    @State private var draft = ""
    @State private var generating = false
    @State private var recording = false
    @State private var replyTask: Task<Void, Never>?
    @State private var today = MockData.today
    @State private var week = MockData.week

    private var showSuggestions: Bool { messages.filter { $0.role == .user }.isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            header
            if env.hasIntelligence {
                thread
                if showSuggestions { suggestions }
                composer
            } else {
                Spacer(minLength: 0)
                EnableIntelligenceCard(message: "Load Gemma to chat about your health — fully on-device.")
                    .padding(.horizontal, DS.screenH)
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .screenEnter()
        .task {
            today = await env.health.todaySnapshot()
            week = await env.health.weeklyReport()
            if messages.isEmpty, let llm = env.intelligence() {
                messages = [ChatMessage(role: .ai, text: llm.greeting(for: env.settings.displayName))]
            }
        }
        .fullScreenCover(isPresented: $recording) {
            VoiceOverlay(onCancel: cancelVoice, onConfirm: confirmVoice)
                .presentationBackground(.ultraThinMaterial)
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(theme.accentColor)
                    .frame(width: 40, height: 40)
                Icon(.chip, size: 21, color: Theme.darkOnAccent, stroke: 1.9)
            }
            .glowPulse()
            VStack(alignment: .leading, spacing: 1) {
                Text("Ask Gemma").font(.ui(21, 720)).tracking(-0.02 * 21)
                HStack(spacing: 5) {
                    LiveDot(color: theme.good, size: 6)
                    Text("On-device · Gemma 3n").font(.mono(11.5)).foregroundStyle(theme.good)
                }
            }
            Spacer()
        }
        .padding(.horizontal, DS.headerH)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    // MARK: Thread

    private var thread: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                    }
                    if generating {
                        HStack { TypingDots(); Spacer(minLength: 0) }
                    }
                    Color.clear.frame(height: 1).id(scrollAnchor)
                }
                .padding(.horizontal, DS.screenH)
                .padding(.top, 4)
                .padding(.bottom, 8)
            }
            .onChange(of: messages.last?.text) { _, _ in scrollToBottom(proxy) }
            .onChange(of: messages.count) { _, _ in scrollToBottom(proxy) }
            .onChange(of: generating) { _, _ in scrollToBottom(proxy) }
        }
    }

    private let scrollAnchor = "thread-bottom"

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(scrollAnchor, anchor: .bottom)
        }
    }

    // MARK: Suggested prompts

    private var suggestions: some View {
        FlowChips(items: env.intelligence()?.suggestedPrompts ?? []) { prompt in
            send(prompt)
        }
        .padding(.horizontal, DS.screenH)
        .padding(.bottom, 10)
    }

    // MARK: Composer

    private var composer: some View {
        HStack(spacing: 9) {
            HStack(spacing: 8) {
                TextField("", text: $draft, prompt: Text("Ask about your health…").foregroundColor(theme.text3))
                    .font(.ui(15))
                    .foregroundStyle(theme.textColor)
                    .submitLabel(.send)
                    .onSubmit { send(draft) }
                if draft.trimmingCharacters(in: .whitespaces).isEmpty {
                    Button(action: startVoice) {
                        circleButton(bg: theme.accentSoft) {
                            Icon(.mic, size: 19, color: theme.accentColor, stroke: 2.1)
                        }
                    }.buttonStyle(.plain)
                } else {
                    Button { send(draft) } label: {
                        circleButton(bg: theme.accentColor) {
                            Icon(.arrowUp, size: 20, color: Theme.darkOnAccent, stroke: 2.4)
                        }
                    }.buttonStyle(.plain)
                }
            }
            .padding(.leading, 16)
            .padding(.trailing, 4)
            .padding(.vertical, 4)
            .background(theme.surface, in: Capsule())
            .overlay(Capsule().strokeBorder(theme.cardBorder, lineWidth: 1))
        }
        .padding(.horizontal, DS.screenH)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    private func circleButton<Content: View>(bg: Color, @ViewBuilder _ content: () -> Content) -> some View {
        ZStack { Circle().fill(bg).frame(width: 38, height: 38); content() }
    }

    // MARK: Send + streaming

    private func send(_ text: String, voice: Bool = false) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        draft = ""
        messages.append(ChatMessage(role: .user, text: trimmed, isVoice: voice))
        generating = true

        replyTask?.cancel()
        replyTask = Task {
            guard let llm = env.intelligence() else { generating = false; return }
            let context = HealthContext.string(today: today, week: week)
            var startedReply = false
            for await chunk in llm.reply(to: trimmed, context: context) {
                if Task.isCancelled { break }
                if !startedReply {
                    generating = false
                    messages.append(ChatMessage(role: .ai, text: ""))
                    startedReply = true
                }
                if let last = messages.indices.last {
                    messages[last].text += chunk
                }
            }
            if !startedReply { generating = false }
        }
    }

    // MARK: Voice

    private func startVoice() {
        Task {
            guard await env.speech.requestAuthorization() else { return }
            try? env.speech.startRecording()
            recording = true
        }
    }

    private func confirmVoice() {
        Task {
            let transcript = await env.speech.stopRecording()
            recording = false
            let text = transcript.isEmpty ? "How's my recovery looking after this week?" : transcript
            send(text, voice: true)
        }
    }

    private func cancelVoice() {
        Task {
            _ = await env.speech.stopRecording()
            recording = false
        }
    }
}

// ─────────────────────────────────────────────────────────────
// Message bubble.
// ─────────────────────────────────────────────────────────────
private struct MessageBubble: View {
    @Environment(\.theme) private var theme
    let message: ChatMessage

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 40) }
            VStack(alignment: .leading, spacing: 6) {
                if message.isVoice {
                    HStack(spacing: 6) {
                        Icon(.mic, size: 13, color: Theme.darkOnAccent, stroke: 2)
                        Text("Voice · transcribed on device").font(.mono(11)).foregroundStyle(Theme.darkOnAccent)
                    }
                    .opacity(0.7)
                }
                Text(message.text)
                    .font(.ui(14.5, isUser ? 540 : 400))
                    .foregroundStyle(isUser ? Theme.darkOnAccent : theme.textColor)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(isUser ? theme.accentColor : theme.surface)
            .clipShape(BubbleShape(isUser: isUser))
            .overlay(isUser ? nil : BubbleShape(isUser: isUser).strokeBorder(theme.cardBorder, lineWidth: 1))
            .frame(maxWidth: 300, alignment: isUser ? .trailing : .leading)
            if !isUser { Spacer(minLength: 40) }
        }
    }
}

private struct BubbleShape: InsettableShape {
    var isUser: Bool
    var inset: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: inset, dy: inset)
        let shape = UnevenRoundedRectangle(
            cornerRadii: .init(
                topLeading: 18,
                bottomLeading: isUser ? 18 : 5,
                bottomTrailing: isUser ? 5 : 18,
                topTrailing: 18
            ),
            style: .continuous
        )
        return shape.path(in: r)
    }

    func inset(by amount: CGFloat) -> BubbleShape {
        var copy = self
        copy.inset += amount
        return copy
    }
}

// ─────────────────────────────────────────────────────────────
// Typing indicator — three dots translate + fade, staggered.
// ─────────────────────────────────────────────────────────────
private struct TypingDots: View {
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animating = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(theme.text3)
                    .frame(width: 7, height: 7)
                    .offset(y: animating ? -3 : 0)
                    .opacity(animating ? 1 : 0.4)
                    .animation(reduceMotion ? nil : Motion.typeDot(delay: Double(i) * 0.16), value: animating)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(theme.surface)
        .clipShape(BubbleShape(isUser: false))
        .overlay(BubbleShape(isUser: false).strokeBorder(theme.cardBorder, lineWidth: 1))
        .onAppear { animating = true }
    }
}

// ─────────────────────────────────────────────────────────────
// Suggested-prompt chips (wrap to multiple lines).
// ─────────────────────────────────────────────────────────────
private struct FlowChips: View {
    @Environment(\.theme) private var theme
    let items: [String]
    var onTap: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                Button { onTap(item) } label: {
                    Text(item)
                        .font(.ui(12.5, 560))
                        .foregroundStyle(theme.accentColor)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 8)
                        .background(theme.accentSoft, in: Capsule())
                        .overlay(Capsule().strokeBorder(theme.accentLine, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// ─────────────────────────────────────────────────────────────
// Voice recording overlay.
// ─────────────────────────────────────────────────────────────
private struct VoiceOverlay: View {
    @Environment(\.theme) private var theme
    var onCancel: () -> Void
    var onConfirm: () -> Void

    @State private var seconds = 0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var clock: String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    var body: some View {
        ZStack {
            Color(hex: 0x080706, alpha: 0.82).ignoresSafeArea()

            VStack(spacing: 0) {
                Text("● RECORDING")
                    .font(.mono(12.5)).tracking(0.06 * 12.5).foregroundStyle(theme.accentColor)
                    .padding(.bottom, 6)
                Text(clock)
                    .font(.ui(44, 760)).tracking(-0.03 * 44).monospacedDigit()

                HStack(spacing: 4) {
                    ForEach(0..<27, id: \.self) { i in
                        WaveBar(delay: Double(i % 9) * 0.09)
                    }
                }
                .frame(height: 64)
                .padding(.top, 26)
                .padding(.bottom, 8)

                (Text("Speak your question — Gemma transcribes and understands it ")
                    + Text("entirely on device").foregroundColor(theme.textColor).bold()
                    + Text("."))
                    .font(.ui(13)).foregroundStyle(theme.text2)
                    .multilineTextAlignment(.center).lineSpacing(3)
                    .frame(maxWidth: 260)

                HStack(spacing: 16) {
                    Button(action: onCancel) {
                        ZStack {
                            Circle().fill(theme.surface).frame(width: 56, height: 56)
                                .overlay(Circle().strokeBorder(theme.hairStrong, lineWidth: 1))
                            Icon(.plus, size: 24, color: theme.text2, stroke: 2.2).rotationEffect(.degrees(45))
                        }
                    }.buttonStyle(.plain)

                    Button(action: onConfirm) {
                        ZStack {
                            Circle().fill(theme.accentColor).frame(width: 72, height: 72)
                                .overlay(Circle().strokeBorder(theme.accentSoft, lineWidth: 6))
                            Icon(.check, size: 30, color: Theme.darkOnAccent, stroke: 2.6)
                        }
                    }.buttonStyle(.plain)

                    Color.clear.frame(width: 56, height: 56)
                }
                .padding(.top, 34)
            }
            .padding(32)
        }
        .onReceive(timer) { _ in seconds += 1 }
    }
}

private struct WaveBar: View {
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let delay: Double
    @State private var tall = false

    var body: some View {
        Capsule()
            .fill(theme.accentColor)
            .frame(width: 4, height: tall ? 44 : 12)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(Motion.waveBar(delay: delay)) { tall = true }
            }
    }
}
