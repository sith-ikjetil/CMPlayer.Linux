// swift-tools-version: 5.7.3
import PackageDescription

    let package = Package(
        name: "Cmpg123",
        products: [
            .library(name: "Cmpg123", targets: ["Cmpg123"])
        ],
        targets: [
            .systemLibrary(name: "Cmpg123"),
        ]
    )
