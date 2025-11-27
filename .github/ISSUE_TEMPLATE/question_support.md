---
name: Question/Support
about: Ask questions or get help with the FastPix iOS Uploads SDK
title: '[QUESTION] '
labels: ['question', 'needs-triage']
assignees: ''
---

# Question / Support

Thank you for reaching out! Please provide the following information to help us assist you efficiently.

---

## Question Type
- [ ] How to use a specific feature
- [ ] Integration help
- [ ] Configuration question
- [ ] Performance question
- [ ] Troubleshooting help
- [ ] Other: _______________

---

## Question
**What would you like to know?**

<!-- Provide a clear and specific question about the iOS Uploads SDK -->

---

## Current Setup
**Describe your current setup:**

- iOS Project Version: [e.g., 17.2]
- Swift Version: [e.g., 5.9]
- Player / Media Integration: [e.g., AVPlayer, Custom Player]
- SDK Version: [e.g., 1.0.0]

---

## What You've Tried
**Code or steps you have already tried:**

```swift
import fp_swift_upload_sdk  

var uploader = Uploads() 

Task { 
    let createUploadURL = try await self.myServerBackend.createDirectUpload()
    uploader.uploadFile(file: file!, endpoint: createUploadURL.absoluteString, chunkSizeKB: Int(chunkSize.text ?? "") ?? 0)
}
```

---

## Expected Outcome
**What are you trying to achieve?**

<!-- Example: track upload progress, handle retries automatically, pause/resume uploads -->

---

## Error Messages / Unexpected Behavior
```
<!-- Paste any error messages, logs, or unexpected behavior -->
```

---

## Use Case
**What are you building?**

- [ ] Mobile app
- [ ] Media analytics platform
- [ ] Video streaming service
- [ ] Other: _______________

---

## Additional Context
**Any other context, references, or examples:**

- [FastPix iOS Uploads SDK GitHub](https://github.com/FastPix/iOS-Uploads.git)
- [SDK Documentation](https://docs.fastpix.io/reference/on-demand-overview)
- [SPM Integration Guide](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app)

---

## Timeline / Priority
**How urgent is this question?**

- [ ] Critical (Blocking development)
- [ ] High (Needs resolution this week)
- [ ] Medium (Would like to know soon)
- [ ] Low (Just curious)

---

## Checklist
Before submitting, please ensure:

- [ ] I have provided a clear question
- [ ] I have included my current setup and environment
- [ ] I have described what I've tried
- [ ] I have pasted any relevant logs or errors
- [ ] I have referenced SDK documentation
- [ ] I have added additional context if needed

---

**We'll do our best to help you get unstuck! 🚀**

**Helpful Resources:**
- [FastPix iOS Uploads SDK GitHub](https://github.com/FastPix/iOS-Uploads.git)
- [API Reference](https://docs.fastpix.io/reference/on-demand-overview)
- [SPM Integration Guide](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app)
