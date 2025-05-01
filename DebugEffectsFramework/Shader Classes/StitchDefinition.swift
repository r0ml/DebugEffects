// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import SwiftUI

@MainActor var registry : [String : any AnyStitchDefinition] = [:]

@MainActor open class StitchDefinition<T : ArgSetter> : AnyStitchDefinition {
  
  public let name: String
  public let shaderType: ShaderType
  public let shaderFn : ShaderFunction
  public let background : BackgroundSpec?
  
  public var mdcache : MetalDelegate<T.Args>?

  public init(_ n : String, _ t : ShaderType, background: BackgroundSpec? = nil
  ) {
    name = n
    self.shaderType = t
    self.background = background
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
  
  @MainActor public func getShaderView() -> AnyView {
    return AnyView( ShaderView(shader: self) )
  }
  
  @MainActor func getMetalDelegate(_ args : ArgProtocol<T.Args> ) -> MetalDelegate<T.Args> {
    if let md = mdcache { return md }
    else {
      args.background = background
      let md = MetalDelegate( name: name, type: shaderType, args: args
                              )
      mdcache = md
      md.beginShader()
      background?.videoStream?.startVideo()
      return md
    }
  }
  
  @MainActor public func getSnapshot(_ s : CGSize)  -> any View {
    let args = ArgProtocol<T.Args>.init(id)
    if args.background == nil {
      args.background = background
    } else {
//      print("background?")
    }
    
//    try? await Task.sleep(for: .milliseconds(50))
    let av = StitchWithArgs<T>(args: args, preview: true, name: name,
                               shaderType: shaderType, shaderFn: shaderFn)

    return VStack {
      av
      Text(name)
    }.frame(width: s.width, height: s.height)
    
//    let renderer = ImageRenderer(content: AnyView( av ).frame(width: s.width, height: s.height) )
//        // FIXME: make sure and use the correct display scale for this device
//      renderer.scale = 1 // displayScale
//    return renderer.nsImage ?? NSImage()
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

