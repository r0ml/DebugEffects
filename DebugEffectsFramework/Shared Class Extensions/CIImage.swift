// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import CoreImage
import AppKit

@MainActor let TheCIContext = CIContext(mtlDevice: device)

extension CIImage {
  @MainActor public var nsImage : NSImage? {
    get {
      guard let cgImg = TheCIContext.createCGImage(self.oriented(.downMirrored), from: self.extent) else { return nil }
      return NSImage(cgImage: cgImg, size: CGSize(width: cgImg.width, height: cgImg.height))
    }
  }

  @MainActor public var cgImage : CGImage? {
    get {
      return TheCIContext.createCGImage(self.oriented(.downMirrored), from: self.extent, format: .ARGB8, colorSpace:
        CGColorSpace.init(name: CGColorSpace.sRGB)) 
    }
  }

}
