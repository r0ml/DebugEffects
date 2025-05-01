// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import Foundation
import DebugEffectsFramework
import AVFoundation

public struct BackgroundManifest : Manifest {
  
  public var registered = [String:any AnyStitchDefinition]()
  public var libnam = "Background"
  
  /// Dictionary with section names as keys and array of scene views as values
  @MainActor public init() {

    for i in [
      "solarization", "toSepia", "nightVision", "nightVision02",
      "monochromeFade", "mouse", "derivatives", "faded",
      "imageCel", "bevelled", "money", "wall03", "vignette03",
      "vignette04", "dotty", "emboss", "emboss02", "fading", "grate",
      "dither", "shutter", "shadows01",
    ] {
      self.register(StitchDefinition<NoArgs>(i, .color, background: BackgroundSpec(NSImage(named: "london_tower")!)))
    }
  }
}

