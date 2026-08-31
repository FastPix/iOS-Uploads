import Foundation
import UIKit
import fp_swift_upload_sdk

// Bridges the SDK's delegate callbacks into @Published state that SwiftUI observes.
// Also holds a UIApplication background-task assertion so an in-flight upload keeps
// running for the short window iOS grants after the app is backgrounded.
//
// ponytail: beginBackgroundTask ceiling ~30s–few min; large uploads still suspend.
// True background continuation needs a background URLSession, which lives in the SDK
// (URLSessionConfiguration.default) — out of scope here (examples don't modify the SDK).
@MainActor
final class UploadManager: NSObject, ObservableObject {

    enum Phase: String {
        case idle = "Idle"
        case preparing = "Preparing…"
        case uploading = "Uploading"
        case paused = "Paused"
        case completed = "Completed 🎉"
        case failed = "Failed"
        case cancelled = "Cancelled"
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var progress: Double = 0        // 0…1
    @Published private(set) var fileName = ""
    @Published private(set) var log: [String] = []

    var isActive: Bool { phase == .preparing || phase == .uploading || phase == .paused }
    var canPause: Bool { phase == .uploading }
    var canResume: Bool { phase == .paused }

    private let uploader = Uploads()
    private var bgTask: UIBackgroundTaskIdentifier = .invalid

    override init() {
        super.init()
        uploader.delegate = self
        uploader.progressDelegate = self
        uploader.errorDelegate = self
    }

    // MARK: - Actions

    func start(fileURL: URL) {
        guard !isActive else { return }
        fileName = fileURL.lastPathComponent
        progress = 0
        log = []
        phase = .preparing
        beginBackgroundTask()
        append("Requesting signed upload URL…")

        Task {
            do {
                let signed = try await FastPixAPI.createUpload()
                append("Got signed URL. Starting upload of \(fileName).")
                phase = .uploading
                uploader.uploadFile(file: fileURL, endpoint: signed.url)
            } catch {
                fail(error.localizedDescription)
            }
        }
    }

    func pause()  { if canPause { uploader.pause() } }
    func resume() { if canResume { uploader.resume() } }
    func cancel() {
        guard isActive else { return }
        uploader.abort()
        phase = .cancelled
        endBackgroundTask()
    }

    // MARK: - Helpers

    private func append(_ line: String) { log.append(line) }

    private func fail(_ message: String) {
        append("Error: \(message)")
        phase = .failed
        endBackgroundTask()
    }

    private func succeed() {
        progress = 1
        append("Upload complete.")
        phase = .completed
        endBackgroundTask()
    }

    private func beginBackgroundTask() {
        endBackgroundTask()
        bgTask = UIApplication.shared.beginBackgroundTask(withName: "FastPixUpload") { [weak self] in
            // iOS is about to reclaim the time it granted us.
            self?.endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        guard bgTask != .invalid else { return }
        UIApplication.shared.endBackgroundTask(bgTask)
        bgTask = .invalid
    }
}

// MARK: - SDK delegates

extension UploadManager: UploadsDelegate, UploadProgressDelegate, UploadSDKErrorDelegate {

    nonisolated func uploads(_ uploads: Uploads, didEmit event: UploadEvent) {
        // SDK emits on the main thread already; hop to the actor for @Published safety.
        Task { @MainActor in
            switch event {
            case .progress(let p):
                self.progress = Double(p)
                if self.phase == .uploading, p >= 0.999 {
                    // The SDK only fires .uploadsuccess for single-chunk uploads;
                    // treat full progress as done so multi-chunk uploads finish too.
                    self.succeed()
                }
            case .uploadsuccess:
                self.succeed()
            case .pause:
                self.phase = .paused
            case .resume:
                self.phase = .uploading
            case .chunkSuccess(let n, let total):
                self.append("Chunk \(n)/\(total) uploaded.")
            case .offline:
                self.append("Network offline — waiting…")
            case .online:
                self.append("Network back online.")
            case .chunkAttemptFailure(let n, let total, _, let attempt):
                self.append("Chunk \(n)/\(total) retry (attempt \(attempt))…")
            case .error(let error):
                self.fail(error.localizedDescription)
            case .chunkAttempt:
                break
            }
        }
    }

    nonisolated func didUpdateProgressText(_ text: String) {}

    nonisolated func uploadSDKDidFail(with error: String) {
        // The SDK reports both hard failures and transient status text here
        // (e.g. "Network is Online"); log it without forcing a failed state.
        Task { @MainActor in self.append(error) }
    }
}
