import Foundation

struct Args {
    var inputs: [String] = []
    var searchRoots: [String] = []
    var ignoreDirs: Set<String> = []
    var includeDirs: [String] = []
    var output: String = ""
    var minMac: String? = nil
    var minIOS: String? = nil
}

@discardableResult
func run(_ cmd: String, _ args: [String]) throws -> String {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: cmd)
    p.arguments = args
    let out = Pipe(); p.standardOutput = out
    let err = Pipe(); p.standardError = err
    try p.run(); p.waitUntilExit()
    if p.terminationStatus != 0 {
        let e = String(decoding: err.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        throw NSError(domain: "MetalMergeTool", code: Int(p.terminationStatus),
                      userInfo: [NSLocalizedDescriptionKey: e])
    }
    let data = out.fileHandleForReading.readDataToEndOfFile()
    return String(decoding: data, as: UTF8.self)
}

func parseArgs(_ argv: [String]) -> Args {
    var a = Args()
    var it = argv.dropFirst().makeIterator()
    while let t = it.next() {
        switch t {
        case "--input":         if let v = it.next() { a.inputs.append(v) }
        case "--search-roots":  if let v = it.next() { a.searchRoots = v.split(separator: ";").map(String.init) }
        case "--ignore-dirs":   if let v = it.next() { a.ignoreDirs = Set(v.split(separator: ";").map(String.init)) }
        case "--include-dirs":  if let v = it.next() { a.includeDirs = v.split(separator: ";").map(String.init) }
        case "--output":        if let v = it.next() { a.output = v }
        case "--min-macos":     if let v = it.next() { a.minMac = v }
        case "--min-ios":       if let v = it.next() { a.minIOS = v }
        default: break
        }
    }
    return a
}

func defaultSearchRoots(env: [String:String]) -> [String] {
    var roots: [String] = []
    if let proj = env["PROJECT_DIR"] { roots.append(proj) }
    if let dd = env["BUILD_DIR"] {
        roots.append((dd as NSString).appendingPathComponent("../../SourcePackages/checkouts/DebugEffects"))
    }

  for i in roots {
    print("root: \(i)")
  }

    return roots
}

func collectMetalFiles(from roots: [String], ignoring ignore: Set<String>) -> [String] {
    let fm = FileManager.default
    var results: [String] = []
    for root in roots {
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: root, isDirectory: &isDir), isDir.boolValue else { continue }
        let enumerator = fm.enumerator(
            at: URL(fileURLWithPath: root),
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) { url, _ in
            ignore.contains(url.lastPathComponent)
        }
      if let enumerator {
        for case let url as URL in enumerator where url.pathExtension == "metal" {
          results.append(url.path)
        }
      }
    }
    return results
}

@main
struct MetalMergeTool {
    static func main() {
        do {
            try runMain()
        } catch {
            fputs("MetalMergeTool error: \(error)\n", stderr)
            exit(1)
        }
    }

    static func runMain() throws {
      print("run main, run main run main")

        var args = parseArgs(CommandLine.arguments)
        let env = ProcessInfo.processInfo.environment

        if args.searchRoots.isEmpty { args.searchRoots = defaultSearchRoots(env: env) }
        if args.ignoreDirs.isEmpty { args.ignoreDirs = [".git", "build", ".build", "Products", "Intermediates.noindex"] }
        guard !args.output.isEmpty else {
            throw NSError(domain: "MetalMergeTool", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing --output"])
        }

        let discovered = collectMetalFiles(from: args.searchRoots, ignoring: args.ignoreDirs)

      for i in discovered {
        print("discovered: \(i)")
      }
      
        var metalFiles = Array(Set(args.inputs + discovered)).sorted()

        if metalFiles.isEmpty {
            try Data().write(to: URL(fileURLWithPath: args.output))
            fputs("No .metal files found; wrote empty metallib placeholder\n", stderr)
            return
        }

        let workDir = (args.output as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: workDir, withIntermediateDirectories: true)

        let sdkName = (env["SDKROOT"] as NSString?)?.lastPathComponent
        func xcrunTool(_ name: String) throws -> String {
            var a = ["-f", name]
          // FIXME: put me back
          //  if let s = sdkName, !s.isEmpty { a = ["-sdk", s] + a }

            return try run("/usr/bin/xcrun", a).split(separator: "\n").first.map(String.init) ?? name
        }

        let metal = try xcrunTool("metal")
        let metallib = try xcrunTool("metallib")
        let metalar = try xcrunTool("metal-ar")

      print("metal \(metal), metallib \(metallib), metalar \(metalar)")

        var airs: [String] = []

     for (k,v) in env.sorted(by: { $0.key < $1.key }) {
        print("\(k)=\(v)")
      }

      
      var incdirs : [String] = []
      if let dd = env["MTL_HEADER_SEARCH_PATHS"] {
        for d in dd.split(separator: ":") {
          incdirs.append(dd) // (dd as NSString).appendingPathComponent("SourcePackages/checkouts/DebugEffects/Includes"))
        }
      }

      print("incdir \(incdirs)")

        for src in metalFiles {
            let base = ((src as NSString).lastPathComponent as NSString).deletingPathExtension
            let air = (workDir as NSString).appendingPathComponent("\(base).air")
            var mArgs = ["-c", src, "-o", air]
            if let m = args.minMac { mArgs += ["-mmacosx-version-min=\(m)"] }
            if let i = args.minIOS { mArgs += ["-miphoneos-version-min=\(i)"] }
            for inc in args.includeDirs { mArgs += ["-I", inc] }

          // FIXME: kludge?
          for inc in incdirs { mArgs += ["-I", inc] }

          print("run /usr/bin/env \(([metal] + mArgs).joined(separator: " "))")

            _ = try run("/usr/bin/env", [metal] + mArgs)

          print("worked?")

          airs.append(air)
        }

      print("oof")
      print("airs.count \(airs.count)")

        if airs.count == 1 {
            _ = try run("/usr/bin/env", [metallib, airs[0], "-o", args.output])
        } else {
            let archive = (workDir as NSString).appendingPathComponent("merged.air")

          print("run \(metalar) rc \(archive) \(airs.joined(separator: " "))")

            _ = try run("/usr/bin/env", [metalar, "rc", archive] + airs)

          print("run \(metallib) \(archive) -o \(args.output)")
          
            _ = try run("/usr/bin/env", [metallib, archive, "-o", args.output])


        }

        fputs("Merged metallib → \(args.output)\n", stderr)
    }
}
