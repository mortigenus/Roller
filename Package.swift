// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Roller",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v6),
  ],
  products: [
    .library(
      name: "Roller",
      targets: ["Roller"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "0.4.1"),
    .package(url: "https://github.com/pointfreeco/swift-gen.git", from: "0.3.0"),
    .package(url: "https://github.com/pointfreeco/swift-parsing", from: "0.5.0"),
  ],
  targets: [
    .target(
      name: "Roller",
      dependencies: [
        .product(name: "Gen", package: "swift-gen"),
        .product(name: "Parsing", package: "swift-parsing"),
      ]),
    .systemLibrary(
      name: "Creadline"
    ),
    .target(
      name: "RollerMain",
      dependencies: [
        "Roller",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        "Creadline",
      ]),
    .testTarget(
      name: "RollerTests",
      dependencies: [
        "Roller",
      ]),
  ]
)
