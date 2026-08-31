# FastPix iOS Uploads — UIKit example

A minimal **UIKit** app that chunk-uploads a video to FastPix from a
**signed upload URL** you paste in, with live progress and pause / resume / abort.

## Requirements

- Xcode 15+
- iOS 14+ simulator or device
- A signed upload URL from the
  [Direct Upload API](https://docs.fastpix.io/docs/upload-videos-directly)

## Run it

1. **Open the project:**

   ```bash
   open examples/uikit/UploadExample.xcodeproj
   ```

   On first open, Xcode fetches the `fp-swift-upload-sdk` package — wait for it
   to finish (or **File → Packages → Resolve Package Versions**).

2. Pick the **UploadExample** scheme + a simulator (or your device, with a
   signing team set under **Signing & Capabilities**), then **⌘R**.

3. Paste a signed upload URL, tap **Choose Video…**, then **Start Upload**.
   Watch progress and the event log; use **Pause / Resume / Abort**.

## How the integration works

```swift
import fp_swift_upload_sdk

let uploader = Uploads()
uploader.delegate = self          // UploadsDelegate — progress + lifecycle events

// Start a chunked upload (chunkSizeKB optional, defaults to 16 MB).
uploader.uploadFile(file: localVideoURL, endpoint: signedUploadURL)

uploader.pause(); uploader.resume(); uploader.abort()
```

```swift
func uploads(_ uploads: Uploads, didEmit event: UploadEvent) {
    switch event {
    case .progress(let fraction):            print("\(Int(fraction * 100))%")
    case .uploadsuccess:                      print("done 🎉")
    case .error(let error):                   print("failed: \(error)")
    default:                                  break
    }
}
```

## Troubleshooting

- **Package won't resolve / "couldn't resolve fp-swift-upload-sdk"** —
  **File → Packages → Reset Package Caches**, then **Resolve Package Versions**
  (needs internet; it fetches from GitHub).
- **"Failed to install" on a device** — **Product → Clean Build Folder (⇧⌘K)**,
  run again, and trust the developer profile under **Settings → General →
  VPN & Device Management**.
- **Upload fails immediately** — the signed URL is likely expired or malformed;
  generate a fresh one.
