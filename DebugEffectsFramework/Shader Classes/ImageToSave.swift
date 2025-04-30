// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import SwiftUI

@Observable public class ImageToSave {
  public var grabImage : Bool = false
  public var theImage : NSImage?
  public var url : URL?
  
  public init() {
  }
}
