// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import SwiftUI
import DebugEffectsFramework

@main
struct SwiftUIMetalApp: App {
    var body: some Scene {
          WindowGroup {
            DebugEffectsMainView().navigationTitle("SwiftUIMetal Window")
          }
    }
}
