# FastPix iOS Uploads — Examples

Standalone example apps for the [FastPix iOS Uploads SDK](../). Each folder is a
self-contained Xcode project — copy one and run it.

| Example | UI | Picks from | Notes |
|---------|-----|-----------|-------|
| [`uikit/`](uikit) | UIKit | Files (paste a signed URL) | Original example. |
| [`swiftui/`](swiftui) | SwiftUI | Photos | Mints the upload URL in-app; best-effort background upload. |

Both do chunked upload with live progress and pause / resume / cancel.
