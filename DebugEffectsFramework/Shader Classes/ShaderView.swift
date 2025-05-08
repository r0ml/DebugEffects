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
  @State var args : ArgProtocol<T.Args>

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
  
  let singleStepIncrement = 0.1
  
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
            if let vv = args.background?.videoStream {
              Task.detached {

                let t = await controlState.elapsedTime
//                let adj = min(1, t)
                await vv.seek(to: t + singleStepIncrement)
                await controlState.deadTime -= singleStepIncrement
//                Task.detached {
//                  try await Task.sleep(for: .seconds(0.1))
                  await controlState.singleStep = false
//                }
              }
            } else {
              controlState.deadTime = max(0, controlState.deadTime - 1)
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
              args.background?.videoStream?.startVideo(false)
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
      controlState.reset()
      if let c = args.background?.bgColor {
        print("color changed -- save defaults")
        //          UserDefaults.standard.set(args.background as! CGColor, forKey: "background.\(shader.name)" )
      } else if let i = args.background?.nsImage {
//        print("image changed -- save defaults")
      } else if let v = args.background?.videoStream {
          v.startVideo(true)
      }
    }
    
    .onChange(of: shader.name) {
      controlState.reset()
      args.background?.videoStream?.startVideo(true)
    }
  }
}
    
