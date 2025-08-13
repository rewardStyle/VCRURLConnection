// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "VCRURLConnection",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        .library(
            name: "VCRURLConnection",
            type: .static,
            targets: ["VCRURLConnection"]
        ),
    ],
    targets: [
        .target(name: "VCRURLConnection"),
        .testTarget(
            name: "VCRURLConnectionTests",
            dependencies: ["VCRURLConnection"],
            resources: [
                .process("Resources/cassette-1.json"),
                .process("Resources/test.png")
            ]
        ),
    ]
)
