// swift-tools-version: 5.7.3
import PackageDescription

    let package = Package(
        name: "termios",
        dependencies: [
            .package(url: "https://github.com/ponyboy47/Termios.git", from: "0.1.1")
        ]
    )
