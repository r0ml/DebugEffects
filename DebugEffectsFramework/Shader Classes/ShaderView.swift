// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import SwiftUI
import UniformTypeIdentifiers

public struct ShaderView<T : ArgSetter> : View, Sendable {
  var shader : StitchDefinition<T>
  var debugFlag : Bool
  
  @State var saveImage : Bool = false
  @State var saveVideo : Bool = false
  
  @State var args : ArgProtocol<T.Args>
  
  
  public init(shader: StitchDefinition<T>, debug: Bool) {
    self.shader = shader
    self.debugFlag = debug
    args = (ArgProtocol<T.Args>).init(shader.name)
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
              MetalWithArgs<T>(args: $args, metalDelegate: shader.getMetalDelegate($args) )
            )
          } else {
            AnyView(
              StitchWithArgs<T>(args: $args, preview: false, name: shader.name, shaderType: shader.shaderType, shaderFn: shader.shaderFn)
//                                .color)
              )
          }
      /// Here's where the UI for setting args goes
      T.init(args: $args)
        }
    .onChange(of: args.floatArgs, initial: false) {
      UserDefaults.standard.set(args.serialized(), forKey: "settings.\(shader.name)" )
      }

    .onChange(of: args.background, initial: false) {
       switch args.background {
        case is CGColor:
          let c = args.background as! CGColor
//          UserDefaults.standard.set(args.background as! CGColor, forKey: "background.\(shader.name)" )
        default:
          break;
      }
    }

      .onChange(of: shader.name) {
        (args.background as? any VideoStream)?.startVideo()
      }
      .onAppear {
//        print("Shader View appears")
      }
      .onDisappear {
//        print("Shader View disappears")
      }
    }
}
    
