// swift-tools-version: 5.10.1
import PackageDescription
    let package = Package(
        name: "CMPlayer",        
        defaultLocalization: "en",        
        products: [
            .executable(name: "CMPlayer", targets: ["CMPlayer"]),
            .library(name: "Cmpg123", type: .dynamic, targets: ["Cmpg123"])
        ],    
        dependencies: [
            .package(url: "https://github.com/ponyboy47/Termios.git", from: "0.1.1"),
        ],
        targets: [            
            .executableTarget(
                name: "CMPlayer",
                dependencies: [    
                    "Termios",                
                    "Cmpg123"
                ]
            ),
            .target(
                name: "Cmpg123",
                dependencies: [],
                cSettings: [
                    .headerSearchPath("include"),                    
                    .define("MY_C_LIBRARY", to: "1")
                ],
                linkerSettings: [
                    .linkedLibrary("/usr/lib64/libmpg123.so")
                ]
            ),
        ]        
    )
