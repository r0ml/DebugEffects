import PackagePlugin
import Foundation

@main
struct MergedMetalPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        let tool = try context.tool(named: "MetalMergeTool")
        let exec = tool.url
      let outFile = context.pluginWorkDirectoryURL.appending(component: "Merged.metallib")

        // App target’s own .metal files (tracked as inputs)
      var metalInputs : [URL] = []
      if let src = target as? SourceModuleTarget {
        metalInputs = src.sourceFiles.filter { $0.url.pathExtension == "metal" }.map(\.url)
      }

        // Env knobs (define these in Xcode Build Settings if you want)
        let env = ProcessInfo.processInfo.environment
        // Semicolon-separated list; defaults are applied in the tool if unset.
        let searchRoots = env["METAL_SEARCH_ROOTS"] ?? ""
        // Optional ignore dirs (e.g., ".git;build;.build")
        let ignoreDirs  = env["METAL_IGNORE_DIRS"] ?? ""
        // Optional include dirs for #include headers
        let includeDirs = env["MTL_INCLUDE_DIRS"] ?? ""

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
        let tool = try context.tool(named: "MetalMergeTool")
        let exec = tool.path
        let outFile = context.pluginWorkDirectory.appending("Merged.metallib")

        // Only the app target's .metal are tracked as inputs
        let metalInputs = target.inputFiles.filter { $0.path.extension == "metal" }.map(\.path)

        let env = ProcessInfo.processInfo.environment
        let searchRoots = env["METAL_SEARCH_ROOTS"] ?? ""
        let ignoreDirs  = env["METAL_IGNORE_DIRS"] ?? ""
        let includeDirs = env["MTL_INCLUDE_DIRS"] ?? ""

        var args: [String] = ["--output", outFile.string]
        metalInputs.forEach { args += ["--input", $0.string] }

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

