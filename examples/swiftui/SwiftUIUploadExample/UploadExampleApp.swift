import SwiftUI

@main
struct UploadExampleApp: App {
    // One manager for the whole app — it owns the uploader and its state.
    @StateObject private var manager = UploadManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(manager)
        }
    }
}
