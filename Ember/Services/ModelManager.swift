import Foundation
import Observation

// ─────────────────────────────────────────────────────────────
// ModelManager — acquires and tracks the on-device `.litertlm`
// model. Three ways in: download from Hugging Face (token), import
// from Files, or auto-detect a file dropped into the app's folder.
// The model lives in Documents/Models/ and is found by GemmaModel.
// ─────────────────────────────────────────────────────────────
@MainActor
@Observable
final class ModelManager: NSObject, URLSessionDownloadDelegate {

    enum Status: Equatable {
        case notInstalled
        case downloading(progress: Double, received: Int64, total: Int64)
        case importing
        case installed(sizeBytes: Int64)
        case failed(String)
    }

    private(set) var status: Status = .notInstalled

    // Download configuration (persisted, except token which is Keychain-backed).
    var repo: String { didSet { ud.set(repo, forKey: Keys.repo) } }
    var filename: String { didSet { ud.set(filename, forKey: Keys.filename) } }
    var revision: String { didSet { ud.set(revision, forKey: Keys.revision) } }
    var hfToken: String { didSet { hfToken.isEmpty ? KeychainTokenStore.clear() : KeychainTokenStore.save(hfToken) } }

    @ObservationIgnored private let ud = UserDefaults.standard
    @ObservationIgnored private var downloadTask: URLSessionDownloadTask?
    @ObservationIgnored nonisolated(unsafe) private var pendingFilename = ""
    @ObservationIgnored private lazy var session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)

    override init() {
        repo = ud.string(forKey: Keys.repo) ?? ""
        filename = ud.string(forKey: Keys.filename) ?? ""
        revision = ud.string(forKey: Keys.revision) ?? "main"
        hfToken = KeychainTokenStore.load() ?? ""
        super.init()
        refresh()
    }

    var isInstalled: Bool { GemmaModel.installedModelPath() != nil }

    nonisolated static var modelsDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("Models", isDirectory: true)
    }

    /// Re-derive status from disk (call after external file drops).
    func refresh() {
        if case .downloading = status { return }
        if case .importing = status { return }
        if let path = GemmaModel.installedModelPath(),
           let size = (try? FileManager.default.attributesOfItem(atPath: path)[.size] as? NSNumber)?.int64Value {
            status = .installed(sizeBytes: size)
        } else {
            status = .notInstalled
        }
    }

    // MARK: Download (Hugging Face)

    func startDownload() {
        let r = repo.trimmingCharacters(in: .whitespaces)
        let f = filename.trimmingCharacters(in: .whitespaces)
        guard !r.isEmpty, !f.isEmpty else {
            status = .failed("Enter a repo and filename first.")
            return
        }
        let rev = revision.trimmingCharacters(in: .whitespaces).isEmpty ? "main" : revision
        guard let url = URL(string: "https://huggingface.co/\(r)/resolve/\(rev)/\(f)?download=true") else {
            status = .failed("Invalid repo/filename.")
            return
        }
        var request = URLRequest(url: url)
        if !hfToken.isEmpty {
            request.setValue("Bearer \(hfToken)", forHTTPHeaderField: "Authorization")
        }
        pendingFilename = f
        status = .downloading(progress: 0, received: 0, total: 0)
        let task = session.downloadTask(with: request)
        downloadTask = task
        task.resume()
    }

    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        refresh()
    }

    // MARK: Import from Files

    func importModel(from sourceURL: URL) {
        status = .importing
        let needsScope = sourceURL.startAccessingSecurityScopedResource()
        Task.detached { [weak self] in
            defer { if needsScope { sourceURL.stopAccessingSecurityScopedResource() } }
            do {
                let dir = ModelManager.modelsDirectory
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                let dest = dir.appendingPathComponent(sourceURL.lastPathComponent)
                if FileManager.default.fileExists(atPath: dest.path) {
                    try FileManager.default.removeItem(at: dest)
                }
                try FileManager.default.copyItem(at: sourceURL, to: dest)
                let size = (try? FileManager.default.attributesOfItem(atPath: dest.path)[.size] as? NSNumber)?.int64Value ?? 0
                await MainActor.run { self?.status = .installed(sizeBytes: size) }
            } catch {
                await MainActor.run { self?.status = .failed("Import failed: \(error.localizedDescription)") }
            }
        }
    }

    // MARK: Delete

    func deleteModel() {
        if let path = GemmaModel.installedModelPath() {
            try? FileManager.default.removeItem(atPath: path)
        }
        refresh()
    }

    // MARK: URLSessionDownloadDelegate (nonisolated — hop to main for state)

    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                                didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                                totalBytesExpectedToWrite: Int64) {
        let progress = totalBytesExpectedToWrite > 0
            ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) : 0
        Task { @MainActor [weak self] in
            self?.status = .downloading(progress: progress, received: totalBytesWritten, total: totalBytesExpectedToWrite)
        }
    }

    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                                didFinishDownloadingTo location: URL) {
        // HF returns an error PAGE (HTML/JSON) with a non-2xx status if the token is
        // missing/invalid or the license isn't accepted — guard against saving that.
        let statusCode = (downloadTask.response as? HTTPURLResponse)?.statusCode ?? 0
        let suggested = downloadTask.response?.suggestedFilename
        guard (200..<300).contains(statusCode) else {
            Task { @MainActor [weak self] in
                self?.status = .failed("Download failed (HTTP \(statusCode)). Check your token and that you've accepted the model license.")
            }
            return
        }
        let dir = ModelManager.modelsDirectory
        let name = pendingFilename.isEmpty ? (suggested ?? "model.litertlm") : pendingFilename
        let dest = dir.appendingPathComponent(name)
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: dest.path) {
                try FileManager.default.removeItem(at: dest)
            }
            try FileManager.default.moveItem(at: location, to: dest)
            let size = (try? FileManager.default.attributesOfItem(atPath: dest.path)[.size] as? NSNumber)?.int64Value ?? 0
            Task { @MainActor [weak self] in self?.status = .installed(sizeBytes: size) }
        } catch {
            Task { @MainActor [weak self] in self?.status = .failed("Couldn't save model: \(error.localizedDescription)") }
        }
    }

    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error else { return }
        if (error as NSError).code == NSURLErrorCancelled { return }
        Task { @MainActor [weak self] in self?.status = .failed(error.localizedDescription) }
    }

    private enum Keys {
        static let repo = "ember.model.repo"
        static let filename = "ember.model.filename"
        static let revision = "ember.model.revision"
    }
}
