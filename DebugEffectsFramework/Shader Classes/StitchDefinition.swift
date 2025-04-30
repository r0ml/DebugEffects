// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import SwiftUI

@MainActor var registry : [String : any AnyStitchDefinition] = [:]

@MainActor open class StitchDefinition<T : ArgSetter> : AnyStitchDefinition {
  
  public let name: String
  public let shaderType: ShaderType
  public let shaderFn : ShaderFunction
  
  public var mdcache : MetalDelegate<T.Args>?

  public init(_ n : String, _ t : ShaderType
  ) {
    name = n
    self.shaderType = t
    let co = MTLCompileOptions()
    co.libraryType = .dynamic
    co.libraries = []
    co.optimizationLevel = MTLLibraryOptimizationLevel(rawValue: 0)!
    co.preprocessorMacros = [:]
    co.installName = nil
    
    let l = ShaderLibrary.default
    
    self.shaderFn = l[dynamicMember: n]
    
    registry[n] = self
  }
  
  @MainActor public func getShaderView(_ debugFlag : Bool) -> AnyView {
    return AnyView( ShaderView(shader: self, debug: debugFlag) )
  }
  
  @MainActor func getMetalDelegate(_ args : Binding<ArgProtocol<T.Args> >) -> MetalDelegate<T.Args> {
    if let md = mdcache { return md }
    else {
      let md = MetalDelegate( name: name, type: shaderType, args: args.wrappedValue
                              )
      mdcache = md
      md.beginShader()
      (args.background as? (any VideoStream))?.startVideo()
      return md
    }
  }
  
  @MainActor public func getSnapshot(_ s : CGSize) async -> NSImage {
    let args = ArgProtocol<T.Args>.init(id)

    try? await Task.sleep(for: .milliseconds(50))
    let av = StitchWithArgs<T>(args: Binding.constant(args), preview: true, name: name,
                               shaderType: shaderType, shaderFn: shaderFn)

    let renderer = ImageRenderer(content: AnyView( av ).frame(width: s.width, height: s.height) )
        // FIXME: make sure and use the correct display scale for this device
      renderer.scale = 1 // displayScale
    return renderer.nsImage ?? NSImage()
  }

  @MainActor public func teardown() {
    // FIXME: how do I do the teardown??
//    (args.background as? VideoStream)?.stopVideo()
  }
}

extension StitchDefinition {
  nonisolated public var id : String {
    self.name
  }

}

