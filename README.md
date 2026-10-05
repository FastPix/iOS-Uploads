# FastPix iOS Uploads SDK - resumable, chunked file uploads for iOS (Swift)

[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-brightgreen?logo=swift)](https://swift.org/package-manager/)
[![Swift](https://img.shields.io/badge/Swift-5.9-F05138?logo=swift&logoColor=white)](https://swift.org)
[![Platform: iOS](https://img.shields.io/badge/platform-iOS-000000?logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Latest release](https://img.shields.io/github/v/release/FastPix/iOS-Uploads?sort=semver)](https://github.com/FastPix/iOS-Uploads/releases)
[![license](https://img.shields.io/github/license/FastPix/iOS-Uploads)](https://github.com/FastPix/iOS-Uploads/blob/main/LICENSE)

This SDK simplifies uploading large files in iOS applications by breaking them into smaller chunks and uploading each chunk individually. Developed in Swift, it is available exclusively as a Swift package.

This SDK is designed specifically for use with FastPix and is not suitable for general-purpose file upload use cases.

**Works with:** iOS · Swift 5.9 · Swift Package Manager · pause / resume / retry · signed upload URLs

📖 **Docs:** https://fastpix.com/docs/upload-videos/set-up-resumable-uploads-for-ios &nbsp;·&nbsp; 🚀 **Dashboard:** https://dashboard.fastpix.com

## Features

- **Chunking:** Files are automatically split into chunks (configurable, default size is 16MB/chunk).
- **Pause and Resume:** Allows temporarily pausing the upload and resuming after a while.
- **Upload Lifecycle Callbacks:** Track the entire upload process using callback functions to monitor uploads lifecycle.
- **Retry**:  Uploads might fail due to temporary network failures. Individual chunks are retried for 5 times with exponential backoff to recover automatically from such failures.
- **Error Handling**: Comprehensive error management to notify users of issues during uploads.
- **Customizability**: Options to customize chunk size and retry attempts.

## Start here

If you are using the FastPix iOS Uploads SDK for the first time, follow these steps in order:

1. [Install the SDK](#install-the-sdk)
2. [Get a signed upload URL](#get-a-signed-upload-url)
3. [Import and upload a file](#import-and-upload-a-file)
4. [Manage the upload](#manage-the-upload)
5. [Track upload progress](#track-upload-progress)
6. [Understand the upload workflow](#understand-the-upload-workflow)

Do not skip the verification steps. If an install, credential, or signed-URL problem occurs, fix it before continuing.

---

### Before you begin

To use the SDK, make sure you have:

- **Xcode** and an iOS app project.
- A **FastPix account**, with an Access Token and a Secret Key.
- A **backend** (or serverless function) that can create a signed upload URL - your credentials must never ship in the app.
- A **local file** to upload (a file `URL` from a document or photo picker).

FastPix uploads use a **signed URL**: you create a short-lived upload URL on your server, then pass only that URL to the SDK as the `endpoint`. See [Get a signed upload URL](#get-a-signed-upload-url).

---

## Install the SDK

Install with **Swift Package Manager**. In Xcode, choose **File → Add Package Dependencies…**, then paste the repository URL into the search field:

```
https://github.com/FastPix/iOS-Uploads.git
```

Choose the latest version and add the `fp-swift-upload-sdk` library to your app target. For a step-by-step walkthrough, see Apple's [Adding package dependencies to your app](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app).

## Get a signed upload URL

The SDK uploads to a **signed URL**, so your Access Token and Secret Key stay on your backend and never ship in the app.

1. Get your **Access Token** and **Secret Key** - see the [Basic Authentication Guide](https://fastpix.com/docs/getting-started/activate-your-account#authentication-format).
2. From your backend, call the [Upload media from device](https://fastpix.com/docs/video-on-demand-api/upload-and-import-videos/direct-upload-video-media) API to generate a signed upload URL.
3. Return only that URL to the app, and pass it to the SDK as the `endpoint`.

> **Security:** Never embed your Access Token or Secret Key in the app. Create signed URLs on your server.

## Import and upload a file

Import the SDK, create an `Uploads` instance, and call `uploadFile` with your local file `URL` and the signed `endpoint`. Here `createDirectUpload()` is your own backend call that returns a signed URL.

**Import**

```swift
import fp_swift_upload_sdk
```

**Integration**

```swift
import fp_swift_upload_sdk  

var uploader = Uploads() 

Task { 
  let createUploadURL = try await self.myServerBackend.createDirectUpload()                           
  uploader.uploadFile(file: file!, endpoint: createUploadURL.absoluteString, chunkSizeKB: Int(chunkSize.text ?? "") ?? 0)  
 } 
```

See [Parameters](#parameters) for chunk size, retry, and file-size options.

## Manage the upload

Easily control the lifecycle of your uploads with the following methods:

- **Pause an Upload:**

  ```swift
  uploader.pause(); // Pauses the current upload
  ```

- **Resume an Upload:**

  ```swift
  uploader.resume(); // Resume the current upload
  ```

- **Abort an Upload:**

  ```swift
  uploader.abort(); // Abort the current upload
  ```

## Track upload progress

The SDK reports the full upload lifecycle through a delegate and a progress closure.

- **Progress closure** - assign `uploader.progressHandler = { progress in ... }` to receive the upload progress (a `Float` from 0 to 1).
- **Delegate** - set `uploader.delegate` to an object conforming to `UploadsDelegate`. It receives one callback, `uploads(_:didEmit:)`, with an `UploadEvent` describing what happened:

| `UploadEvent` case | Fires when |
|---|---|
| `progress(progress:)` | Upload progress updates. |
| `chunkAttempt(chunkNumber:totalChunks:)` | A chunk upload is attempted. |
| `chunkSuccess(chunkNumber:totalChunks:)` | A chunk finishes successfully. |
| `chunkAttemptFailure(chunkNumber:totalChunks:error:attempt:)` | A chunk attempt fails and will be retried. |
| `uploadsuccess` | The whole upload completes. |
| `error(error:)` | The upload fails. |
| `pause` / `resume` | The upload is paused or resumed. |
| `online` / `offline` | Network connectivity changes. |

For complete, working delegate and progress code, see the [example apps](#example-apps).

## Understand the upload workflow

Your backend creates a signed upload URL; the SDK splits the file into chunks and uploads them to that URL with automatic retry, reporting progress along the way and emitting `uploadsuccess` when the upload finishes. Processing and playback happen afterward in your app.

![FastPix iOS upload workflow: your backend creates a signed upload URL, the Uploads SDK splits the file into chunks and uploads them to FastPix with retry, reports progress, and emits uploadsuccess; your app then plays the processed media.](https://static.fastpix.com/ios-upload-workflow.png)

## Parameters

`uploadFile(file:endpoint:chunkSizeKB:maxRetryAttempt:maxFileBytesKB:)` accepts the following parameters:

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `file` | `URL` | Required | Local file URL to upload (for example, from a document or photo picker). |
| `endpoint` | `String` | Required | The signed FastPix upload URL, created on your backend. |
| `chunkSizeKB` | `Int?` | Optional | Size of each chunk in KB. Default is `16384` KB (16 MB). **Minimum:** 5120 KB (5 MB), **Maximum:** 512000 KB (500 MB). |
| `maxRetryAttempt` | `Int?` | Optional | Number of retry attempts per chunk on failure. Default is `5`. |
| `maxFileBytesKB` | `Int?` | Optional | Maximum allowed file size in KB. Files larger than this are rejected. |

## Example apps

The repository includes two complete, runnable example apps under [`examples/`](examples) - copy one and run it:

- **UIKit** - [`examples/uikit`](examples/uikit): pick a file from Files, paste a signed URL, and upload with live progress and pause / resume / cancel.
- **SwiftUI** - [`examples/swiftui`](examples/swiftui): pick from Photos, mints the upload URL in-app, and does a best-effort background upload.

## FAQ

**What do I install, and how?**
Add the Swift package `https://github.com/FastPix/iOS-Uploads.git` in Xcode, then `import fp_swift_upload_sdk`. See [Install the SDK](#install-the-sdk).

**Where does the upload URL come from?**
You create a signed upload URL on your backend with the FastPix Direct Upload API and pass it to `uploadFile` as the `endpoint`. See [Get a signed upload URL](#get-a-signed-upload-url).

**What chunk sizes are allowed?**
5 MB to 500 MB (`chunkSizeKB` from 5120 to 512000). Default is 16 MB (16384 KB). See [Parameters](#parameters).

**Can I pause and resume an upload?**
Yes - `uploader.pause()`, `uploader.resume()`, and `uploader.abort()`. See [Manage the upload](#manage-the-upload).

**How do I show upload progress?**
Assign `uploader.progressHandler`, or set `uploader.delegate` to receive `UploadEvent`s. See [Track upload progress](#track-upload-progress).

**How are failures handled?**
Each chunk is retried up to `maxRetryAttempt` times (default 5) with exponential backoff. See [Parameters](#parameters).

**Is there a runnable example?**
Yes - a UIKit and a SwiftUI example. See [Example apps](#example-apps).

## Which FastPix repo do I need?

This SDK uploads from a native iOS app. For other platforms and playback:

| I want to... | Repo |
|---|---|
| Add resumable uploads in a React Native app | [react-native-uploader](https://github.com/FastPix/react-native-uploader) |
| Add resumable uploads in the browser / any web app | [web-uploads-sdk](https://github.com/FastPix/web-uploads-sdk) |
| Generate signed upload URLs from a Node backend | [node-sdk](https://github.com/FastPix/node-sdk) |
| Play FastPix video in an iOS app | [iOS-player](https://github.com/FastPix/iOS-player) |
| Add playback analytics for AVPlayer (iOS / tvOS) | [iOS-data-avplayer-sdk](https://github.com/FastPix/iOS-data-avplayer-sdk) |

Browse everything in the [FastPix organization](https://github.com/orgs/FastPix/repositories).

## References

- [Homepage](https://www.fastpix.com/)
- [Dashboard](https://dashboard.fastpix.com)
- [GitHub](https://github.com/FastPix/iOS-Uploads.git)
- [API Reference](https://fastpix.com/docs/video-on-demand-api/upload-and-import-videos/direct-upload-video-media)

## Detailed Usage
 
For more detailed steps and advanced usage, please refer to the official [FastPix Documentation](https://fastpix.com/docs/upload-videos/upload-videos-from-device#uploading-large-media-files).
## License

This SDK is released under the MIT License - see the [LICENSE](LICENSE) file for details.
