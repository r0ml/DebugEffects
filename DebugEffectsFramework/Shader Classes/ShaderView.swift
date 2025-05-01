// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import SwiftUI
import UniformTypeIdentifiers

public struct ShaderView<T : ArgSetter> : View, Sendable {
  var shader : StitchDefinition<T>
  @State var debugFlag : Bool = false
  @State var saveImage : Bool = false
  @State var saveVideo : Bool = false
  
  var args : ArgProtocol<T.Args>
  
  public init(shader: StitchDefinition<T>) {
    self.shader = shader
    let aa = (ArgProtocol<T.Args>).init(shader.name)
    if aa.background == nil {
      aa.background = shader.background
    } else {
      print("background video?")
    }
    self.args = aa
  }
  
  @MainActor var mag : some Gesture {
    // FIXME: this should work for non-debug
    return MagnificationGesture()
  }
  
  @MainActor var drag : some Gesture {
    DragGesture()
  }
  
  public var body : some View {
    //    let _ = Self._printChanges()
    // here is either a MetalView or an ExtensionView
    VStack {
      if debugFlag {
        AnyView(
          // FIXME: I should need to pass $args twice in one line
          MetalWithArgs<T>(metalDelegate: shader.getMetalDelegate(args) )
        )
      } else {
        AnyView(
          StitchWithArgs<T>(args: args, preview: false, name: shader.name, shaderType: shader.shaderType, shaderFn: shader.shaderFn)
        )
      }
      /// Here's where the UI for setting args goes
      T.init(args: args)
    }
    .toolbar {
      HStack {
        Text("Debug")
        Toggle("Debeug", isOn: $debugFlag).toggleStyle(.switch)
      }
    }
    
    .onChange(of: args.floatArgs, initial: false) {
      UserDefaults.standard.set(args.serialized(), forKey: "settings.\(shader.name)" )
    }
    
    .onChange(of: args.background, initial: false) {
      if let c = args.background?.bgColor {
        print("color changed -- save defaults")
        //          UserDefaults.standard.set(args.background as! CGColor, forKey: "background.\(shader.name)" )
      } else if let i = args.background?.nsImage {
        print("image changed -- save defaults")
      } else if let v = args.background?.videoStream {
        if let vv = v as? VideoSupport {
          vv.startVideo()
        }
      }
    }
    
    .onChange(of: shader.name) {
      args.background?.videoStream?.startVideo()
    }
  }
}
    
