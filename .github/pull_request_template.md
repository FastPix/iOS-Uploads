# FastPix iOS Uploads SDK - Documentation PR

## Documentation Changes
- [ ] New documentation added
- [ ] Existing documentation updated
- [ ] Documentation errors fixed
- [ ] Code examples updated
- [ ] Links and references updated

---

## Files Modified
- [ ] README.md
- [ ] docs/ directory
- [ ] USAGE.md
- [ ] CONTRIBUTING.md
- [ ] Other: _______________

---

## Summary
**Brief description of changes:**

<!-- Describe what documentation was added, updated, or fixed for the iOS Uploads SDK -->

---

## Code Examples
```swift
import fp_swift_upload_sdk

// Initialize Uploads instance for handling file uploads
var uploader = Uploads()

// Example: Upload a file using a signed URL from your backend
Task {
    let createUploadURL = try await self.myServerBackend.createDirectUpload()
    uploader.uploadFile(
        file: file!,
        endpoint: createUploadURL.absoluteString,
        chunkSizeKB: Int(chunkSize.text ?? "") ?? 0
    )
}

// Manage upload lifecycle
uploader.pause()  // Pause upload
uploader.resume() // Resume upload
uploader.abort()  // Abort upload
```

---

## Testing
- [ ] All code examples tested on iOS
- [ ] Links verified
- [ ] Grammar checked
- [ ] Formatting consistent

---

## Review Checklist
- [ ] Content is accurate
- [ ] Code examples work as expected
- [ ] Links are working
- [ ] Grammar is correct
- [ ] Formatting is consistent

---

**Ready for review!**
