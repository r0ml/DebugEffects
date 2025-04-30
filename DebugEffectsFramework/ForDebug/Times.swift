// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import Foundation

public func now() -> Double {
  return ProcessInfo.processInfo.systemUptime
}

// Keeps track of the virtual time in the shader timeline (because of pauses and restarts)
public actor Times {
  public var currentTime : Double
  var lastTime : Double
  var startTime : Double

  public init() {
    let t = now()
    currentTime = t
    lastTime = t
    startTime = t
  }
  
  public func play() {
    currentTime = now()
    let paused = currentTime - lastTime
    startTime += paused
    lastTime += paused
  }
  
  public func setTime(_ d : Double) {
    currentTime = startTime + d
  }
  
  public func rewind() {
    let n = now()
    lastTime = n
    currentTime = n
    startTime = n
  }
  
  public func updateTime() {
    lastTime = currentTime
    currentTime = now()
  }
  
  public func secondsSinceLast() -> Double {
    return currentTime - lastTime
  }
  
  public func secondsSinceStart() -> Double {
    return currentTime - startTime
  }
  
  public func advance(_ t : Double) {
    currentTime = now()
    let paused = currentTime - (lastTime + t)
    startTime += paused
    lastTime += paused
  }
}


