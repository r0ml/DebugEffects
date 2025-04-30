// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import AVFoundation
import CoreMedia
import MetalKit
import os
import SwiftUI

public class WebcamSupport : NSObject, VideoStream {
  private var frameTexture : MTLTexture? = nil
  private var region : MTLRegion = MTLRegion()
  
  private var permissionGranted = false
  private let captureSession = AVCaptureSession()
  private let context = CIContext()
  private let name : String
  private var im : CIImage = CIImage()

  public func getAspectRatio() async -> CGFloat? {
    return nil
  }


  @MainActor public init(camera n : String) {
    name = n
    super.init()
    checkPermission()
  }
  
  public func readBufferAsTexture(_ nVSync : TimeInterval) -> MTLTexture? {
    return self.frameTexture
  }
  
  public func readBufferAsImage( _ nVSync : TimeInterval) -> CIImage? {
    return im
//    fatalError("readBufferAsImage not implmented yet")
  }

  public func startVideo() {
    self.configureSession()
    captureSession.startRunning()
  }

  @MainActor public func stopVideo() {
    captureSession.stopRunning()
  }


}

extension WebcamSupport :  AVCaptureVideoDataOutputSampleBufferDelegate {
  
  private func checkPermission() {
    switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
    case .authorized:
      permissionGranted = true
    case .notDetermined:
      requestPermission()
    default:
      permissionGranted = false
    }
  }
  private func requestPermission() {
    AVCaptureDevice.requestAccess(for: AVMediaType.video) { granted in
      self.permissionGranted = granted
    }
  }
  
  @MainActor private func configureSession() {
    if permissionGranted,
      let captureDevice = selectCaptureDevice(),
      let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice) {
      
      captureSession.sessionPreset = .medium
      if captureSession.canAddInput(captureDeviceInput) { captureSession.addInput(captureDeviceInput) }
      
      let videoOutput = AVCaptureVideoDataOutput()
      // videoOutput.alwaysDiscardsLateVideoFrames = true
      videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer"))
      videoOutput.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)]

      let z = CMVideoFormatDescriptionGetDimensions(captureDevice.activeFormat.formatDescription)
//      print(z)

      let mtd = MTLTextureDescriptor.texture2DDescriptor(pixelFormat:
        theOtherPixelFormat, width: Int(z.width), height: Int(z.height), mipmapped: false)
      let tx = device.makeTexture(descriptor: mtd)
      tx?.label = "webcam frame"
      tx?.setPurgeableState(.keepCurrent)
      self.frameTexture = tx
      region = MTLRegionMake2D(0, 0, mtd.width, mtd.height)

      if captureSession.canAddOutput(videoOutput) { captureSession.addOutput(videoOutput) }
      captureSession.commitConfiguration()
    }
  }
  
  @MainActor private func selectCaptureDevice() -> AVCaptureDevice? {
    let j = CameraPicker.getDevice(name)
    return j
  }
  
  public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
    let ciimage = CIImage(cvPixelBuffer: pixelBuffer)
    self.im = ciimage

//    if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
      if let tx = self.frameTexture {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        if let dd = CVPixelBufferGetBaseAddress(pixelBuffer) {
          tx.replace(region: region, mipmapLevel: 0, withBytes: dd, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer))
          CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
      }
    
  }
}

/// The drop down list for macOS to select the camera in the event that there are multiple cameras available.
public struct CameraPicker : View {
  @Binding var cameraName : String

  public init(cameraName: Binding<String>) {
    _cameraName = cameraName
  }

  public var body : some View {

    Picker(selection: $cameraName, label: Text("Choose a camera") ) {
      ForEach( Self.cameraList, id: \.self) { cn in
        Text(cn)
      }
    }
  }

  static public var _cameraList : [AVCaptureDevice] { get {
    return AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera, .external], mediaType: .video, position: AVCaptureDevice.Position.unspecified).devices
  } }

  static var cameraList : [String] { get {
    return Self._cameraList.map(\.localizedName)
  }}

  static func getDevice(_ s : String) -> AVCaptureDevice? {
    let list = CameraPicker._cameraList
    if let videoCaptureDevice = list.first(where : { $0.localizedName == s })  {
      return videoCaptureDevice
    } else {
      if let a = list.first {
        return a
      }
    }
    return nil
  }

}

