// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import AVFoundation

extension AVAsset {
  public func getThumbnailImage() async -> CGImage {
    let videoGen = AVAssetImageGenerator.init(asset: self )
    videoGen.requestedTimeToleranceBefore = CMTime(value: 1, timescale: 10)
    videoGen.requestedTimeToleranceAfter = CMTime(value: 1, timescale: 10)
    videoGen.appliesPreferredTrackTransform = true
    let imageGenerator = videoGen
    
    let z = CMTime(seconds: 10, preferredTimescale: 60)

    do {
//      let thumb = try imageGenerator.copyCGImage(at: z , actualTime: &actualTime)
      let thumb = try await imageGenerator.image(at: z)
      return thumb.image
    } catch let error {
      print("getting thumbnail ", error)
      return NSImage().cgImage
    }
  }
}
