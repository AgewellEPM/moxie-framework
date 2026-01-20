// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SimpleMoxieSwitcher",
    platforms: [.macOS(.v13)],
    products: [],
    dependencies: [
        .package(url: "https://github.com/emqx/CocoaMQTT.git", from: "2.1.0")
    ],
    targets: [
        .executableTarget(
            name: "SimpleMoxieSwitcher",
            dependencies: ["CocoaMQTT"]
        ),
    ]
)
