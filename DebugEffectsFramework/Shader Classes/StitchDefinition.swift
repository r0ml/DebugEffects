// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import SwiftUI

@MainActor var registry : [String : any AnyStitchDefinition] = [:]

@MainActor open class StitchDefinition<T : ArgSetter> : AnyStitchDefinition {
  
  public let name: String
  public let shaderType: ShaderType
  public let shaderFn : ShaderFunction
  public var background : BackgroundSpec?
  public var imageArg : NSImage?
  
  public var mdcache : MetalDelegate<T.Args>?

  public convenience init(_ n : String, _ t : ShaderType, background: String, imageArg: String? = nil) {
    self.init(n, t, background: BackgroundSpec(NSImage(named: background)!), imageArg: imageArg == nil ? nil : NSImage(named: imageArg!)! )
  }
  
  public init(_ n : String, _ t : ShaderType, background: BackgroundSpec? = nil, imageArg: NSImage? = nil
  ) {
    name = n
    self.shaderType = t
    self.background = background
    self.imageArg = imageArg
    
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
  
  @MainActor public func getShaderView(debugFlag : Binding<Bool>) -> AnyView {
    return AnyView( ShaderView(shader: self, debugFlag: debugFlag) )
  }
  
  @MainActor func getMetalDelegate(_ args : ArgProtocol<T.Args>, _ controlState : ControlState ) -> MetalDelegate<T.Args> {
    if let md = mdcache { return md }
    else {
      
// at this point, load the UserDefaults for background
     
// FIXME: this also happens in ArgProtocol -- sort it out and do it one place.
      // this might be the right place, assuming that the StitchDefinition can be modified
      // to include the stored UserDefaults upon creation
      
      let n = name
      
      /*
      var bookmarkIsStale : Bool = false
      if let bmx = UserDefaults.standard.data(forKey: "background.\(n)") {
        let bm = bmx.dropFirst(2)
        if bmx[0] == 2 || bmx[0] == 3,
           // 2.
           let resolvedUrl = try? URL(resolvingBookmarkData: bm,
                                      options: [.withSecurityScope
                                                //, withoutUI
                                               ],
                                      relativeTo: nil,
                                      bookmarkDataIsStale: &bookmarkIsStale),
           !bookmarkIsStale {
          if resolvedUrl.startAccessingSecurityScopedResource() {
            // FIXME: need to also create Webcam or Video or Color
            if bmx[0] == 2,
               let ni = NSImage(contentsOf: resolvedUrl) {
              background = BackgroundSpec(ni)
            } else if bmx[0] == 3 {
              let nv = VideoSupport(url: resolvedUrl)
              background = BackgroundSpec(nv)
            } else {
              background = BackgroundSpec(NSColor.systemMint.cgColor)
            }
          }
        }
      }
      

      if let bmx = UserDefaults.standard.data(forKey: "imageArg.\(n)") {
        let bm = bmx.dropFirst(2)
        if bmx[0] == 2 || bmx[0] == 3,
           // 2.
           let resolvedUrl = try? URL(resolvingBookmarkData: bm,
                                      options: [.withSecurityScope
                                                //, withoutUI
                                               ],
                                      relativeTo: nil,
                                      bookmarkDataIsStale: &bookmarkIsStale),
           !bookmarkIsStale {
          if resolvedUrl.startAccessingSecurityScopedResource() {
            // FIXME: need to also create Webcam or Video or Color
            if bmx[0] == 2,
               let ni = NSImage(contentsOf: resolvedUrl) {
              imageArg = ni // BackgroundSpec(ni)
            } else if bmx[0] == 3 {
              let nv = VideoSupport(url: resolvedUrl)
              background = BackgroundSpec(nv)
            } else {
              background = BackgroundSpec(NSColor.systemMint.cgColor)
            }
          }
        }
      }




      args.background = background
      args.otherImage = imageArg
      */
      
      
      
      let md = MetalDelegate( name: name, type: shaderType, args: args
                              )
      md.controlState = controlState
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
    
    if args.otherImage == nil {
      args.otherImage = imageArg
    }
    
//    let av =

    return VStack {
      StitchWithArgs(args: args, preview: true, name: name,
                                 shaderType: shaderType, shaderFn: shaderFn, controlState: ControlState() )
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

