---
name: Documentation Issue
about: Report problems with the FastPix iOS Uploads SDK documentation
title: '[DOCS] '
labels: ['documentation', 'needs-triage']
assignees: ''
---

## Documentation Issue

Thank you for helping improve the FastPix iOS Uploads SDK documentation! Please provide the following information:

## Issue Type
- [ ] Missing documentation
- [ ] Incorrect information
- [ ] Unclear explanation
- [ ] Broken links
- [ ] Outdated content
- [ ] Other: _______________

## Description
**Describe the documentation issue clearly:**

<!-- What's wrong with the documentation? -->

## Current Documentation
**What does the current documentation say?**

<!-- Paste the current documentation content or reference link -->

## Expected Documentation
**What should the documentation say instead? Example:**

```swift
import fp_swift_upload_sdk

var uploader = Uploads()

Task {
    let createUploadURL = try await myServerBackend.createDirectUpload()
    uploader.uploadFile(
        file: file!,
        endpoint: createUploadURL.absoluteString,
        chunkSizeKB: "Chunk-size"
    )
}

// Example lifecycle control methods
uploader.pause()
uploader.resume()
uploader.abort()
```

## Location
**Where is this documentation issue located?**

- [ ] README.md
- [ ] docs/ directory
- [ ] USAGE.md
- [ ] CONTRIBUTING.md
- [ ] API documentation
- [ ] Code examples
- [ ] Other: _______________

**Specific file and section:**
<!-- e.g., README.md line 45, or docs/api-reference.md section "Authentication" -->

## Impact
**How does this issue affect users?**

- [ ] Blocks new users from getting started
- [ ] Causes confusion for existing users
- [ ] Leads to incorrect implementation
- [ ] Creates support requests
- [ ] Other: _______________

## Proposed Fix
**How should the documentation be corrected?**

<!-- Describe the correction or updated example that should appear -->

## Additional Context
Add any other context that may help clarify or resolve the issue.

## Screenshots
<!-- If applicable, include screenshots of the documentation issue -->

### Related Issues
- **GitHub Issues:** [Link to any related issues]
- **User Feedback:** [Link to user complaints or confusion]

### Testing
**How did you discover this issue?**

- [ ] While following the documentation
- [ ] User reported confusion
- [ ] Code didn't work as documented
- [ ] Other: _______________

## Priority
Please indicate the priority of this documentation issue:

- [ ] Critical (Blocks users from using the SDK)
- [ ] High (Causes significant confusion)
- [ ] Medium (Minor clarity issue)
- [ ] Low (Cosmetic improvement)

## Checklist
Before submitting, please ensure:

- [ ] I have identified the specific documentation issue
- [ ] I have provided the current and expected content
- [ ] I have explained the impact on users
- [ ] I have proposed a clear fix
- [ ] I have checked if this is already reported
- [ ] I have provided sufficient context

---

**Thank you for helping improve the FastPix iOS Uploads SDK documentation! 📚**
