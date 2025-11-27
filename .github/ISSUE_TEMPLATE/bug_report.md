---
name: Bug Report
about: Report an issue related to the FastPix iOS Uploads SDK
title: '[BUG] '
labels: bug
assignees: ''
---

## Bug Description
A clear and concise description of the bug or unexpected behavior in the FastPix iOS Uploads SDK.

---

## Reproduction Steps

### 1. **SDK Setup**

Add the FastPix iOS Uploads SDK using Swift Package Manager:

```
https://github.com/FastPix/iOS-Uploads.git
```

Import the library:

```swift
import fp_swift_upload_sdk
```

### 2. **Code To Reproduce**

Provide a minimal reproducible code snippet. Example:

```swift
import fp_swift_upload_sdk

var uploader = Uploads()

Task {
    let createUploadURL = try await myServerBackend.createDirectUpload()
    uploader.uploadFile(
        file: file!,
        endpoint: createUploadURL.absoluteString,
        chunkSizeKB: 16384
    )
}

// Example control methods
uploader.pause()
uploader.resume()
uploader.abort()
```

Replace the above snippet with the exact code where the issue occurs.

---

## Expected Behavior
```
<!-- Describe what you expected to happen, e.g., file uploads successfully, progress updates correctly -->
```

## Actual Behavior
```
<!-- Describe what actually happened, e.g., upload fails, incorrect chunking, error messages -->
```

---

## Environment

- **SDK Version**: [e.g., 1.0.0]
- **iOS Version**: [e.g., iOS 17.2]
- **Device/Simulator**: [e.g., iPhone 14 Pro, Xcode Simulator]
- **Xcode Version**: [e.g., 15.3]
- **Integration Method**: Swift Package Manager (SPM) / Manual
- **Upload File Type**: [Video, Image, Other]

---

## Code Sample
```swift
// Provide a minimal reproducible sample here
```

## Logs / Errors / Stack Trace
```
Paste console logs, crash logs, or SDK error responses here
```

---

## Additional Context
Add any other context that would help us investigate the issue, such as:

- File size
- Network conditions
- Chunk size
- Retry attempts

## Screenshots / Screen Recording
If applicable, attach screenshots or a video showing the problem.
