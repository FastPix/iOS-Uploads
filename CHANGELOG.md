
# Changelog

All notable changes to this project will be documented in this file.

## [1.0.2]

### Compatibility
- The SDK is now fully compatible with both old and new versions of Xcode (before and after Xcode 26) and Swift (Swift 5.x and Swift 6.x including Swift 6.3.2).
- No functionality has been changed. All fixes are only compatability ones, updates to ensure the SDK builds and runs correctly across all supported Xcode and Swift versions.

### Fixed
- Fixed invalid `try (tuple)` syntax in `uploadFile` that caused a Swift 6.3.2 compiler crash (SILGen segfault) under Xcode 26.
- Fixed `customizedChunkSize` incorrectly storing `0` when `chunkSizeKB: 0` was passed. Both `nil` and `0` now correctly fall back to the SDK default (`16384` KB).
- Fixed chunk size validation thresholds that were written in MB (`< 5`, `> 500`) but compared against a value stored in KB, causing valid chunk sizes and the SDK default to always fail validation.
- Fixed `FileHandle` on iOS 13.0–13.3 silently returning empty `Data` due to a missing availability check. Legacy `seek(toFileOffset:)` and `readData(ofLength:)` are now used as a fallback on iOS < 13.4.
- Fixed missing `fileHandle.closeFile()` fallback in `deinit` for iOS < 13.0.
- Fixed force-unwrap crash on `VideoChunkProcessor(fileURL:)` returning `nil` when the file could not be opened.
- Fixed force-unwrap crash on `currentChunk` in `requestChunk`.
- Fixed `NotificationCenter.addObserver` being called off the main thread when `uploadFile` is invoked from a background thread.

### Changed
- Replaced duplicated chunk-success logic in `submitHttpRequest` with a shared `handleChunkSuccess()` method.
- All closures (`emit`, upload task completion, `asyncAfter`) now capture `self` weakly via `[weak self]` to prevent retain cycles.
- `UploadEvent` associated error values updated from bare `Error` to `any Error` for Swift 5.7+ and Swift 6 compatibility.

### Added
- `Sendable` conformance added to `UploadEvent`, `UploadsDelegate`, `UploadProgressDelegate`, and `UploadSDKErrorDelegate` for Swift 6 strict concurrency compliance.

### Removed
- Removed unstable `() async throws -> String` existential type from `validateUserInput` endpoint check, which is unsupported across Swift versions.
- Removed unused variable `var response = 429` and duplicate `if let httpResponse` rebinding inside `submitHttpRequest`.

## [1.0.1]

### Changed
- **Domain migration: `fastpix.io` → `fastpix.com`**
  - Direct Upload API endpoint updated from `https://api.fastpix.io/v1/on-demand/upload` to `https://api.fastpix.com/v1/on-demand/upload`.
  - README references for dashboard, documentation, and API links updated to use `.com` domains.

> **Note:** Existing `.io` domains will continue functioning temporarily, but migration to `.com` endpoints is strongly recommended to avoid future disruptions.

## [1.0.0]

### Added
- **Chunking**: Files are automatically split into chunks (configurable, default size is 16MB/chunk).
- **Pause and Resume**: Allows temporarily pausing the upload and resuming after a while.
- **Upload Lifecycle Callbacks**: Track the entire upload process using callback functions to monitor upload lifecycle.
- **Retry**: Individual chunks are retried up to 5 times with exponential backoff to recover from temporary network failures.
- **Error Handling**: Comprehensive error management to notify users of issues during uploads.
- **Customizability**: Options to customize chunk size and retry attempts.
- **Swift Package Manager Support**: SDK is installable via SPM using the repo URL.
- Implemented support for Google Cloud Storage resumable uploads and chunked client uploads.
- Added retry mechanism with exponential backoff for GCS upload failures based on retryable status codes.
- Enabled support for user-provided signed URLs for resumable uploads with externally generated session URIs.
- Updated the API endpoint from `https://v1.fastpix.io/on-demand/uploads` to `https://api.fastpix.io/v1/on-demand/upload`.
