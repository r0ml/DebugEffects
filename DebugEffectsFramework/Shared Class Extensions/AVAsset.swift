// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import AVFoundation

extension AVAsset {
  public func getThumbnailImage() -> CGImage {
    let videoGen = AVAssetImageGenerator.init(asset: self )
    videoGen.requestedTimeToleranceBefore = CMTime(value: 1, timescale: 10)
    videoGen.requestedTimeToleranceAfter = CMTime(value: 1, timescale: 10)
    videoGen.appliesPreferredTrackTransform = true

    let imageGenerator = videoGen
    let z = CMTime(seconds: 10, preferredTimescale: 60)

    do {
      var actualTime : CMTime = CMTime.zero

      // FIXME: the replacement here uses a callback -- must figure out how to make it async
      let thumb = try imageGenerator.copyCGImage(at: z , actualTime: &actualTime)
      return thumb
    } catch let error {
      print("getting thumbnail ", error)
      return NSImage().cgImage
    }
  }
}
