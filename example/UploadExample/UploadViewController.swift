import UIKit
import PhotosUI
import UniformTypeIdentifiers
import fp_swift_upload_sdk

/// Shared brand styling for the demo app.
enum Theme {
    static let accent = UIColor(red: 0.235, green: 0.353, blue: 0.937, alpha: 1)
    static let accentDark = UIColor(red: 0.145, green: 0.204, blue: 0.639, alpha: 1)
}

/// Demonstrates the FastPix iOS Uploads SDK: paste a signed upload URL, pick a
/// video from the library, then chunk-upload it with live progress and the full
/// pause / resume / abort lifecycle.
final class UploadViewController: UIViewController {

    // MARK: SDK

    private let uploader = Uploads()
    private var selectedFileURL: URL?

    // MARK: UI

    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    private let urlField = UITextView()
    private let fileLabel = UILabel()
    private let pickButton = UIButton(type: .system)
    private let uploadButton = UIButton(type: .system)
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let percentLabel = UILabel()
    private let statusLabel = UILabel()
    private let pauseButton = UIButton(type: .system)
    private let resumeButton = UIButton(type: .system)
    private let abortButton = UIButton(type: .system)
    private let logView = UITextView()

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "FastPix Upload"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemGroupedBackground

        uploader.delegate = self
        uploader.progressDelegate = self
        uploader.errorDelegate = self

        buildLayout()
        updateControlState()
    }

    // MARK: Layout

    private func buildLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)

        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])

        stack.addArrangedSubview(makeUrlCard())
        stack.addArrangedSubview(makeFileCard())
        stack.addArrangedSubview(makeUploadButton())
        stack.addArrangedSubview(makeProgressCard())
        stack.addArrangedSubview(makeControlsRow())
        stack.addArrangedSubview(makeLogCard())
    }

    private func makeCard(title: String) -> (card: UIView, body: UIStackView) {
        let card = UIView()
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 16
        card.layer.cornerCurve = .continuous
        card.translatesAutoresizingMaskIntoConstraints = false

        let header = UILabel()
        header.text = title
        header.font = .systemFont(ofSize: 13, weight: .semibold)
        header.textColor = .secondaryLabel

        let body = UIStackView()
        body.axis = .vertical
        body.spacing = 10

        let outer = UIStackView(arrangedSubviews: [header, body])
        outer.axis = .vertical
        outer.spacing = 10
        outer.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(outer)
        NSLayoutConstraint.activate([
            outer.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            outer.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            outer.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            outer.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        return (card, body)
    }

    private func makeUrlCard() -> UIView {
        let (card, body) = makeCard(title: "1 · SIGNED UPLOAD URL")

        urlField.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        urlField.text = ""
        urlField.isScrollEnabled = false
        urlField.backgroundColor = .tertiarySystemGroupedBackground
        urlField.layer.cornerRadius = 10
        urlField.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        urlField.autocapitalizationType = .none
        urlField.autocorrectionType = .no
        urlField.delegate = self
        urlField.heightAnchor.constraint(greaterThanOrEqualToConstant: 74).isActive = true

        let hint = UILabel()
        hint.text = "Paste the signed PUT URL from FastPix's Direct Upload API."
        hint.font = .preferredFont(forTextStyle: .footnote)
        hint.textColor = .secondaryLabel
        hint.numberOfLines = 0

        body.addArrangedSubview(urlField)
        body.addArrangedSubview(hint)
        return card
    }

    private func makeFileCard() -> UIView {
        let (card, body) = makeCard(title: "2 · VIDEO FILE")

        pickButton.setTitle("Choose Video…", for: .normal)
        pickButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        pickButton.tintColor = Theme.accent
        pickButton.contentHorizontalAlignment = .leading
        pickButton.addTarget(self, action: #selector(pickVideo), for: .touchUpInside)

        fileLabel.text = "No file selected"
        fileLabel.font = .preferredFont(forTextStyle: .footnote)
        fileLabel.textColor = .secondaryLabel
        fileLabel.numberOfLines = 0

        body.addArrangedSubview(pickButton)
        body.addArrangedSubview(fileLabel)
        return card
    }

    private func makeUploadButton() -> UIView {
        uploadButton.setTitle("Start Upload", for: .normal)
        uploadButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        uploadButton.setTitleColor(.white, for: .normal)
        uploadButton.backgroundColor = Theme.accent
        uploadButton.layer.cornerRadius = 14
        uploadButton.layer.cornerCurve = .continuous
        uploadButton.addTarget(self, action: #selector(startUpload), for: .touchUpInside)
        uploadButton.heightAnchor.constraint(equalToConstant: 52).isActive = true
        return uploadButton
    }

    private func makeProgressCard() -> UIView {
        let (card, body) = makeCard(title: "PROGRESS")

        progressView.progressTintColor = Theme.accent
        progressView.trackTintColor = .tertiarySystemGroupedBackground
        progressView.progress = 0

        percentLabel.text = "0%"
        percentLabel.font = .systemFont(ofSize: 28, weight: .bold)
        percentLabel.textColor = .label

        statusLabel.text = "Idle"
        statusLabel.font = .preferredFont(forTextStyle: .footnote)
        statusLabel.textColor = .secondaryLabel
        statusLabel.numberOfLines = 0

        body.addArrangedSubview(percentLabel)
        body.addArrangedSubview(progressView)
        body.addArrangedSubview(statusLabel)
        return card
    }

    private func makeControlsRow() -> UIView {
        for (button, title) in [(pauseButton, "Pause"), (resumeButton, "Resume"), (abortButton, "Abort")] {
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
            button.backgroundColor = .secondarySystemGroupedBackground
            button.layer.cornerRadius = 12
            button.heightAnchor.constraint(equalToConstant: 46).isActive = true
        }
        pauseButton.tintColor = Theme.accent
        resumeButton.tintColor = Theme.accent
        abortButton.tintColor = .systemRed
        pauseButton.addTarget(self, action: #selector(pauseUpload), for: .touchUpInside)
        resumeButton.addTarget(self, action: #selector(resumeUpload), for: .touchUpInside)
        abortButton.addTarget(self, action: #selector(abortUpload), for: .touchUpInside)

        let row = UIStackView(arrangedSubviews: [pauseButton, resumeButton, abortButton])
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.spacing = 10
        return row
    }

    private func makeLogCard() -> UIView {
        let (card, body) = makeCard(title: "EVENT LOG")
        logView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        logView.isEditable = false
        logView.isScrollEnabled = true
        logView.backgroundColor = .clear
        logView.textColor = .label
        logView.text = "—"
        logView.heightAnchor.constraint(equalToConstant: 150).isActive = true
        body.addArrangedSubview(logView)
        return card
    }

    // MARK: Actions

    @objc private func pickVideo() {
        var config = PHPickerConfiguration()
        config.filter = .videos
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func startUpload() {
        view.endEditing(true)
        guard let endpoint = urlField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !endpoint.isEmpty else {
            log("⚠️ Paste a signed upload URL first.")
            return
        }
        guard let file = selectedFileURL else {
            log("⚠️ Choose a video first.")
            return
        }
        progressView.setProgress(0, animated: false)
        percentLabel.text = "0%"
        statusLabel.text = "Starting upload…"
        log("▶︎ uploadFile(endpoint: …\(endpoint.suffix(24)))")

        // chunkSizeKB is optional — omit to use the SDK default of 16 MB.
        uploader.uploadFile(file: file, endpoint: endpoint)
    }

    @objc private func pauseUpload()  { uploader.pause();  log("⏸ pause() called") }
    @objc private func resumeUpload() { uploader.resume(); log("⏵ resume() called") }
    @objc private func abortUpload()  { uploader.abort();  log("⏹ abort() called") }

    // MARK: Helpers

    private func log(_ message: String) {
        let stamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let line = "[\(stamp)] \(message)\n"
        if logView.text == "—" { logView.text = "" }
        logView.text += line
        let bottom = NSRange(location: logView.text.count, length: 0)
        logView.scrollRangeToVisible(bottom)
    }

    private func updateControlState() {
        let hasFile = selectedFileURL != nil
        let hasURL = !(urlField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        uploadButton.isEnabled = hasFile && hasURL
        uploadButton.alpha = uploadButton.isEnabled ? 1 : 0.5
    }
}

// MARK: - PHPickerViewControllerDelegate

extension UploadViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider else { return }
        let movieType = UTType.movie.identifier
        guard provider.hasItemConformingToTypeIdentifier(movieType) else {
            log("⚠️ Selected item is not a movie file.")
            return
        }
        log("Loading selected video…")
        provider.loadFileRepresentation(forTypeIdentifier: movieType) { [weak self] url, error in
            guard let self = self else { return }
            if let error = error {
                DispatchQueue.main.async { self.log("⚠️ Load failed: \(error.localizedDescription)") }
                return
            }
            guard let url = url else { return }
            // The provided URL is temporary; copy it somewhere stable to upload from.
            let dest = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(url.pathExtension.isEmpty ? "mov" : url.pathExtension)
            do {
                try? FileManager.default.removeItem(at: dest)
                try FileManager.default.copyItem(at: url, to: dest)
                let size = (try? FileManager.default.attributesOfItem(atPath: dest.path)[.size] as? Int) ?? 0
                DispatchQueue.main.async {
                    self.selectedFileURL = dest
                    let mb = Double(size ?? 0) / 1_048_576
                    self.fileLabel.text = "\(dest.lastPathComponent)  ·  \(String(format: "%.1f", mb)) MB"
                    self.fileLabel.textColor = .label
                    self.log("Selected \(dest.lastPathComponent) (\(String(format: "%.1f", mb)) MB)")
                    self.updateControlState()
                }
            } catch {
                DispatchQueue.main.async { self.log("⚠️ Copy failed: \(error.localizedDescription)") }
            }
        }
    }
}

// MARK: - UITextViewDelegate

extension UploadViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) { updateControlState() }
}

// MARK: - Uploads SDK delegates

extension UploadViewController: UploadsDelegate, UploadProgressDelegate, UploadSDKErrorDelegate {

    func uploads(_ uploads: Uploads, didEmit event: UploadEvent) {
        switch event {
        case .chunkAttempt(let n, let total):
            statusLabel.text = "Uploading chunk \(n) of \(total)…"
            log("chunkAttempt \(n)/\(total)")
        case .chunkSuccess(let n, let total):
            log("✓ chunkSuccess \(n)/\(total)")
        case .progress(let p):
            setProgress(p)
        case .uploadsuccess:
            setProgress(1)
            statusLabel.text = "Upload complete 🎉"
            log("✅ uploadsuccess")
        case .pause:
            statusLabel.text = "Paused"; log("event: pause")
        case .resume:
            statusLabel.text = "Resumed"; log("event: resume")
        case .online:
            log("🌐 back online")
        case .offline:
            statusLabel.text = "Offline — waiting for network…"; log("📴 offline")
        case .chunkAttemptFailure(let n, let total, let error, let attempt):
            log("⚠️ chunk \(n)/\(total) failed (attempt \(attempt)): \(error.localizedDescription)")
        case .error(let error):
            statusLabel.text = "Error"
            log("❌ error: \(error.localizedDescription)")
        @unknown default:
            break
        }
    }

    func didUpdateProgressText(_ text: String) {
        statusLabel.text = text.trimmingCharacters(in: .whitespaces)
    }

    func uploadSDKDidFail(with error: String) {
        log("❌ SDK error: \(error)")
    }

    private func setProgress(_ p: Float) {
        progressView.setProgress(p, animated: true)
        percentLabel.text = "\(Int((p * 100).rounded()))%"
    }
}
