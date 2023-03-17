// swift-tools-version: 5.7.3
import PackageDescription

    // pkconfig = <name>.pc file
    let pkgConfig = "libmpg123" 
    
    let provider: [SystemPackageProvider] = [ 
        // provider <name> for -l<name> = -lmpg123-0
        .apt(["mpg123-0", "mpg123-dev"]),   
    ]   

    let package = Package(
        name: "Cmpg123",
        products: [
            .library(name: "Cmpg123", targets: ["Cmpg123"]),
        ],
        targets: [    
            .systemLibrary(
                name: "Cmpg123", 
                pkgConfig: pkgConfig, 
                providers: provider),
        ]
    )
