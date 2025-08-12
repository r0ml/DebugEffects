// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import Foundation
import MetalKit

@MainActor public let commandQueue = device.makeCommandQueue()!
@MainActor public let textureLoader = MTKTextureLoader(device: device)

public let thePixelFormat = MTLPixelFormat.bgra8Unorm // could be bgra8Unorm_srgb

// FIXME: is this why the colors don't match
// public let theOtherPixelFormat = MTLPixelFormat.bgra8Unorm_srgb
public let theOtherPixelFormat = MTLPixelFormat.bgra8Unorm

public let multisampleCount = 1

@MainActor public let device = MTLCreateSystemDefaultDevice()!
let metalURL = {
  let k = Bundle.main
  let c = k.urls(forResourcesWithExtension: "bundle", subdirectory: nil) ?? []
  for bb in c {
    let b = Bundle(url: bb)!
    print("bundle: \(b.bundleURL)")
    if let bb = b.url(forResource: "Merged", withExtension: "metallib") {
      return bb
    }
  }
  fatalError("no Merged metallib")
}()
@MainActor public let metalLibrary = try! device.makeLibrary(URL:metalURL)
