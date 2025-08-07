// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import SwiftUI

struct MetalWithArgs<T : ArgSetter> : View {
  var metalDelegate : MetalDelegate<T.Args>
  
  @State var aspect : CGFloat? = nil
  
  init(metalDelegate: MetalDelegate<T.Args>) {
    self.metalDelegate = metalDelegate
//    metalDelegate.controlState = $controlState
  }

  var body : some View {
    VStack {
      GeometryReader { g in
        VStack {
          MetalView<T.Args>(delegate: metalDelegate)
            .aspectRatio( aspect ?? (g.size.width / g.size.height), contentMode: .fit)
          // FIXME: this needs to be done in a separate task because getting the aspect ration of a
          // video is async.  If the aspect ratio were computed when loaded, it would be available here.
            .task { aspect = await self.getAspectRatio() }
        }
      }.aspectRatio(aspect, contentMode: .fit)
      .clipped()
      
//      ControlView(controlState: $controlState)
    }
    .onChange(of: metalDelegate.args.floatArgs, initial: true) {
        metalDelegate.setArgBuffer(metalDelegate.args.floatArgs)
    }
    /*
    .onChange(of: args.otherImage, initial: true) {
      metalDelegate.args.otherImage = args.otherImage
    }
    .onChange(of: args.background, initial: true) {
      metalDelegate.args.background = args.background
    }
     */
//    .task {
//      metalDelegate.controlState = $controlState
//    }
    
  }

  func getAspectRatio() async -> CGFloat? {
    if let m = metalDelegate.args.background?.nsImage {
      let z = m.size.width / m.size.height
      return z
    } else if let v = await (metalDelegate.args.background?.videoStream)?.getAspectRatio() {
      return v
    }
    return nil
  }
}
