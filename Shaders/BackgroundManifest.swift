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
      "monochromeFade", "colorCycle", "vignette01",
      "imageCel", "bevelled", "money", "wall03",
      "dotty", "emboss", "emboss02", "spotlight01", "grate",
      "shutter",
    ] {
      self.register(StitchDefinition<NoArgs>(i, .color, background: BackgroundSpec(NSImage(named: "london_tower")!)))
    }
    
    self.register(StitchDefinition<Derivatives>("derivatives", .color, background: BackgroundSpec(VideoSupport(url: Bundle.main.resourceURL!.appendingPathComponent("diving.m4v")))))
  }
  
  struct Derivatives : ArgSetter {
    enum Variant : Int, CaseIterable, Identifiable {
      case luminance
      case emboss
      case unchanged
      
      var id: Int { rawValue }
    }
    struct Args : Instantiatable {
      var variant : Variant = .luminance
    }

    @Bindable var args : ArgProtocol<Args>

    var body : some View {
      VStack {
        Picker(selection: $args.floatArgs.variant, label: Text("Variant")) {
          ForEach(Variant.allCases) {i in
            Text("\(i)").tag(i)
          }
          }.pickerStyle(.segmented)
        JustImage(args: args)
      }
    }
  }

}

