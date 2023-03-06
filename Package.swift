// swift-tools-version: 5.7.3
import PackageDescription

    let package = Package(
        name: "CMPlayer",
        products: [
            .library(name: "Cmpg123", targets: ["Cmpg123"]),
        ],
        dependencies: [
            .package(url: "https://github.com/ponyboy47/Termios.git", from: "0.1.1"),            
        ],        
        targets: [    
            .systemLibrary(name: "Cmpg123"),        
            .executableTarget(name: "CMPlayer", dependencies: ["Termios", "Cmpg123"]),            
        ]
    )
