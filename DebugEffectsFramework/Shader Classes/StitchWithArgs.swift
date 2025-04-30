// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import SwiftUI
import UniformTypeIdentifiers

/** This stores the location of the last mouse point -- in local view pixel coordinates */
class Location {
  var pt : CGPoint = CGPoint(x: 100, y: 75);
}

struct StitchWithArgs<T : ArgSetter > : View {

  @Environment(\.colorScheme) var colorScheme : ColorScheme

  @Binding var args : ArgProtocol<T.Args>
  @State var data : Data = Data()
  @State var controlState : ControlState = ControlState()
  @State var argArgs : [Shader.Argument] = []
  
  var location : Location = Location()

  var preview : Bool
  var name : String
  
  var shaderFn : ShaderFunction
  var shaderType : ShaderType
  
  init(args : Binding<ArgProtocol<T.Args>>, preview : Bool, name : String, // argSetter : T.Type,
       shaderType : ShaderType, shaderFn: ShaderFunction) {
    self.preview = preview
    self.name = name
    self.shaderFn = shaderFn
    self.shaderType = shaderType
        self._args = args
  }
  
  func getArgs() -> [Shader.Argument] {
    return args.asShaderArguments()
  }
  
  // For a Metal scaffold, this should be a Metal View with a delegate that runs the
  // fragment shader "scaffold" and passes in a parameter to have it invoke the
  // colorFn or distortFn or layerFn
    public var body: some View {
    //  let _ = Self._printChanges()
      
      if preview {
        
        AnyView(
          // FIXME: grab a frame from the video for this thumbnail
          StillView(elapsedTime: 5, nn: args.background?.view ?? AnyView(Rectangle()) /* BaseView(image: (args.background as? NSImage) ) */, location: Location(),
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
          
          var nn = args.background?.view ?? AnyView(Rectangle())

          TimelineView(  .animation(minimumInterval: 0.01, paused: controlState.paused && !controlState.singleStep)   ) {@MainActor context in
            if let vv = (args.background as? (any VideoStream)),
               let xx = vv.readBufferAsImage( controlState.elapsedTime /*   now()  */ /* - controlState.deadTime */ /* t */ ) {
              if let nnn = NSImage.init(ciImage: xx.oriented(.down)) {
                  let _ = nn = AnyView(Image(nsImage: nnn).resizable().scaledToFit())
            }
            }

            StillView(elapsedTime: controlState.elapsedTime, nn: nn,
                      location: location,
                      shaderType: shaderType, shaderFn: shaderFn, args: getArgs())
            .background(Color.black)
            .gesture(myGesture)

            let _ = controlState.doStep()
          }.onChange(of: args.floatArgs, initial: true) {
            argArgs = getArgs()
          }.onChange(of: args.otherImage, initial: true) {
            argArgs = getArgs()
          }


          .clipped()

          ControlView(controlState: $controlState)
            .onChange(of: controlState.paused, initial: true) { ov, nv in
              if nv { // paused
                // FIXME: make startVideo / stopVideo methods on protocol Backgroundable
                (args.background as? (any VideoStream))?.stopVideo()
              } else {
                (args.background as? (any VideoStream))?.startVideo()
              }
            }
        }
                  )





      }
    }
  
}
