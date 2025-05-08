// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

/** This stores the location of the last mouse point -- in local view pixel coordinates */
class Location {
  var pt : CGPoint = CGPoint(x: 100, y: 75);
}

struct StitchWithArgs<T : Instantiatable > : View {

  @Environment(\.colorScheme) var colorScheme : ColorScheme

  var args : ArgProtocol<T>
  @State var data : Data = Data()
  @State var argArgs : [Shader.Argument] = []
  var controlState : ControlState
  
  var location : Location = Location()

  var preview : Bool
  var name : String
  
  var shaderFn : ShaderFunction
  var shaderType : ShaderType
   
  init(args : ArgProtocol<T>, preview : Bool, name : String,
       shaderType : ShaderType, shaderFn: ShaderFunction,
       controlState : ControlState) {
    self.preview = preview
    self.name = name
    self.shaderFn = shaderFn
    self.shaderType = shaderType
    self.args = args
    self.controlState = controlState
  }
  
  func getArgs() -> [Shader.Argument] {
    return args.asShaderArguments()
  }
  
  // For a Metal scaffold, this should be a Metal View with a delegate that runs the
  // fragment shader "scaffold" and passes in a parameter to have it invoke the
  // colorFn or distortFn or layerFn
    public var body: some View {
     // let _ = Self._printChanges()
      
      if preview {
        
        AnyView(
          // FIXME: grab a frame from the video for this thumbnail
          StillView(elapsedTime: 5, nn: args.background?.view ?? AnyView(Rectangle()), location: Location(),
                    shaderType: shaderType, shaderFn: shaderFn, args: getArgs() )
          .frame(minHeight: 80)
          .background(Color.black)
          .clipped()
        )
      } else {

        AnyView ( VStack {
          
          let myGesture = DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged({
              self.location.pt = $0.location
            })
          
          var nn = args.background?.view ?? AnyView(Rectangle().foregroundStyle(Color.blue))
          
          TimelineView(  .animation(minimumInterval: 0.01, paused: controlState.paused && !controlState.singleStep)   ) {@MainActor context in
            // let _ = print("timeline")

            let ce = controlState.elapsedTime
            if let nnn = self.sortOutVideo() {
              let _ = nn = nnn
            }
          
            StillView(elapsedTime: ce, nn: nn,
                      location: location,
                      shaderType: shaderType, shaderFn: shaderFn, args: getArgs())
            .background(Color.black)
            .gesture(myGesture)
            
//            let _ = controlState.doStep()
          }.onChange(of: args.floatArgs, initial: true) {
            argArgs = getArgs()
          }.onChange(of: args.otherImage, initial: true) {
            argArgs = getArgs()
          }.onChange(of: args.background, initial: true) {
            argArgs = getArgs()
            //      print("background changed")
          }
          
          
          .clipped()
        }
          
          )





      }
    }
  
  func sortOutVideo() -> AnyView? {
    guard let vv = args.background?.videoStream else { return nil }
    var ce = controlState.elapsedTime
    let drift = ce - vv.currentTime.seconds
    if drift > 0.3 {
      print("drift is \(drift)")
      controlState.deadTime += drift - 0.15
      ce -= drift - 0.15
    }
    if controlState.paused && !controlState.singleStep {
      if let xx = vv.lastImage,
         let z = NSImage(ciImage: xx.oriented(.down) ) {
        return AnyView(Image.init(nsImage: z).resizable().scaledToFit())
      }
    } else {
      
//      let _ = print("elapsed time in timeline", controlState.elapsedTime)

      if let xx = vv.readBufferAsImage( ce ),
         let z = NSImage.init(ciImage: xx.oriented(.down)) {
        
        return AnyView(Image.init(nsImage: z).resizable().scaledToFit())
      } else {
        if let xx = vv.lastImage,
           let z = NSImage(ciImage: xx.oriented(.down)) {
          return AnyView(Image.init(nsImage: z).resizable().scaledToFit())
        }
        //                let _ = print("keep the old one")
      }
    }
    return nil
  }
  
}
