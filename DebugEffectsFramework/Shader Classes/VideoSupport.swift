// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import MetalKit
import AVFoundation
import os
import CoreVideo

// import MediaToolbox
import Accelerate
import SwiftUI


public class VideoSupport : VideoStream, Equatable, @unchecked Sendable {
  nonisolated public func getAspectRatio() async -> CGFloat? {
    let v = self.video
    do {
      let sz = try await v.resolutionSizeForLocalVideo()
      return sz.width / sz.height
    } catch( let e) {
      print("failed to get video size: \(e.localizedDescription)")
      return nil
    }
  }

  public static func == (lhs : VideoSupport, rhs : VideoSupport) -> Bool {
    return lhs.url == rhs.url
  }
  
  private var video : AVAsset
  public var url : URL

  // FIXME: make private again?

  private var reader : AVAssetReader?
  private var player : AVQueuePlayer
  private var textureQ = DispatchQueue(label: "videoTextureQ")
  private var looper : AVPlayerLooper
  private var observation: NSKeyValueObservation?
  private var thumbnail : CGImage?

  private var frameTexture : MTLTexture? = nil
  private var region : MTLRegion = MTLRegion()

  var observer : NSObject?

  deinit {
    print("deinit videostream")
    player.pause()
  }

  @MainActor public init( url u : URL ) {
    url = u
    video = AVURLAsset(url: u)
    player = AVQueuePlayer()
    let pi = AVPlayerItem.init(asset: video )
    looper = AVPlayerLooper(player: player, templateItem: pi)
    doInit(asset: video)
  }

  @MainActor public init( asset v : AVURLAsset ) {
    url = v.url
    video = v
    player = AVQueuePlayer()
    let pi = AVPlayerItem.init(asset: video )
    looper = AVPlayerLooper(player: player, templateItem: pi)
    doInit(asset: video)
  }

  private func doInit(asset video : AVAsset) {
    let ll = self.looper
    observation = looper.observe(\AVPlayerLooper.status, options: .new) { object, change in
      let status = ll.status
      // Switch over status value
      // print("doInit status = \(status)")
      switch status {
        case .ready:
          // Player item is ready to play.
          Task { @MainActor in
            let attributes = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32BGRA)]
            ll.loopingPlayerItems.forEach { pis in
              let playerItemVideoOutput: AVPlayerItemVideoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: attributes)

              pis.add(playerItemVideoOutput)
            }
          }
        case .cancelled:
          // Player item failed. See error.
          break
        case .unknown:
          break
          // Player item is not yet ready.
        default:
          break
      }
    }
  }

  @MainActor public func pause() {
    player.pause()
  }

/*  @MainActor public func start() {
    print("start \(url)")
    player.play()
  }
*/
  
  var loop : Bool = false

  public func startVideo() {
    //    print("start")
    let v = self.video
    Task {
      try? await self.configure(v)
      print("startVideo \(url)")
      player.play()
    }
  }

  public func stopVideo() {
    print("stopVideo \(url)")
    player.pause()
  }

  func configure(_ v : AVAsset) async throws {
    let siz = try await v.resolutionSizeForLocalVideo()

    let mtd = MTLTextureDescriptor.texture2DDescriptor(pixelFormat:
                                                        theOtherPixelFormat, width: Int(siz.width),
                                                       height: Int(siz.height), mipmapped: false)
    mtd.storageMode = .shared
    let tx =  MTLCreateSystemDefaultDevice()!.makeTexture(descriptor: mtd)
    tx?.label = "video frame"
    tx?.setPurgeableState(.keepCurrent)

    self.frameTexture = tx
    self.region = MTLRegionMake2D(0, 0, mtd.width, mtd.height)
  }




  @MainActor private func getPixelsAsImage(_ currentTime : CMTime) -> CIImage? {
    var ot : CMTime = .zero
    if let pci = player.currentItem,
       let pivo = pci.outputs.first as? AVPlayerItemVideoOutput,
       
        //
       // let currentTime = pivo.itemTime(forHostTime: nextVSync)
        
        // pivo.hasNewPixelBuffer(forItemTime: currentTime),
        let pixelBuffer = pivo.copyPixelBuffer(forItemTime: player.currentTime(), itemTimeForDisplay: &ot)  {
       // print(currentTime, ot)
      
      let ci = CIImage(cvPixelBuffer: pixelBuffer)
      return ci
    }
    return nil
  }

  @MainActor func getPixelsAsTexture(_ currentTime : CMTime) -> MTLTexture? {
    let pivo = player.currentItem!.outputs[0] as! AVPlayerItemVideoOutput
    // let currentTime = pivo.itemTime(forHostTime: nextVSync)

    if pivo.hasNewPixelBuffer(forItemTime: currentTime),
       let pixelBuffer = pivo.copyPixelBuffer(forItemTime: currentTime, itemTimeForDisplay: nil)  {

      var vib = vImage_Buffer()
      var format = vImage_CGImageFormat(
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        colorSpace: nil,
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
        version: 0,
        decode: nil,
        renderingIntent: .perceptual)

      let _ /*error*/ = vImageBuffer_InitWithCVPixelBuffer(&vib,
                                                           &format,
                                                           pixelBuffer,
                                                           vImageCVImageFormat_CreateWithCVPixelBuffer(pixelBuffer).takeUnretainedValue(),
                                                           nil,
                                                           vImage_Flags(kvImageNoFlags))

      // vImageVerticalReflect_ARGB8888(&vib, &vib, vImage_Flags(kvImageDoNotTile) )


      // FIXME: can I defer creation of the
      // texture to here?  and only create it on the first frame?

      /*
       let mtd = MTLTextureDescriptor.texture2DDescriptor(pixelFormat:
       thePixelFormat, width:CVPixelBufferGetWidth(pixelBuffer),
       height: CVPixelBufferGetHeight(pixelBuffer), mipmapped: false)

       let tx = device.makeTexture(descriptor: mtd)
       tx?.label = "video frame"
       let region = MTLRegionMake2D(0, 0, mtd.width, mtd.height)
       */

      if let tx = self.frameTexture {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        if let dd = CVPixelBufferGetBaseAddress(pixelBuffer) {
          tx.replace(region: region, mipmapLevel: 0, withBytes: dd, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer))
          CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly);
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        return tx
      }
    }
    return self.frameTexture
  }

  public func readBufferAsImage(_ nVSync : TimeInterval) -> CIImage? /* NSImage? */ {
    let nextVSync = nVSync

    //    print(player.timeControlStatus.rawValue.description)

    //    if player.timeControlStatus == .paused {
    //      player.play()
    //      print("paused")
    //      nextVSync += 10
    //      return nil
    //    } else
    if player.timeControlStatus == .waitingToPlayAtSpecifiedRate {
      return nil
    }
    //    else if player.timeControlStatus != .playing {
    //      player.play()
    //      return nil
    //    }

    guard looper.loopingPlayerItems.count > 0 else {
      return nil
    }

    //    if let pci = player.currentItem {
    //     let pcio = pci.outputs.first {
    //     let pivo = pcio as! AVPlayerItemVideoOutput

    //   let currentTime = pivo.itemTime(forHostTime: nextVSync)

    //    player.seek(to: currentTime)

//    print("nextVSync \(nextVSync)")
    let cmt = CMTime(seconds: nextVSync, preferredTimescale: 60)
//    print("cmt \(cmt)")
    if let tx = getPixelsAsImage( cmt /* currentTime */ ) {
      //    self.myTexture = tx
 //     print("got texture")
      return tx
    } else {
//      print("nil")
      return nil
    }

  }


  @MainActor public func readBufferAsTexture(_ nVSync : TimeInterval) -> MTLTexture? {
    var nextVSync = nVSync

    if player.timeControlStatus == .paused {
      Task {
        await MainActor.run {
          print("readBuffer play \(url)")
          player.play()
        }
      }
      nextVSync += 10
      return nil
    }

    if player.timeControlStatus != .playing {
      Task {
        await MainActor.run {
          print("readBuffer play2 \(url)")
          player.play()
        }
      }
      return nil
    }

    guard looper.loopingPlayerItems.count > 0 else {
      return nil
    }

    let pivo = player.currentItem!.outputs[0] as! AVPlayerItemVideoOutput
    let currentTime = pivo.itemTime(forHostTime: nextVSync)

    // FIXME: how to get video into SwiftUI Shader?

    let tx = getPixelsAsTexture(currentTime)
    self.frameTexture = tx
    return tx

  }






  // FIXME: I could cache the thumbnail for future reference
  func getThumbnail() async -> CGImage {
    if let t = thumbnail {
      return t
    }
    let k = await video.getThumbnailImage()
    thumbnail = k
    return k
  }


}


extension AVAsset {
  nonisolated func resolutionSizeForLocalVideo() async throws -> CGSize {
    var unionRect = CGRect.zero
    for track in try await self.loadTracks(withMediaCharacteristic: .visual)  {
      let (ns, pt) = try await track.load(.naturalSize, .preferredTransform)
      let trackRect = CGRect(x: 0, y: 0, width:
                              ns.width, height:
                              ns.height).applying(pt)
      unionRect = unionRect.union(trackRect)

    }
    return unionRect.size
  }
}
