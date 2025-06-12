
# iOS Uploads SDK


This SDK simplifies uploading large files in iOS applications by breaking them into smaller chunks and uploading each chunk individually. Developed in Swift, it is available exclusively as a Swift package.

This SDK is designed specifically for use with FastPix and is not suitable for general-purpose file upload use cases.

## Features:

- **Chunking:** Files are automatically split into chunks (configurable, default size is 16MB/chunk).
- **Pause and Resume:** Allows temporarily pausing the upload and resuming after a while.
- **Upload Lifecycle Callbacks:** Track the entire upload process using callback functions to monitor uploads lifecycle.
- **Retry**:  Uploads might fail due to temporary network failures. Individual chunks are retried for 5 times with exponential backoff to recover automatically from such failures.
- **Error Handling**: Comprehensive error management to notify users of issues during uploads.
- **Customizability**: Options to customize chunk size and retry attempts.

# Prerequisites:
 
## Getting started with FastPix:
 
To get started with SDK, you will need a signed URL.
 
To make API requests, you'll need a valid **Access Token** and **Secret Key**. See the [Basic Authentication Guide](https://docs.fastpix.io/docs/basic-authentication) for details on retrieving these credentials.
 
Once you have your credentials, use the [Upload media from device](https://docs.fastpix.io/reference/direct-upload-video-media) API to generate a signed URL for uploading media.

## Installation

To install the SDK, you can use Swift Package Manager(SPM) :

## How to use Swift Package Manager 

The Swift Package Manager is a tool that simplifies the distribution and management of Swift code, seamlessly integrating with Xcode and the Swift build system to streamline downloading, compiling, and linking dependencies.

Here’s a quick guide for adding our package to your Xcode project [Step-by-step guide on using Swift Package Manager in Xcode](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app). 

To get started, use the repository URL in Xcode's search field: "https://github.com/FastPix/iOS-Uploads.git".
 
## Basic Usage

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

## Managing Uploads

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

## Parameters Accepted

The upload function accepts the following parameters:

| Name                | Type                                | Required | Description                                                                                                                                                   |
| ------------------- | ----------------------------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `endpoint`          | `string` or `() => Promise<string>` | Required | The signed URL endpoint where the file will be uploaded. Can be a static string or a function returning a `Promise` that resolves to the upload URL.          |
| `file`              | `File` or `Object`                  | Required | The file object to be uploaded. Typically a `File` retrieved from an `<input type="file" />` element, but can also be a generic object representing the file. |
| `chunkSize`         | `number` (in KB)                    | Optional | Size of each chunk in kilobytes. Default is `16384` KB (16 MB).<br>**Minimum:** 5120 KB (5 MB), **Maximum:** 512000 KB (500 MB).                              |
| `maxFileBytesKB`       | `number` (in KB)                    | Optional | Maximum allowed file size for upload, specified in kilobytes. Files exceeding this limit will be rejected.                                                    |
| `maxRetryAttempt` | `number`                            | Optional | Number of retry attempts per chunk in case of failure. Default is `5`.                                                                                        |                                    

# References 

- [Homepage](https://www.fastpix.io/)
- [Dashboard](https://dashboard.fastpix.io/login?redirect=https://dashboard.fastpix.io/)
- [GitHub](https://github.com/FastPix/iOS-Uploads.git)
- [API Reference](https://docs.fastpix.io/reference/on-demand-overview)
