// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import Foundation
import SceneKit

public final class Locations : @unchecked Sendable {
  var pointerLocation : CGPoint = CGPoint(x: 0.5, y: 0.5)
  var hitLocation : SIMD2<Float> = .zero
  
  private var queue = DispatchQueue(label: "locations", attributes: .concurrent)
  
  public init() {}
  
  public func setPointerLocation(_ c : CGPoint) {
    queue.sync(flags: .barrier) {
      pointerLocation = c
    }
  }
  
  public func setHitLocation(_ c : SIMD2<Float>) {
    hitLocation = c
    //  print(hitLocation)
  }
  
  public func getHitLocation() -> SIMD2<Float> {
    return queue.sync { self.hitLocation }
  }
}
