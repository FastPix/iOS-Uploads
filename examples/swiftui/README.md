# FastPix iOS Uploads — SwiftUI example

A minimal **SwiftUI** app that mints a signed upload URL in-app, picks a video
from Photos, and chunk-uploads it with live progress and pause / resume / cancel.
Upload state is driven by an `ObservableObject` (`UploadManager`).

## Requirements

- Xcode 15+
- iOS 16+ simulator or device (uses `PhotosPicker`)
- A FastPix **token + secret key** (Dashboard → Settings → Access Tokens)

## Run it

1. **Add your credentials** — copy the template and paste your keys:

   ```bash
   cd examples/swiftui/SwiftUIUploadExample
   cp Secrets.example.swift Secrets.swift   # Secrets.swift is gitignored
   ```

2. **Open the project:**

   ```bash
   open examples/swiftui/SwiftUIUploadExample.xcodeproj
   ```

   On first open, Xcode fetches the `fp-swift-upload-sdk` package — wait for it
   to finish (or **File → Packages → Resolve Package Versions**).

3. Pick the **SwiftUIUploadExample** scheme + a simulator (or your device, with a
   signing team set under **Signing & Capabilities**), then **⌘R**.

4. Tap **Choose Video…**, pick a clip. The app calls create-upload, then uploads.
   Watch progress and the event log; use **Pause / Resume / Cancel**.

## How the integration works

```swift
import fp_swift_upload_sdk

let uploader = Uploads()
uploader.delegate = self          // UploadsDelegate — progress + lifecycle events

// Mint a signed URL, then start the chunked upload.
let signed = try await FastPixAPI.createUpload()   // POST /v1/on-demand/upload
uploader.uploadFile(file: fileURL, endpoint: signed.url)

uploader.pause(); uploader.resume(); uploader.abort()
```

## Background uploads

Start an upload, then background the app — it keeps going for the short window
iOS grants (`beginBackgroundTask`), then iOS suspends it. iOS has no
foreground-service equivalent (unlike Android); a large upload that truly
survives suspension needs a background `URLSession`, which is an SDK change.
See [`../BACKGROUND-UPLOADS-SDK-REQUEST.md`](../BACKGROUND-UPLOADS-SDK-REQUEST.md).

## Troubleshooting

- **Package won't resolve / "couldn't resolve fp-swift-upload-sdk"** —
  **File → Packages → Reset Package Caches**, then **Resolve Package Versions**
  (needs internet; it fetches from GitHub).
- **Build error "cannot find 'Secrets' in scope"** — you skipped step 1; create
  `Secrets.swift` from the template.
- **"Set your token/secret in Secrets.swift"** in the event log — `Secrets.swift`
  still has the placeholder values; paste your real token + secret key.
- **"Failed to install" on a device** — **Product → Clean Build Folder (⇧⌘K)**,
  run again, and trust the developer profile under **Settings → General →
  VPN & Device Management**.
