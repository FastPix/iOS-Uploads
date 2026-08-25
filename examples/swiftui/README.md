# FastPix iOS Uploads — SwiftUI Example

A minimal **SwiftUI** app that mints a signed upload URL from FastPix, picks a
video, and chunk-uploads it with live progress and **pause / resume / cancel**.
Upload state is driven by an `ObservableObject` (`UploadManager`).

This is separate from the UIKit example in [`../uikit`](../uikit).

## Run it

1. **Add your credentials.** Copy the template and paste a token + secret key
   (Dashboard → Settings → Access Tokens):

   ```bash
   cd examples/swiftui/SwiftUIUploadExample
   cp Secrets.example.swift Secrets.swift   # Secrets.swift is gitignored
   ```

2. **Open and run:**

   ```bash
   open examples/swiftui/SwiftUIUploadExample.xcodeproj
   ```

   Pick the `SwiftUIUploadExample` scheme + a simulator (or your device, with a
   signing team set), then ⌘R. The project references the SDK locally (`../..`),
   so it builds against the code in this repo.

3. Tap **Choose Video…**, pick a clip. The app calls create-upload, then uploads.
   Watch the progress bar and event log; use **Pause / Resume / Cancel**.

## What "background upload" means here

Tap upload, then background the app — it keeps uploading for the short window
iOS grants (`beginBackgroundTask`), typically tens of seconds to a couple of
minutes, then iOS suspends it.

**Why not longer, like the Android example?** Android has a *foreground service*
that keeps your process running while backgrounded. iOS has no equivalent — it
suspends your process within seconds. The only way a large transfer truly
survives suspension is a **background `URLSession`** (`URLSessionConfiguration.background`),
where a system daemon does the transfer. That has to be configured *inside* the
SDK (it currently uses `URLSessionConfiguration.default`), and a background
session can't upload in-memory `Data` chunks the way this SDK does — so it's an
SDK change, out of scope for an example. This app does the honest best-effort:
`beginBackgroundTask` around the active upload.

## Files

- `UploadExampleApp.swift` — `@main` app, owns the `UploadManager`.
- `ContentView.swift` — the screen: pick, progress, pause/resume/cancel, log.
- `UploadManager.swift` — `ObservableObject` bridging SDK delegates → `@Published`
  state; holds the `beginBackgroundTask` assertion.
- `FastPixAPI.swift` — the create-upload POST call.
- `Secrets.swift` — your credentials (gitignored).
