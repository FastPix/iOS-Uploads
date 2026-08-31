import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var manager: UploadManager
    @State private var pickerItem: PhotosPickerItem?
    @State private var pickError: String?

    var body: some View {
        NavigationView {
            Form {
                Section("Video") {
                    PhotosPicker(selection: $pickerItem, matching: .videos) {
                        Label(manager.fileName.isEmpty ? "Choose Video…" : manager.fileName,
                              systemImage: "film")
                    }
                    .disabled(manager.isActive)
                    if let pickError {
                        Text(pickError).foregroundColor(.red).font(.footnote)
                    }
                }

                Section("Progress") {
                    ProgressView(value: manager.progress)
                    HStack {
                        Text(manager.phase.rawValue)
                        Spacer()
                        Text("\(Int(manager.progress * 100))%").monospacedDigit()
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                    HStack {
                        Button("Pause") { manager.pause() }.disabled(!manager.canPause)
                        Spacer()
                        Button("Resume") { manager.resume() }.disabled(!manager.canResume)
                        Spacer()
                        Button("Cancel", role: .destructive) { manager.cancel() }
                            .disabled(!manager.isActive)
                    }
                    .buttonStyle(.bordered)
                }

                if !manager.log.isEmpty {
                    Section("Event Log") {
                        ForEach(Array(manager.log.enumerated()), id: \.offset) { _, line in
                            Text(line).font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("FastPix Upload")
        }
        .navigationViewStyle(.stack)
        .onChange(of: pickerItem) { newItem in
            guard let newItem else { return }
            Task { await load(newItem) }
        }
    }

    private func load(_ item: PhotosPickerItem) async {
        pickError = nil
        do {
            // Copies the picked video into our temp dir; the SDK reads it from there.
            guard let movie = try await item.loadTransferable(type: Movie.self) else {
                pickError = "Couldn't load that video."
                return
            }
            manager.start(fileURL: movie.url)
        } catch {
            pickError = "Couldn't load the video: \(error.localizedDescription)"
        }
    }
}

// Transferable that lands the picked video as a file URL in our temp dir.
struct Movie: Transferable {
    let url: URL
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let dest = FileManager.default.temporaryDirectory
                .appendingPathComponent(received.file.lastPathComponent)
            try? FileManager.default.removeItem(at: dest)
            try FileManager.default.copyItem(at: received.file, to: dest)
            return Movie(url: dest)
        }
    }
}
