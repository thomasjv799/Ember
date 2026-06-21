import Foundation

// ─────────────────────────────────────────────────────────────
// SpeechTranscribing — voice capture + on-device transcription
// behind a protocol. MockSpeechProvider returns a canned line
// (default / simulator); SpeechProvider uses AVAudioEngine +
// SFSpeechRecognizer with on-device recognition.
// ─────────────────────────────────────────────────────────────
protocol SpeechTranscribing: AnyObject {
    var isAvailable: Bool { get }
    func requestAuthorization() async -> Bool
    func startRecording() throws
    func stopRecording() async -> String
}

// MARK: - Mock

final class MockSpeechProvider: SpeechTranscribing {
    var isAvailable: Bool { true }
    func requestAuthorization() async -> Bool { true }
    func startRecording() throws {}
    func stopRecording() async -> String { "How's my recovery looking after this week?" }
}

// MARK: - Real (Speech framework)

#if canImport(Speech) && canImport(AVFoundation)
import Speech
import AVFoundation

final class SpeechProvider: SpeechTranscribing {
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var transcript = ""

    var isAvailable: Bool { recognizer?.isAvailable ?? false }

    func requestAuthorization() async -> Bool {
        let speechOK = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        let micOK = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        return speechOK && micOK
    }

    func startRecording() throws {
        transcript = ""

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if recognizer?.supportsOnDeviceRecognition == true {
            request.requiresOnDeviceRecognition = true
        }
        self.request = request

        let input = engine.inputNode
        task = recognizer?.recognitionTask(with: request) { [weak self] result, _ in
            if let result { self?.transcript = result.bestTranscription.formattedString }
        }

        let format = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }
        engine.prepare()
        try engine.start()
    }

    func stopRecording() async -> String {
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.finish()
        // Brief settle so the recognizer can emit its final result.
        try? await Task.sleep(nanoseconds: 250_000_000)
        request = nil
        task = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        return transcript
    }
}
#endif
