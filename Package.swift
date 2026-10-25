// swift-tools-version: 6.0
// The example apps' hosts: one executable per app on Cairn's AppKit host. Cairn comes from the
// registry, as for any app. Each executable links its app's Lean side as one library,
// .cairn/lib/libcairn_examples_<app>.a, which `make lean` writes with Cairn's bin/cairn-link
// (Lean's runtime, Cairn and that app's library). v1 apps all export `cairn_app_*`, so no
// executable links two. This is the root package, so the link lines may use unsafeFlags.
import PackageDescription

let lib = Context.packageDirectory + "/.cairn/lib"

func app(_ name: String, _ archive: String, resources: [Resource]? = nil) -> Target {
    .executableTarget(
        name: "Cairn\(name)",
        dependencies: ["CExamples",
                       .product(name: "CLean", package: "cairn"),
                       .product(name: "CairnFrame", package: "cairn"),
                       .product(name: "CairnRender", package: "cairn"),
                       .product(name: "CairnHost", package: "cairn"),
                       .product(name: "CairnCapture", package: "cairn")],
        path: "host/Sources/Cairn\(name)",
        resources: resources,
        linkerSettings: [.unsafeFlags(["-L" + lib, "-lcairn_examples_\(archive)"])])
}

let package = Package(
    name: "cairn_examples",
    platforms: [.macOS("27.0")],
    dependencies: [
        .package(url: "https://cairn.registry.nexthub.sh/git/iamnbutler/cairn.git", from: "0.3.0"),
    ],
    targets: [
        // The apps' initializers (host/Sources/CExamples/include/cairn_examples.h).
        .target(name: "CExamples", dependencies: [.product(name: "CLean", package: "cairn")],
                path: "host/Sources/CExamples"),
        app("Counter", "counter"),
        app("Basics", "basics"),
        app("Todo", "todo"),
        app("Clock", "clock"),
        app("Tray", "tray"),
        app("Gallery", "gallery", resources: [.copy("images")]),
    ]
)
