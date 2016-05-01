import PackageDescription

let package = Package(
    name: "SlimaneExample",
  	dependencies: [
      .Package(url: "https://github.com/noppoMan/Slimane", majorVersion: 0, minor: 3),
      .Package(url: "https://github.com/slimane-swift/SessionRedisStore", majorVersion: 0, minor: 2),
      .Package(url: "https://github.com/slimane-swift/BodyParser", majorVersion: 0, minor: 2),
      .Package(url: "https://github.com/slimane-swift/Render", majorVersion: 0, minor: 2),
      .Package(url: "https://github.com/slimane-swift/MustacheViewEngine", majorVersion: 0, minor: 2)
   ]
)
