// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

/** This implements the support for recording the animation generated on the metalView by the shaders */
import Foundation
import AVFoundation


public class MetalVideoRecorder {
  var isRecording = false
  var recordingStartTime = TimeInterval(0)

  public var assetWriter: AVAssetWriter
  private var assetWriterVideoInput: AVAssetWriterInput
  private var assetWriterPixelBufferInput: AVAssetWriterInputPixelBufferAdaptor

  public init?(outputURL url: URL, size: CGSize) {
    do {
      print("url \(url.absoluteString), size \(size)" )
      assetWriter = try AVAssetWriter(outputURL: url, fileType: AVFileType.m4v)
    } catch {
      return nil
    }

    let outputSettings: [String: Any] = [ AVVideoCodecKey : AVVideoCodecType.h264 ,
                                          AVVideoWidthKey : NSNumber(value: Float(size.width)),
                                         AVVideoHeightKey : NSNumber(value: Float(size.height)) ]

    // Are the output settings OK?
    assetWriterVideoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: outputSettings)
    
    // do I need to set mediaTimeScale?
    // assetWriterVideoInput.mediaTimeScale = CMTimeScale(bitPattern: 600)
    
    assetWriterVideoInput.expectsMediaDataInRealTime = true

    let sourcePixelBufferAttributes: [String: Any] = [
      kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_32BGRA),
      kCVPixelBufferWidthKey as String : NSNumber(value: Float(size.width)) ,
      kCVPixelBufferHeightKey as String : NSNumber(value: Float(size.height)) ]

    // can I default the sourcePixelBufferAttributes?
    assetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterVideoInput,
                                                                       sourcePixelBufferAttributes: sourcePixelBufferAttributes /* nil */ )

    if assetWriter.canAdd(assetWriterVideoInput) {
      assetWriter.add(assetWriterVideoInput)
    } else {
      fatalError("why can't I add the video input to the asset writer?")
    }
  }

  public func startRecording() {
    assetWriter.startWriting()
    assetWriter.startSession(atSourceTime: .zero)

    recordingStartTime = CACurrentMediaTime()
    isRecording = true
  }

  public func endRecording(_ completionHandler: @Sendable @escaping () -> ()) {
    isRecording = false

    assetWriterVideoInput.markAsFinished()
    assetWriter.finishWriting(completionHandler: completionHandler)
  }

  public func writeFrame(forTexture texture: MTLTexture) {
    if !isRecording {
      return
    }

    while !assetWriterVideoInput.isReadyForMoreMediaData {}

  
    /*
    guard let pixelBufferPool = assetWriterPixelBufferInput.pixelBufferPool else {
      print("Pixel buffer asset writer input did not have a pixel buffer pool available; cannot retrieve frame")
      return
    }

     */
    
    
    var maybePixelBuffer: CVPixelBuffer? = nil
    
    let status = CVPixelBufferCreate(kCFAllocatorDefault, texture.width, texture.height, kCVPixelFormatType_32BGRA, nil, &maybePixelBuffer )

    // zapped out because I couldn't get the pixel pool to work
//    let status  = CVPixelBufferPoolCreatePixelBuffer(nil, pixelBufferPool, &maybePixelBuffer)
    
    if status != kCVReturnSuccess {
      print("Could not get pixel buffer from asset writer input; dropping frame...")
      return
    }

    guard let pixelBuffer = maybePixelBuffer else {
      fatalError("failed to create pixel buffer")
      return }

    CVPixelBufferLockBaseAddress(pixelBuffer, [])
    let pixelBufferBytes = CVPixelBufferGetBaseAddress(pixelBuffer)!

    // let scale = 2
    // Use the bytes per row value from the pixel buffer since its stride may be rounded up to be 16-byte aligned
    let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
    let region = MTLRegionMake2D(0, 0, texture.width, texture.height)

    texture.getBytes(pixelBufferBytes, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)

    let frameTime = CACurrentMediaTime() - recordingStartTime
    let presentationTime = CMTime(seconds: frameTime, preferredTimescale: 240)
    
    let stat = assetWriterPixelBufferInput.append(pixelBuffer, withPresentationTime: presentationTime)
    if (!stat) {
      print("asset writer error : \(assetWriter.error)")
//      fatalError("what?")
    }
//    print("appending at time \(presentationTime): \(stat)")


    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
//    CVPixelBufferRelease(pixelBuffer)

  }
}
