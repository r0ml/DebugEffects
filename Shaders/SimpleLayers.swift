// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import Foundation
import DebugEffectsFramework
import AVFoundation

public struct SimpleLayersManifest : Manifest {
  
  public var registered = [String:any AnyStitchDefinition]()
  public var libnam = "SimpleLayers"
  
  /// Dictionary with section names as keys and array of scene views as values
  @MainActor public init() {

    for i in [
      "lights03", "rain06", "rosace21",
      "water92", "aberration02", "isovalues",
      "vhs02", "postProcess",
      "deform02", "laplace", "infinite", "sliced",
      "tunnel92", "water93",
      "blackHole", "vhsfilter", "pressure",
    ] {
      self.register(StitchDefinition<NoArgs>(i, .layer, background: BackgroundSpec(NSImage(named: "london_tower")!)))
    }
  }
}
