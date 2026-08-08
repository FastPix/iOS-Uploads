# FastPix iOS Uploads — Example App

A minimal iOS (UIKit) app showing how to integrate the
[FastPix iOS Uploads SDK](https://github.com/FastPix/iOS-Uploads) to
chunk-upload a video to FastPix using a **signed upload URL**, with live
progress and the full **pause / resume / abort** lifecycle.

## Requirements

- macOS with **Xcode 15 or later**
- **iOS 14.0+** simulator or device
- A **signed upload URL** from FastPix's
  [Direct Upload API](https://docs.fastpix.io/docs/upload-videos-directly) —
  create one from the [FastPix dashboard](https://dashboard.fastpix.com) or via
  the API
- (Device only) an Apple ID / signing team configured in Xcode

## How to run this app

### 1. Get the project

If you cloned the SDK repo, the example lives in the `example/` folder:

```bash
git clone https://github.com/FastPix/iOS-Uploads.git
cd iOS-Uploads/example
```

### 2. Open it in Xcode

```bash
open UploadExample.xcodeproj
```

Or launch Xcode → **File → Open…** → select `UploadExample.xcodeproj`.

### 3. Let Swift Package Manager resolve dependencies

On first open, Xcode automatically fetches the `fp-swift-upload-sdk` package.
Wait until the progress spinner in the toolbar finishes. If it doesn't start,
choose **File → Packages → Resolve Package Versions**.

### 4. Pick a destination and run

1. In the toolbar's scheme/destination selector, choose the **UploadExample**
   scheme and a target:
   - **Simulator** — e.g. *iPhone 15 Pro* (no signing needed).
   - **Physical device** — select **Signing & Capabilities**, pick your **Team**
     so Xcode provisions the app, then plug in / select the device.
2. Press **⌘R** (or the ▶︎ Run button).

### 5. Upload a video

1. **Paste a signed upload URL** into the first card. Generate one from FastPix's
   Direct Upload API — it's a pre-authorized `PUT` URL the SDK uploads chunks to.
2. Tap **Choose Video…** and pick a clip from the library (no photo-library
   permission prompt — it uses the system `PHPicker`).
3. Tap **Start Upload**. Watch the **Progress** card climb to 100% and the
   **Event Log** stream each chunk. Use **Pause / Resume / Abort** at any time.
4. Confirm the asset appears in your
   [FastPix dashboard](https://dashboard.fastpix.com) once the upload completes.

### Troubleshooting

- **"Failed to install" on a device** — clean with **Product → Clean Build
  Folder (⇧⌘K)** and run again. On the first install, trust the developer
  profile under **Settings → General → VPN & Device Management** on the device.
- **Package resolution errors** — **File → Packages → Reset Package Caches**,
  then resolve again.
- **Upload fails immediately** — the signed URL may be expired or malformed.
  Generate a fresh one and paste the full `PUT` URL.

## App structure

- `UploadViewController` — the single screen: paste URL, pick video, start the
  upload, and observe progress + lifecycle events via the SDK delegates.
- `AppDelegate` / `SceneDelegate` — standard programmatic UIKit bootstrap (no
  storyboards).

## How the integration works

```swift
import fp_swift_upload_sdk

// Keep a strong reference for the whole upload session.
private let uploader = Uploads()

// Observe lifecycle, progress-text, and error callbacks.
uploader.delegate = self          // UploadsDelegate
uploader.progressDelegate = self  // UploadProgressDelegate
uploader.errorDelegate = self     // UploadSDKErrorDelegate

// Start a chunked upload. chunkSizeKB is optional (defaults to 16 MB).
uploader.uploadFile(file: localVideoURL, endpoint: signedUploadURL)

// Control the in-flight upload at any time.
uploader.pause()
uploader.resume()
uploader.abort()
```

Handle events from the `UploadsDelegate`:

```swift
func uploads(_ uploads: Uploads, didEmit event: UploadEvent) {
    switch event {
    case .progress(let fraction):                 // 0.0 … 1.0
        progressView.setProgress(fraction, animated: true)
    case .chunkSuccess(let n, let total):
        print("uploaded chunk \(n)/\(total)")
    case .uploadsuccess:
        print("done 🎉")
    case .error(let error):
        print("failed: \(error.localizedDescription)")
    default:
        break
    }
}
```

See the
[official FastPix documentation](https://docs.fastpix.io/docs/upload-videos-directly)
for creating signed upload URLs and the full SDK API.
