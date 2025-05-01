// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import SwiftUI

struct MetalWithArgs<T : ArgSetter> : View {
  var args : ArgProtocol<T.Args>
  var metalDelegate : MetalDelegate<T.Args>
  
  @State var controlState = ControlState()
  @State var aspect : CGFloat? = nil

  init(args: ArgProtocol<T.Args>, metalDelegate: MetalDelegate<T.Args>) {
    self.args = args
    self.metalDelegate = metalDelegate
//    metalDelegate.controlState = $controlState
  }

  var body : some View {
    VStack {
      GeometryReader { g in
        MetalView<T.Args>(delegate: metalDelegate)
          .aspectRatio(aspect ?? (g.size.width / g.size.height), contentMode: .fit)
          .task { aspect = await self.getAspectRatio() }
      }
      ControlView(controlState: $controlState)
    }.onChange(of: args.floatArgs, initial: true) {
      withUnsafePointer(to: self.args.floatArgs) {
        metalDelegate.argBuffer.contents().copyMemory(from: $0, byteCount: MemoryLayout.size(ofValue: args.floatArgs))
      }
    }.onChange(of: args.otherImage, initial: true) {
      metalDelegate.args.otherImage = args.otherImage
    }
    .task {
      metalDelegate.controlState = $controlState
    }
    
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
