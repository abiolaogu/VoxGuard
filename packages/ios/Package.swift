// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ACM",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ACMDomain",
            targets: ["ACMDomain"]
        ),
        .library(
            name: "ACMData",
            targets: ["ACMData"]
        ),
        .library(
            name: "ACMPresentation",
            targets: ["ACMPresentation"]
        )
    ],
    dependencies: [
        // Apollo GraphQL
        .package(url: "https://github.com/apollographql/apollo-ios.git", from: "1.7.0"),
        
        // The Composable Architecture
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "1.7.0"),
        
        // Dependencies management
        .package(url: "https://github.com/pointfreeco/swift-dependencies.git", from: "1.1.0"),
        
        // Tagged types
        .package(url: "https://github.com/pointfreeco/swift-tagged.git", from: "0.10.0"),
        
        // Keychain access
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
    ],
    targets: [
        // Domain Layer
        .target(
            name: "ACMDomain",
            dependencies: [
                .product(name: "Tagged", package: "swift-tagged"),
            ],
            path: "Sources/Domain"
        ),
        
        // Data Layer
        .target(
            name: "ACMData",
            dependencies: [
                "ACMDomain",
                .product(name: "Apollo", package: "apollo-ios"),
                .product(name: "ApolloWebSocket", package: "apollo-ios"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "KeychainAccess", package: "KeychainAccess"),
            ],
            path: "Sources/Data"
        ),
        
        // Presentation Layer
        .target(
            name: "ACMPresentation",
            dependencies: [
                "ACMDomain",
                "ACMData",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            path: "Sources/Presentation"
        ),
        
        // Tests
        .testTarget(
            name: "ACMTests",
            dependencies: [
                "ACMDomain",
                "ACMData",
                "ACMPresentation",
            ]
        ),
    ]
)
