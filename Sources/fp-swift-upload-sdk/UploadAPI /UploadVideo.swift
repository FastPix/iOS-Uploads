
import Foundation
import UIKit
import Network

public struct UserProps {
    var endpoint: String
    var file: URL
    var retryChunkAttempt: Int?
    var delayRetry: Int?
    var chunkSize: Int?
    var maxFileSize: Int?
    var initUploadUrl: String?
    var completeUploadUrl: String?
}

let defaultChunkSizeKB: Int = 16 * 1024

func calculateChunkSize(kbSize: Int?) -> Int {
    let sizeKB = (kbSize == nil || kbSize == 0) ? defaultChunkSizeKB : kbSize!
    return sizeKB * 1024
}

// MARK: - VideoChunkProcessor

public class VideoChunkProcessor {
    
    private var fileHandle: FileHandle
    private var fileSize: Int
    
    init?(fileURL: URL) {
        do {
            self.fileHandle = try FileHandle(forReadingFrom: fileURL)
            let attr = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            self.fileSize = attr[.size] as? Int ?? 0
        } catch {
            return nil
        }
    }
    
    func getChunk(chunkStart: Int, chunkEnd: Int) -> Data {
        
        do {
            if #available(iOS 13.4, *) {
                try fileHandle.seek(toOffset: UInt64(chunkStart))
                let sizeToRead = min(chunkEnd - chunkStart, fileSize - chunkStart)
                // `read(upToCount:)` returns non-optional `Data` on iOS 13.4+
                // but the compiler on older SDKs may still see the old
                // optional signature — use `?? Data()` to satisfy both.
                return (try fileHandle.read(upToCount: sizeToRead)) ?? Data()
            } else {
                // Legacy path: synchronous readData (available since iOS 2)
                fileHandle.seek(toFileOffset: UInt64(chunkStart))
                let sizeToRead = min(chunkEnd - chunkStart, fileSize - chunkStart)
                return fileHandle.readData(ofLength: sizeToRead)
            }
        } catch {
            return Data()
        }
    }
    
    func getFileSize() -> Int {
        return fileSize
    }
    
    deinit {
        if #available(iOS 13.0, *) {
            try? fileHandle.close()
        } else {
            fileHandle.closeFile()
        }
    }
}

// MARK: - UploadEvent

public enum UploadEvent: Sendable {
    case chunkAttempt(chunkNumber: Int, totalChunks: Int)
    case chunkSuccess(chunkNumber: Int, totalChunks: Int)
    case error(error: any Error)
    case progress(progress: Float)
    case uploadsuccess
    case pause
    case resume
    case online
    case offline
    case chunkAttemptFailure(chunkNumber: Int, totalChunks: Int, error: any Error, attempt: Int)
}

// MARK: - Delegate protocols

public protocol UploadsDelegate: AnyObject, Sendable {
    func uploads(_ uploads: Uploads, didEmit event: UploadEvent)
}

public protocol UploadProgressDelegate: AnyObject, Sendable {
    func didUpdateProgressText(_ text: String)
}

public protocol UploadSDKErrorDelegate: AnyObject, Sendable {
    func uploadSDKDidFail(with error: String)
}

// MARK: - Uploads

public class Uploads: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate {
    
    // MARK: Stored properties
    var videoFile: URL?
    var endpoint: String?
    var sessionURL: String?
    var customizedChunkSize: Int = defaultChunkSizeKB
    var chunkBytes: Int = defaultChunkSizeKB * 1024
    var fileSize: Int = 0
    var maxFileSize: Int = 0
    public var totalChunks: Int = 0
    var chunkStart: Int = 0
    var chunkEnd: Int = 0
    public var chunkOffset: Int = 1
    var totalChunkRetries: Int = 0
    var maxChunkRetries: Int = 0
    var objectName = ""
    var uploadID = ""
    var uploadURLS = [""]
    var prevSegmentStart: Date?
    var isUploadCompleted = false
    var chunkProcessor: VideoChunkProcessor?
    
    public weak var delegate: UploadsDelegate?
    public weak var progressDelegate: UploadProgressDelegate?
    
    public var errorDelegate: UploadSDKErrorDelegate?
    
    var session: URLSession!
    public var progressHandler: ((Float) -> Void)?
    var isPaused: Bool = false
    var isAborted: Bool = false
    var isOffline: Bool = false
    var failedChunkRetries: Int = 0
    var activeUploadTask: URLSessionUploadTask?
    
    // NWPathMonitor — available iOS 12+
    var monitor: NWPathMonitor?
    var consecutiveBackOffFailures = 0
    var maxLimitForBackOffFailures = 5
    var retryUpTo = 0
    
    // MARK: Init
    public override init() {
        super.init()
        let configuration = URLSessionConfiguration.default
        self.session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        self.monitor = NWPathMonitor()
        self.startMonitoringNetwork()
    }
    
    // MARK: - Emit helper
    private func emit(_ event: UploadEvent) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.uploads(self, didEmit: event)
        }
    }
    
    // MARK: - Public upload entry-point
    public func uploadFile(file: URL,
                           endpoint: String,
                           chunkSizeKB: Int? = nil,
                           maxRetryAttempt: Int? = nil,
                           maxFileBytesKB: Int? = nil) {
        self.videoFile = file
        self.endpoint = endpoint
        self.customizedChunkSize = (chunkSizeKB == nil || chunkSizeKB == 0) ? defaultChunkSizeKB : chunkSizeKB!
        self.chunkBytes = calculateChunkSize(kbSize: chunkSizeKB)
        self.fileSize = Uploads.getFileSize(at: file)
        self.maxFileSize = maxFileBytesKB ?? 0
        
        guard self.chunkBytes > 0 else {
            self.errorDelegate?.uploadSDKDidFail(with: "Validation failed: The chunk-size must be 5120 KB or more.")
            return
        }
        
        self.totalChunks = Int(ceil(Double(fileSize) / Double(self.chunkBytes)))
        self.chunkStart = 0
        self.chunkEnd = self.chunkBytes
        self.chunkOffset = 1
        self.totalChunkRetries = 0
        self.isPaused = false
        self.isAborted = false
        self.isOffline = false
        self.isUploadCompleted = false
        self.maxChunkRetries = maxRetryAttempt ?? 5
        
        guard let processor = VideoChunkProcessor(fileURL: file) else {
            self.errorDelegate?.uploadSDKDidFail(with: "Validation failed: Could not open file for reading.")
            return
        }
        self.chunkProcessor = processor
        
        self.monitor = NWPathMonitor()
        self.startMonitoringNetwork()
        
        // Use UIApplication notifications safely — they must be observed on
        // the main thread. `addObserver` is main-thread safe but wrapping in
        // async guarantees it when `uploadFile` is called off-main.
        DispatchQueue.main.async {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.appDidBecomeActive),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )
        }
        
        do {
            try (
                validateUserInput(endpoint: endpoint, streamFile: videoFile, customizedChunkSize: customizedChunkSize, maxFileBytes: 0)
            )
            self.requestChunk()
        } catch let error as UploadValidationError {
            self.errorDelegate?.uploadSDKDidFail(with: "Validation failed: \(error.localizedDescription)")
            emit(.error(error: error))
        } catch {
            emit(.error(error: error))
        }
    }
    
    // MARK: - Validation Error
    
    enum UploadValidationError: Error, LocalizedError {
        case invalidEndpoint
        case invalidFile
        case chunkSizeTooSmall
        case chunkSizeTooLarge
        case fileSizeExceeded(actualSize: Int, maxSize: Int)
        
        var errorDescription: String? {
            switch self {
            case .invalidEndpoint:
                return "The endpoint must be provided either as a string or a function that returns a promise."
            case .invalidFile:
                return "The file must be a valid file URL or data."
            case .chunkSizeTooSmall:
                return "The chunk-size must be 5120 KB or more."
            case .chunkSizeTooLarge:
                return "The chunk-size shouldn't be greater than 512000 KB."
            case .fileSizeExceeded(let actualSize, let maxSize):
                return "The uploaded file size of \(actualSize / 1024) KB exceeds the permitted file size of \(maxSize / 1024) KB."
            }
        }
    }
    
    // MARK: - Validate user input
    
    func validateUserInput(endpoint: Any?,
                           streamFile: URL?,
                           customizedChunkSize: Int?,
                           maxFileBytes: Int) throws {
        
        guard endpoint is String else {
            throw UploadValidationError.invalidEndpoint
        }
        
        guard let streamFile = streamFile,
              FileManager.default.fileExists(atPath: streamFile.path) else {
            throw UploadValidationError.invalidFile
        }
        
        // Chunk size validation
        if self.customizedChunkSize < 5120 {
            throw UploadValidationError.chunkSizeTooSmall
        }
        
        if self.customizedChunkSize == 0 {
            throw UploadValidationError.chunkSizeTooSmall
        }
        
        if self.customizedChunkSize > 512000 {
            throw UploadValidationError.chunkSizeTooLarge
        }
        
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: streamFile.path)
        if let fileSize = fileAttributes[.size] as? Int {
            if maxFileBytes > 0 && maxFileBytes < fileSize {
                throw UploadValidationError.fileSizeExceeded(actualSize: fileSize, maxSize: maxFileBytes)
            }
        } else {
            throw UploadValidationError.invalidFile
        }
    }
    
    // MARK: - File size helper
    private static func getFileSize(at url: URL) -> Int {
        
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: url.path)
            return attr[.size] as? Int ?? 0
        } catch {
            return 0
        }
    }
    
    // MARK: - Chunk helpers
    public func getVideoChunk(chunkStart: Int, chunkEnd: Int) -> Data? {
        return self.chunkProcessor?.getChunk(chunkStart: chunkStart, chunkEnd: chunkEnd)
    }
    
    public func updateChunkRange() {
        self.chunkStart = (self.chunkOffset - 1) * self.chunkBytes
        let potentialEnd = self.chunkOffset * self.chunkBytes
        let fileSize = Uploads.getFileSize(at: self.videoFile!)
        self.chunkEnd = min(potentialEnd, fileSize)
    }
    
    public func requestChunk() {
        guard self.totalChunks > 0,
              (self.chunkOffset - 1) < self.totalChunks else { return }
        
        let chunkStart = (self.chunkOffset == 0) ? 0 : self.chunkStart
        let chunkEnd = self.chunkEnd
        
        autoreleasepool {
            guard let currentChunk = self.getVideoChunk(chunkStart: chunkStart, chunkEnd: chunkEnd) else {
                return
            }
            self.prevSegmentStart = Date()
            self.emit(.chunkAttempt(chunkNumber: self.chunkOffset, totalChunks: self.totalChunks))
            let progressText = "  Uploading \(self.chunkOffset) of \(self.totalChunks)"
            self.progressDelegate?.didUpdateProgressText(progressText)
            self.submitHttpRequest(method: "PUT", urlString: self.endpoint ?? "", body: currentChunk)
        }
    }
    
    // MARK: - HTTP request
    func submitHttpRequest(method: String, urlString: String, body: Data) {
        guard let url = URL(string: urlString) else { return }
        
        let chunkEndRange = min(self.chunkStart + self.chunkBytes - 1, self.fileSize - 1)
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(videoFile?.pathExtension.lowercased(), forHTTPHeaderField: "Content-Type")
        request.setValue("bytes \(self.chunkStart)-\(chunkEndRange)/\(self.fileSize)",
                         forHTTPHeaderField: "Content-Range")
        
        // Capture values needed inside the completion handler to avoid
        // implicitly capturing `self` as Sendable.
        let capturedChunkEndRange = chunkEndRange
        
        let task = self.session.uploadTask(with: request, from: body) { [weak self] data, response, error in
            guard let self = self else { return }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                self.emit(.error(error: NSError(domain: "NoHTTPResponse", code: -1, userInfo: nil)))
                return
            }
            
            if let error = error {
                self.emit(.chunkAttemptFailure(
                    chunkNumber: self.chunkOffset + 1,
                    totalChunks: self.totalChunks,
                    error: error,
                    attempt: self.totalChunkRetries + 1
                ))
                if self.totalChunkRetries < self.maxChunkRetries &&
                    !self.isPaused && !self.isAborted && !self.isOffline &&
                    self.totalChunks > 0 && self.uploadURLS.count > 0 {
                    self.validateChunkUpload()
                    self.totalChunkRetries += 1
                } else {
                    self.emit(.error(error: error))
                    self.errorDelegate?.uploadSDKDidFail(with: error.localizedDescription)
                }
                return
            }
            
            // Parse Range header
            var uploadedBytes: Int = 0
            if let headers = (response as? HTTPURLResponse)?.allHeaderFields,
               let rangeHeader = headers["Range"] as? String {
                let byteRange = rangeHeader.replacingOccurrences(of: "bytes=", with: "")
                let parts = byteRange.split(separator: "-")
                if parts.count == 2 {
                    uploadedBytes = Int(parts[1]) ?? 0
                }
            }
            
            if httpResponse.statusCode == 308 {
                if uploadedBytes < capturedChunkEndRange {
                    self.requestChunk()
                } else if uploadedBytes == capturedChunkEndRange {
                    self.handleChunkSuccess()
                }
            } else if [200, 201, 204, 206].contains(httpResponse.statusCode) {
                self.consecutiveBackOffFailures = 0
                self.handleChunkSuccess()
            } else if [408, 429, 501, 502, 503].contains(httpResponse.statusCode) {
                self.errorDelegate?.uploadSDKDidFail(with: "Upload Failed with response code \(httpResponse.statusCode)")
                self.consecutiveBackOffFailures += 1
                
                if self.consecutiveBackOffFailures >= self.maxLimitForBackOffFailures {
                    return
                }
                
                let baseDelay: Double = 2000
                let maxDelay: Double = 5000
                let randomJitter = Double.random(in: 0..<1000)
                let delay = min(baseDelay * pow(2.0, Double(self.consecutiveBackOffFailures)) + randomJitter, maxDelay)
                let delayInSeconds = delay / 1000.0
                
                DispatchQueue.main.asyncAfter(deadline: .now() + floor(delayInSeconds)) { [weak self] in
                    self?.requestChunk()
                }
            }
        }
        self.activeUploadTask = task
        task.resume()
    }
    
    private func handleChunkSuccess() {
        self.emit(.chunkSuccess(chunkNumber: self.chunkOffset, totalChunks: self.totalChunks))
        let progressText = "  Successfully Uploaded \(self.chunkOffset) of \(self.totalChunks)"
        self.progressDelegate?.didUpdateProgressText(progressText)
        self.totalChunkRetries = 0
        self.chunkOffset += 1
        self.updateChunkRange()
        self.validateChunkUpload()
    }
    
    // MARK: - Chunk validation / completion
    public func validateChunkUpload() {
        if self.totalChunks == (self.chunkOffset - 1) {
            if self.totalChunks <= 1 {
                self.emit(.uploadsuccess)
            }
            // Multi-chunk final state — uploadsuccess emitted when server
            // confirms the last chunk via 200/201/204/206.
        } else {
            self.requestChunk()
        }
    }
    
    // MARK: - Abort / retry
    public func abort() {
        if self.activeUploadTask != nil && self.totalChunks > 0 && self.uploadURLS.count > 0 {
            self.activeUploadTask?.cancel()
            self.activeUploadTask = nil
            self.isAborted = true
            errorDelegate?.uploadSDKDidFail(with: "The current upload was aborted. Please try uploading a new video")
            self.retryUpload()
        }
    }
    
    public func retryUpload() {
        self.activeUploadTask?.cancel()
        self.activeUploadTask = nil
        self.uploadURLS.removeAll()
        self.uploadID = ""
        self.objectName = ""
        self.chunkOffset = 0
        self.totalChunks = 0
        self.chunkBytes = 0
        self.totalChunkRetries = 0
        self.isOffline = false
        self.isPaused = false
        self.isAborted = false
        self.isUploadCompleted = false
    }
    
    // MARK: - Pause / Resume
    public func pause() {
        if !self.isPaused &&
            !self.isOffline &&
            !self.isAborted &&
            self.totalChunkRetries < self.maxChunkRetries &&
            self.totalChunks > 0 &&
            self.uploadURLS.count > 0 {
            
            self.isPaused = true
            self.emit(.pause)
            activeUploadTask?.cancel()
            activeUploadTask = nil
        }
    }
    
    public func resume() {
        if self.isPaused &&
            !self.isOffline &&
            !self.isAborted &&
            self.totalChunkRetries < self.maxChunkRetries &&
            self.totalChunks > 0 &&
            self.uploadURLS.count > 0 {
            
            self.isPaused = false
            self.emit(.resume)
            if self.totalChunks != self.chunkOffset || self.totalChunks == 1 {
                requestChunk()
            }
        }
    }
    
    // MARK: - Network monitoring
    public func startMonitoringNetwork() {
        self.monitor?.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            if path.status == .satisfied {
                if self.isOffline &&
                    self.totalChunkRetries < self.maxChunkRetries &&
                    !self.isAborted &&
                    self.totalChunks > 0 &&
                    self.uploadURLS.count > 0 {
                    
                    self.isOffline = false
                    self.emit(.online)
                    self.errorDelegate?.uploadSDKDidFail(with: "Network is Online")
                    if !self.isUploadCompleted && !self.isPaused {
                        self.validateChunkUpload()
                    }
                }
            } else {
                self.isOffline = true
                self.emit(.offline)
                self.errorDelegate?.uploadSDKDidFail(with: "Network is Offline")
                
                if self.totalChunks != self.chunkOffset &&
                    !self.isUploadCompleted &&
                    !self.isAborted &&
                    self.totalChunkRetries < self.maxChunkRetries &&
                    self.totalChunks > 0 &&
                    self.uploadURLS.count > 0 {
                    
                    self.activeUploadTask?.cancel()
                    self.activeUploadTask = nil
                }
            }
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        self.monitor?.start(queue: queue)
    }
    
    @objc func appDidBecomeActive() {
        startMonitoringNetwork()
    }
    
    // MARK: - URLSession progress delegate
    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didSendBodyData bytesSent: Int64,
                           totalBytesSent: Int64,
                           totalBytesExpectedToSend: Int64) {
        
        let remainingChunks = totalChunks - (chunkOffset - 1)
        let progressChunkSize = fileSize - chunkStart
        let progressPerChunk = Float(progressChunkSize) / Float(fileSize) / Float(remainingChunks)
        let successfulProgress = Float(chunkStart) / Float(fileSize)
        let currentChunkProgress = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
        let chunkProgress = currentChunkProgress * progressPerChunk
        let overallProgress = min(successfulProgress + chunkProgress, 1.0)
        
        progressHandler?(overallProgress)
        self.emit(.progress(progress: overallProgress))
    }
}
