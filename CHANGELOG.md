
# Changelog

All notable changes to this project will be documented in this file.

## [1.0.1]

### Domain migration: `fastpix.io` → `fastpix.com`

All FastPix-hosted endpoints (`api.fastpix.io`, `dashboard.fastpix.io`, `docs.fastpix.io`, `www.fastpix.io`) are migrating to the `.com` TLD. Existing `.io` hosts continue to serve traffic temporarily for backward compatibility, but they are planned for future deprecation.

- **API endpoint migration**
  - Direct Upload API endpoint updated from:
    - `https://api.fastpix.io/v1/on-demand/upload`
  - To:
    - `https://api.fastpix.com/v1/on-demand/upload`

- **Documentation updates**
  - README references for dashboard, documentation, and API links are being updated to use `.com` domains.

> **Note:** Existing `.io` domains will continue functioning temporarily, but migration to `.com` endpoints is strongly recommended to avoid future disruptions.

## [1.0.0]

### Features
  - **Chunking**: Files are automatically split into chunks (configurable, default size is 16MB/chunk).
  - **Pause and Resume**: Allows temporarily pausing the upload and resuming after a while.
  - **Upload Lifecycle Callbacks**: Track the entire upload process using callback functions to monitor uploads lifecycle.
  - **Retry**:  Uploads might fail due to temporary network failures. Individual chunks are retried for 5 times with exponential backoff to recover automatically from such failures.
  - **Error Handling**: Comprehensive error management to notify users of issues during uploads.
  - **Customizability**: Options to customize chunk size and retry attempts.
  - Implemented support for Google Cloud Storage resumable uploads and chunked client uploads.
  - Added retry mechanism with exponential backoff for GCS upload failures based on retryable status codes.
  - Enabled support for user-provided signed URLs, allowing resumable uploads to work with externally generated session URIs.
  - Updated the API endpoint from https://v1.fastpix.io/on-demand/uploads to https://api.fastpix.io/v1/on-demand/upload for obtaining signed URLs.
- **Swift Package Manager Support**: SDK is installable via SPM using the repo URL.
