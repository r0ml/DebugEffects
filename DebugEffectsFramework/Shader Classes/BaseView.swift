// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import SwiftUI

struct BaseView : View {
  var image : NSImage?

  var body : some View  {
    if let image {
      return AnyView(Image(nsImage: image).resizable().scaledToFit())
    } else {
      // FIXME: use an asset image to indicate no image?
      return AnyView(Rectangle().foregroundStyle(Color.purple))
    }
  }

}
