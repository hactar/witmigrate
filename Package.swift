import PackageDescription

let package = Package(
    name: "witmigrate",
    dependencies: [
	.Package(url: "https://github.com/johnsundell/unbox.git", majorVersion: 2),
	.Package(url: "https://github.com/JohnSundell/Wrap.git", majorVersion: 2)
	]
)
