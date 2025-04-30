// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import CoreImage
import AVFoundation

/// A VideoStream is either a VideoSupport (for playing video files)  or a WebcamSupport (for playing the live camera)
public protocol VideoStream : Equatable {
  @MainActor func readBufferAsImage(_ nVSync : TimeInterval) -> CIImage?
  @MainActor func readBufferAsTexture(_ nVSync : TimeInterval) -> MTLTexture?
  @MainActor func stopVideo()
  @MainActor func startVideo()
  @MainActor func getAspectRatio() async -> CGFloat?
}

