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
      "toSepia", "nightVision", "nightVision02",
      "monochromeFade", "colorCycle", "derivatives", "vignette01",
      "imageCel", "bevelled", "money", "wall03",
      "dotty", "emboss", "emboss02", "spotlight01", "grate",
      "shutter",
    ] {
      self.register(StitchDefinition<NoArgs>(i, .color, background: BackgroundSpec(NSImage(named: "london_tower")!)))
    }
  }
}

