// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Roller",
  products: [
    .library(
      name: "Roller",
      targets: ["Roller"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "0.4.1"),
    .package(url: "https://github.com/pointfreeco/swift-gen.git", from: "0.3.0"),
    .package(url: "https://github.com/pointfreeco/swift-parsing", from: "0.1.2"),
    .package(name: "Prelude", url: "https://github.com/pointfreeco/swift-prelude", .branch("main")),
  ],
  targets: [
    .target(
      name: "Roller",
      dependencies: [
        .product(name: "Gen", package: "swift-gen"),
        .product(name: "Parsing", package: "swift-parsing"),
        "Prelude",
        .product(name: "Optics", package: "Prelude"),
      ]),
    .target(
      name: "RollerMain",
      dependencies: [
        "Roller",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ]),
    .testTarget(
      name: "RollerTests",
      dependencies: [
        "Roller",
      ]),
  ]
)


