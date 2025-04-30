// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import Foundation
import DebugEffectsFramework
import AVFoundation

public struct SimpleManifest : Manifest {
  
  public var registered = [String:any AnyStitchDefinition]()
  public var libnam = "Default"
  
  /// Dictionary with section names as keys and array of scene views as values
  @MainActor public init() {

    for i in [
      "oily1", "oily2", "fire", "flame2", "scissor", "wisps",
    ] {
      self.register(StitchDefinition<NoArgs>(i, .color))
    }
  }
}

struct JustToggle : ArgSetter {

  struct Args : Instantiatable {
    var toggle = false
  }

  var args : Binding<ArgProtocol<Args>>

  var body : some View {
        VStack {
          Toggle(isOn: args.floatArgs.toggle) { Text("Toggle") }
        }
      }
}
