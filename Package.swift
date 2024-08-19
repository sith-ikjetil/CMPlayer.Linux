// swift-tools-version: 5.10.1
import PackageDescription
    let package = Package(
        name: "CMPlayer",        
        defaultLocalization: "en",        
        products: [
            .executable(name: "CMPlayer", targets: ["CMPlayer"]),
            .library(name: "Cmpg123", type: .dynamic, targets: ["Cmpg123"]),
            .library(name: "Cao", type: .dynamic, targets: ["Cao"]),
        ],    
        dependencies: [
            .package(url: "https://github.com/ponyboy47/Termios.git", from: "0.1.1"),
        ],
        targets: [            
            .executableTarget(
                name: "CMPlayer",
                dependencies: [    
                    "Termios",                
                    "Cmpg123",
                    "Cao",
                    "Cffmpeg",
                ]
            ),
            .target(
                name: "Cmpg123",
                dependencies: [],
                cSettings: [
                    .headerSearchPath("include"),                    
                    .define("MY_MPG123_LIBRARY", to: "1")
                ],
                linkerSettings: [
                    .linkedLibrary("mpg123"),                    
                ]
            ),
            .target(
                name: "Cao",
                dependencies: [],
                cSettings: [
                    .headerSearchPath("include"),                    
                    .define("MY_AO_LIBRARY", to: "1")
                ],
                linkerSettings: [
                    .linkedLibrary("ao"),                    
                ]
            ),
            .target(
                name: "Cffmpeg",
                dependencies: [],
                cSettings: [
                    .headerSearchPath("include"),                    
                    .define("MY_AO_LIBRARY", to: "1")
                ],
                linkerSettings: [
                    .linkedLibrary("avcodec"),
                    .linkedLibrary("avformat"),
                    .linkedLibrary("avutil"),
                    .linkedLibrary("swresample"),
                ]
            ),
        ]        
    )
