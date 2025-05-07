// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import SwiftUI
import UniformTypeIdentifiers

public struct ShaderViewWrapper : View {
  var shader : (any AnyStitchDefinition)?
  @Binding var debugFlag : Bool

  public init(shader: (any AnyStitchDefinition)?, debugFlag: Binding<Bool>) {
    self.shader = shader
    self._debugFlag = debugFlag
  }
  
  public var body : some View {
    if let shader {
      return shader.getShaderView(debugFlag: $debugFlag)
    } else {
      return AnyView(Text("Nothing selected"))
    }
  }
}

public struct ShaderView<T : ArgSetter> : View, Sendable {
  var shader : StitchDefinition<T>
  var args : ArgProtocol<T.Args>

  @Binding var debugFlag : Bool
  @State var saveImage : Bool = false
  @State var saveVideo : Bool = false
  
  @State var controlState : ControlState = ControlState()

  public init(shader: StitchDefinition<T>, debugFlag: Binding<Bool>) {
    self.shader = shader
    let aa = (ArgProtocol<T.Args>).init(shader.name)
    if aa.background == nil {
      aa.background = shader.background
    }
    if aa.otherImage == nil {
      aa.otherImage = shader.imageArg
    }
    
    self.args = aa
    self._debugFlag = debugFlag
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
    VStack {
      if debugFlag {
         AnyView(MetalWithArgs<T>(metalDelegate: shader.getMetalDelegate(args, controlState) ))
      } else {
        AnyView(
          StitchWithArgs(args: args, preview: false, name: shader.name, shaderType: shader.shaderType, shaderFn: shader.shaderFn, controlState: controlState)
        )
      }
      
      
      
      ControlView(controlState: $controlState)
        .onChange(of: controlState.singleStep) { ov, nv in
          if nv {
            if let v = args.background?.videoStream,
               let vv = v as? VideoSupport {
              Task {
                await vv.seekForward(by: 1/10.0)
              }
            }
          }
        }
//        .onChange(of: shader.name, initial: true) {ov, nv in
//          print(ov, nv)
//        }
        .onChange(of: controlState.paused, initial: true) { ov, nv in
          if nv { // paused
              // FIXME: make startVideo / stopVideo methods on protocol Backgroundable
              args.background?.videoStream?.stopVideo()
          } else {
              args.background?.videoStream?.startVideo()
          }
        
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
    
    // FIXME: video gets started twice -- once for change of background, once for change of shader name
    .onChange(of: args.background, initial: false) {
      if let c = args.background?.bgColor {
        print("color changed -- save defaults")
        //          UserDefaults.standard.set(args.background as! CGColor, forKey: "background.\(shader.name)" )
      } else if let i = args.background?.nsImage {
//        print("image changed -- save defaults")
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
    
