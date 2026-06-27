// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AgilCore",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "AgilCore",
            targets: ["AgilCore"]
        ),
    ],
    targets: [
        // MARK: - Main Library Target
        .target(
            name: "AgilCore",
            dependencies: [],
            path: "Sources",
            swiftSettings: [
                .unsafeFlags(["-suppress-warnings"], .when(configuration: .release))
            ]
        ),

        // MARK: - Unit Tests
   /*     .testTarget(
            name: "AgilCoreTests",
            dependencies: ["AgilCore"],
            path: "Tests/AgilCoreTests"
        ),
    */
    ],
    swiftLanguageModes: [.v6]
  
)
