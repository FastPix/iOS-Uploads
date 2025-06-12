// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let sdkName = "fp-swift-upload-sdk" // <- ✅ Define constant here

let package = Package(
    name: sdkName,
    products: [
        .library(
            name: sdkName,
            targets: [sdkName]),
    ],
    targets: [
        .target(
            name: sdkName),
        .testTarget(
            name: "\(sdkName)Tests",
            dependencies: [.target(name: sdkName)]),
    ],
    swiftLanguageVersions: [
        .v5
    ]
)

