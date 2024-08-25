// swift-tools-version: 5.10.1
import PackageDescription
    let package = Package(
        name: "CMPlayer",        
        defaultLocalization: "en",        
        products: [
            .executable(name: "cmplayer", targets: ["CMPlayer"]),
            .library(name: "Cmpg123", type: .dynamic, targets: ["Cmpg123"]),
            .library(name: "Cao", type: .dynamic, targets: ["Cao"]),
            .library(name: "Cffmpeg", type: .dynamic, targets: ["Cffmpeg"]),
            .library(name: "Casound", type: .dynamic, targets: ["Casound"]),
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
                    "Casound",
                ],
                cSettings: [
                    .define("CMP_TARGET_UBUNTU_V22_04"),
                    //.define("CMP_TARGET_UBUNTU_V24_04"),
                    //.define("CMP_TARGET_FEDORA_V40"),
                    //.define("CMP_TARGET_MANJARO_V24"),
                    .define("CMP_FFMPEG_V4"),
                    //.define("CMP_FFMPEG_V6"),
                    //.define("CMP_FFMPEG_V7"),
                ],
                swiftSettings: [
                    .define("CMP_TARGET_UBUNTU_V22_04"),
                    //.define("CMP_TARGET_UBUNTU_V24_04"),
                    //.define("CMP_TARGET_FEDORA_V40"),
                    //.define("CMP_TARGET_MANJARO_V24"),
                    .define("CMP_FFMPEG_V4"),
                    //.define("CMP_FFMPEG_V6"),
                    //.define("CMP_FFMPEG_V7"),
                ]
            ),
            .target(
                name: "Cmpg123",
                dependencies: [],
                cSettings: [                    
                    .headerSearchPath("include"),
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
                ],
                linkerSettings: [
                    .linkedLibrary("avcodec"),
                    .linkedLibrary("avformat"),
                    .linkedLibrary("avutil"),
                    .linkedLibrary("swresample"),
                ]
            ),
            .target(
                name: "Casound",
                dependencies: [],
                cSettings: [
                    .headerSearchPath("include"),                    
                ],
                linkerSettings: [
                    .linkedLibrary("asound"),                    
                ]
            ),
        ]        
    )
