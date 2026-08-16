// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "TeslaGarage",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "TeslaGarage", targets: ["TeslaGarage"])],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.8.0")
    ],
    targets: [
        .executableTarget(
            name: "TeslaGarage",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            exclude: [
                "Resources/TeslaGarage.icon",
                "Resources/TeslaGarageCustom.icns",
                "Resources/tesla-garage-app-icon.png"
            ],
            resources: [.process("Resources")],
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])
            ]
        )
    ]
)
