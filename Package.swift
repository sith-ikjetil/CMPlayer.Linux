// swift-tools-version: 5.7.3
import PackageDescription
    let pkgConfig = "libmpg123" // pkconfig <name>.pc file
    
    let provider: [SystemPackageProvider] = [ 
        .apt(["libmpg123-0"])   // provider <name> for -l<name>, -lmpg123-0
    ]   

    let package = Package(
        name: "CMPlayer",
        products: [
            .library(name: "Cmpg123", targets: ["Cmpg123"]),
        ],
        dependencies: [
            .package(url: "https://github.com/ponyboy47/Termios.git", from: "0.1.1"),
            /*.package(url: "Sources/Cmpg123", from: "0.0.1"),*/       
        ],        
        targets: [    
            .systemLibrary(
                name: "Cmpg123", 
                path: "Sources/Cmpg123", 
                pkgConfig: pkgConfig, 
                providers: provider),
            .executableTarget(
                name: "CMPlayer", 
                dependencies: ["Termios", "Cmpg123"])
            
        ]
    )
