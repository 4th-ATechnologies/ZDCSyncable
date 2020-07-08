// swift-tools-version:5.0
import PackageDescription

let package = Package(
	name: "ZDCSyncable",
	products: [
		.library(name: "ZDCSyncable", targets: ["ZDCSyncable"])
	],
	targets: [
		.target(name: "ZDCSyncable", path: "ZDCSyncable", exclude: []),
		.testTarget(name: "ZDCSyncableTests", dependencies: ["ZDCSyncable"], path: "UnitTests")
	]
)