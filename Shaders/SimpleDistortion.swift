// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import DebugEffectsFramework
import AVFoundation

public struct SimpleDistortionManifest : Manifest {
  
  public var registered = [String:any AnyStitchDefinition]()
  public var libnam = "SimpleLayers"
  
  /// Dictionary with section names as keys and array of scene views as values
  @MainActor public init() {

    for i in [
      "tunnel01", "melting", "water_wave_ripples_distort",
      "verbose_raytrace_quad", "tunnel_effect", "vortex92",
      "spiral92", "tunnel94", "tunnel95", "kaleidoscope_polar_repeat",
      "easy_sphere_distortion", "magnifier", "fresnel",
    ] {
      self.register(StitchDefinition<NoArgs>(i, .distort, background: BackgroundSpec(NSImage(named: "london_tower")!)))
    }
  }
}
