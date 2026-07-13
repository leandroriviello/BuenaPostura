// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "BuenaPostura",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "BuenaPosturaCore", targets: ["BuenaPosturaCore"]),
        .executable(name: "BuenaPostura", targets: ["BuenaPostura"]),
        .executable(name: "BuenaPosturaCoreSmokeTests", targets: ["BuenaPosturaCoreSmokeTests"])
    ],
    targets: [
        .target(name: "BuenaPosturaCore"),
        .executableTarget(
            name: "BuenaPostura",
            dependencies: ["BuenaPosturaCore"],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("CoreMotion"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("UserNotifications")
            ]
        ),
        .executableTarget(
            name: "BuenaPosturaCoreSmokeTests",
            dependencies: ["BuenaPosturaCore"]
        )
    ]
)
