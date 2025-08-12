import PackagePlugin
import Foundation

@main
struct MergedMetalPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        let tool = try context.tool(named: "MetalMergeTool")
        let exec = tool.url

      let outFile = context.pluginWorkDirectoryURL.appending(component: "Merged.metallib")


      var includeDirs = [URL]()

        // App target’s own .metal files (tracked as inputs)
      var metalInputs : [URL] = []

      let n = target.sourceModule!.directoryURL.appending(components: "../Shaders").standardizedFileURL
      let j = FileManager.default.enumerator(at: n, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsPackageDescendants])
      let urls = j!.compactMap({ $0 as? URL }).filter { $0.pathExtension == "metal" }
      metalInputs += urls


/*
      if let src = target as? SourceModuleTarget {
        metalInputs = src.sourceFiles.filter { $0.url.pathExtension == "metal" }.map(\.url)
        print("metalInputs: \(metalInputs)")
      }
*/
      
        // Env knobs (define these in Xcode Build Settings if you want)
        let env = ProcessInfo.processInfo.environment

/*     for (k,v) in env.sorted(by: { $0.key < $1.key }) {
        print("\(k)=\(v)")
      }
*/
      print("dependencies: \(target.dependencies)")
      let a = target.dependencies
     for b in a {
       switch b {
         case .target(let t):
           print("directory => \(t.directoryURL.path)")
           print(t.sourceModule?.directoryURL.path)
         case .product(let t):
           print("product => \(t.name)")
           let n = t.sourceModules.first!.directoryURL.appending(components: "../Metal").standardizedFileURL
           includeDirs.append(n)
           let j = FileManager.default.enumerator(at: n, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsPackageDescendants])
           let urls = j!.compactMap({ $0 as? URL }).filter { $0.pathExtension == "metal" }
           metalInputs += urls
         @unknown default:
           fatalError("no such dependency")
       }
     }


      var args: [String] = ["--output", outFile.path]
        metalInputs.forEach { args += ["--input", $0.path] }

//      if !searchRoots.isEmpty { args += ["--search-roots", (searchRoots.map { $0.path }).joined(separator: ";")] }
//        if !ignoreDirs.isEmpty  { args += ["--ignore-dirs",  ignoreDirs] }
      if !includeDirs.isEmpty { args += ["--include-dirs", (includeDirs.map { $0.path }).joined(separator: ";")] }

        if let macMin = env["MTL_MIN_MACOS"] { args += ["--min-macos", macMin] }
        if let iosMin = env["MTL_MIN_IOS"]   { args += ["--min-ios",   iosMin] }

        return [
            .buildCommand(
                displayName: "Merging Metal → Merged.metallib",
                executable: exec,
                arguments: args,
                inputFiles: metalInputs,    // target-local changes trigger rebuild
                outputFiles: [outFile]
            )
        ]
    }
}

// Xcode projects: opt-in support (same args/env). Not required, but nice to have.
#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin
extension MergedMetalPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
      print("XCode Create BuildCommands")

        let tool = try context.tool(named: "MetalMergeTool")
        let exec = tool.url
      let outFile = context.pluginWorkDirectoryURL.appendingPathComponent("Merged.metallib")

        // Only the app target's .metal are tracked as inputs
      let metalInputs = target.inputFiles.filter { $0.url.pathExtension == "metal" }.map { $0.url }

        let env = ProcessInfo.processInfo.environment
        let searchRoots = env["METAL_SEARCH_ROOTS"] ?? ""
        let ignoreDirs  = env["METAL_IGNORE_DIRS"] ?? ""
        let includeDirs = env["MTL_INCLUDE_DIRS"] ?? ""

      let kk = target.dependencies
      print("Context: \(context)")
      print("Target: \(target)")
      print("Dependencies: \(kk)")
      for dep in kk {
        switch dep {
        case .target(let depTarget):
            print("Dependency target: \(depTarget.displayName)")
            print("Dependency root: \(depTarget.inputFiles)")
        case .product(let product):
            for productTarget in product.targets {
                print("Product target: \(productTarget.name)")
                print("Product root: \(productTarget.directoryURL)")
              for t in product.targets {
                print("-- target \(t)")
              }
            }
        default:
            break
        }
      }

      var args: [String] = ["--output", outFile.path]
        metalInputs.forEach { args += ["--input", $0.path] }

        if !searchRoots.isEmpty { args += ["--search-roots", searchRoots] }
        if !ignoreDirs.isEmpty  { args += ["--ignore-dirs",  ignoreDirs] }
        if !includeDirs.isEmpty { args += ["--include-dirs", includeDirs] }

        if let macMin = env["MTL_MIN_MACOS"] { args += ["--min-macos", macMin] }
        if let iosMin = env["MTL_MIN_IOS"]   { args += ["--min-ios",   iosMin] }

        return [
            .buildCommand(
                displayName: "Merging Metal → Merged.metallib",
                executable: exec,
                arguments: args,
                inputFiles: metalInputs,
                outputFiles: [outFile]
            )
        ]
    }
}
#endif

