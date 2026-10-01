// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "WorkshopCore", platforms: [.macOS("27.0")], products: [.library(name: "WorkshopCore", targets: ["WorkshopCore"])], targets: [.target(name: "WorkshopCore", path: "Sources/Core"), .testTarget(name: "WorkshopCoreTests", dependencies: ["WorkshopCore"], path: "Tests/Core")])
