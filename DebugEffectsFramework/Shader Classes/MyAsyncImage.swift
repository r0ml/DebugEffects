// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import SwiftUI

struct MyAsyncImage : View {
  // The image being displayed: initialized to a placeholder (currently empty)
  @State var myim : NSImage = NSImage()
  var closure : (
    () async -> NSImage)
  
  var body : some View {
    Image(nsImage: myim).resizable().scaledToFit()
      .task {
        self.myim = await closure()
      }
//      .background(Color.orange)
  }
}
