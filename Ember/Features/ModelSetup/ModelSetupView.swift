import SwiftUI
import UniformTypeIdentifiers

// ─────────────────────────────────────────────────────────────
// ModelSetupView — get a Gemma `.litertlm` model into Ember:
// download from Hugging Face (token), import from Files, or see
// the auto-detected installed model. Presented as a sheet.
// ─────────────────────────────────────────────────────────────
struct ModelSetupView: View {
    @Environment(\.theme) private var theme
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @State private var showImporter = false

    var body: some View {
        @Bindable var mm = env.modelManager

        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    intro
                    switch mm.status {
                    case .installed(let bytes): installedCard(bytes)
                    case .downloading(let p, let received, let total): downloadingCard(p, received, total)
                    case .importing: importingCard
                    default: setupForm($mm)
                    }
                    if case .failed(let message) = mm.status { errorCard(message) }
                }
                .padding(16)
            }
            .background(theme.bg)
            .navigationTitle("On-device AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.foregroundStyle(theme.accentColor)
                }
            }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.item], allowsMultipleSelection: false) { result in
                if case .success(let urls) = result, let url = urls.first {
                    env.modelManager.importModel(from: url)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Intro / privacy

    private var intro: some View {
        Card(pad: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Icon(.chip, size: 20, color: theme.accentColor)
                    Text("Gemma runs entirely on this iPhone").font(.ui(15.5, 680))
                }
                Text("Ember needs a Gemma `.litertlm` model on the device. The download is the **only** time the app uses the network — your health data and all answers stay on-device.")
                    .font(.ui(13.5)).foregroundStyle(theme.text2).lineSpacing(3)
            }
        }
    }

    // MARK: Installed

    private func installedCard(_ bytes: Int64) -> some View {
        Card(pad: 16) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Icon(.check, size: 20, color: theme.good, stroke: 2.4)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Model installed").font(.ui(15.5, 680))
                        Text(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file))
                            .font(.mono(12.5)).foregroundStyle(theme.text2)
                    }
                }
                Button(role: .destructive) { env.modelManager.deleteModel() } label: {
                    Text("Remove model").font(.ui(14.5, 600)).foregroundStyle(theme.accentColor)
                        .frame(maxWidth: .infinity).frame(height: 44)
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(theme.accentLine, lineWidth: 1))
                }.buttonStyle(.plain)
            }
        }
    }

    // MARK: Downloading / importing

    private func downloadingCard(_ progress: Double, _ received: Int64, _ total: Int64) -> some View {
        Card(pad: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Downloading model…").font(.ui(15.5, 680))
                ProgressView(value: max(progress, 0.001)).tint(theme.accentColor)
                HStack {
                    Text(byteLine(received, total)).font(.mono(12)).foregroundStyle(theme.text2)
                    Spacer()
                    Text("\(Int(progress * 100))%").font(.mono(12)).foregroundStyle(theme.accentColor)
                }
                Button { env.modelManager.cancelDownload() } label: {
                    Text("Cancel").font(.ui(14.5, 600)).foregroundStyle(theme.text2)
                        .frame(maxWidth: .infinity).frame(height: 44)
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(theme.hairStrong, lineWidth: 1))
                }.buttonStyle(.plain)
            }
        }
    }

    private var importingCard: some View {
        Card(pad: 16) {
            HStack(spacing: 10) {
                ProgressView().tint(theme.accentColor)
                Text("Importing model…").font(.ui(15.5, 600))
            }
        }
    }

    private func errorCard(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Icon(.info, size: 15, color: theme.accentColor, stroke: 2)
            Text(message).font(.ui(13)).foregroundStyle(theme.accentColor).lineSpacing(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.accentSoft, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: Setup form (download + import)

    private func setupForm(_ mm: Bindable<ModelManager>) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Download from Hugging Face
            Card(pad: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    SectionLabel("Download from Hugging Face")
                    field("Access token", text: mm.hfToken, placeholder: "hf_…", secure: true)
                    Text("Create a read token at huggingface.co/settings/tokens and accept the model's license.")
                        .font(.ui(11.5)).foregroundStyle(theme.text3).lineSpacing(2)
                    field("Repository", text: mm.repo, placeholder: "org/gemma-3n-…-litertlm")
                    field("Filename", text: mm.filename, placeholder: "model.litertlm")
                    Button { env.modelManager.startDownload() } label: {
                        Text("Download").font(.ui(15, 680)).foregroundStyle(Theme.darkOnAccent)
                            .frame(maxWidth: .infinity).frame(height: 46)
                            .background(theme.accentColor, in: RoundedRectangle(cornerRadius: 12))
                    }.buttonStyle(.plain)
                }
            }

            // Import from Files
            Card(pad: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel("Already have a model?")
                    Text("Import a `.litertlm` file from Files (e.g. one you downloaded or exported), or drop it into Ember's folder via Finder.")
                        .font(.ui(13)).foregroundStyle(theme.text2).lineSpacing(2)
                    Button { showImporter = true } label: {
                        Text("Choose from Files").font(.ui(14.5, 680)).foregroundStyle(theme.accentColor)
                            .frame(maxWidth: .infinity).frame(height: 44)
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(theme.accentLine, lineWidth: 1))
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    private func field(_ label: String, text: Binding<String>, placeholder: String, secure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label.uppercased()).font(.mono(10.5)).tracking(0.04 * 10.5).foregroundStyle(theme.text3)
            Group {
                if secure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }
            .font(.ui(15))
            .padding(.horizontal, 12).padding(.vertical, 11)
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(theme.cardBorder, lineWidth: 1))
        }
    }

    private func byteLine(_ received: Int64, _ total: Int64) -> String {
        let r = ByteCountFormatter.string(fromByteCount: received, countStyle: .file)
        guard total > 0 else { return r }
        return "\(r) / \(ByteCountFormatter.string(fromByteCount: total, countStyle: .file))"
    }
}

// ─────────────────────────────────────────────────────────────
// EnableIntelligenceCard — shown on AI surfaces when no model is
// loaded. Opens Model Setup.
// ─────────────────────────────────────────────────────────────
struct EnableIntelligenceCard: View {
    @Environment(\.theme) private var theme
    var message: String = "Load a Gemma model to generate this privately, on-device."
    @State private var showSetup = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 11) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous).fill(theme.accentSoft).frame(width: 40, height: 40)
                    Icon(.chip, size: 20, color: theme.accentColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Enable on-device intelligence").font(.ui(15.5, 680))
                    Text(message).font(.ui(13)).foregroundStyle(theme.text2).lineSpacing(2)
                }
            }
            Button { showSetup = true } label: {
                Text("Set up Gemma").font(.ui(14.5, 680)).foregroundStyle(Theme.darkOnAccent)
                    .frame(maxWidth: .infinity).frame(height: 44)
                    .background(theme.accentColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }.buttonStyle(.plain)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: theme.radius, style: .continuous)
                .strokeBorder(theme.accentLine, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
        )
        .sheet(isPresented: $showSetup) { ModelSetupView() }
    }
}
