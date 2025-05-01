// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import AppKit
import MetalKit
import os

import SwiftUI


extension NSImage : @unchecked Sendable {

  var cgImage: CGImage {
    get {
      let imageData = self.tiffRepresentation!
      let source = CGImageSourceCreateWithData(imageData as CFData, nil).unsafelyUnwrapped
      let maskRef = CGImageSourceCreateImageAtIndex(source, Int(0), nil)
      return maskRef.unsafelyUnwrapped
    }
  }
  
  public func _getTexture(_ t : MTKTextureLoader, flipped: Bool = true, mipmaps : Bool = true) -> MTLTexture? {

    // This business fixed the problem with having a gray-scale png texture

    let sourceImageRep = self.tiffRepresentation!

    // FIXME: is this whey the colors are different?
    //    let targetColorSpace = NSColorSpace.deviceRGB
    // *** WARNING *** sRGB didn't work here, but displayP$ did!
    let targetColorSpace = NSColorSpace.displayP3
    let targetImageRep = NSBitmapImageRep(data: sourceImageRep)?.converting(to: targetColorSpace, renderingIntent:NSColorRenderingIntent.perceptual)!
    let data = targetImageRep!.tiffRepresentation!

    do {
      let j = try t.newTexture(data: data,
                               options: [
                                .textureUsage : NSNumber(value: MTLTextureUsage.shaderRead.rawValue + MTLTextureUsage.renderTarget.rawValue),
                                .origin :  flipped ? MTKTextureLoader.Origin.topLeft : MTKTextureLoader.Origin.bottomLeft,
                                //                                .SRGB: NSNumber(value: true),
                                
                                // FIXME: how to make this an option
                                  .generateMipmaps : NSNumber(value: mipmaps)
                               ]
      )
      return j
    } catch let e {
      os_log("getting texture: %s", type: .error, e.localizedDescription)
    }
    return nil
  }
  
  func createTextureWithBlackBorder(_ device: MTLDevice) -> MTLTexture? {
      let originalSize = self.size
      let newSize = NSSize(width: originalSize.width + 2, height: originalSize.height + 2)
      
      // 1. Create a bitmap context
      guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
          print("Failed to create color space")
          return nil
      }
      
      let bytesPerPixel = 4
      let bitsPerComponent = 8
      let bytesPerRow = Int(newSize.width) * bytesPerPixel
      
      var rawData = [UInt8](repeating: 0, count: Int(newSize.width * newSize.height) * bytesPerPixel)
      
      guard let context = CGContext(
          data: &rawData,
          width: Int(newSize.width),
          height: Int(newSize.height),
          bitsPerComponent: bitsPerComponent,
          bytesPerRow: bytesPerRow,
          space: colorSpace,
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      ) else {
          print("Failed to create CGContext")
          return nil
      }
      
      // 2. Fill background with black (this becomes the 1-pixel border)
      context.setFillColor(NSColor.black.cgColor)
      context.fill(CGRect(origin: .zero, size: CGSize(width: newSize.width, height: newSize.height)))
      
      // 3. Draw the original image centered (offset by 1 pixel)
      guard let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil) else {
          print("Failed to get CGImage from NSImage")
          return nil
      }
      
      context.draw(cgImage, in: CGRect(x: 1, y: 1, width: originalSize.width, height: originalSize.height))
      
      // 4. Create a Metal texture
      let descriptor = MTLTextureDescriptor.texture2DDescriptor(
          pixelFormat: .rgba8Unorm,
          width: Int(newSize.width),
          height: Int(newSize.height),
          mipmapped: false
      )
      descriptor.usage = [.shaderRead, .shaderWrite]
      
      guard let texture = device.makeTexture(descriptor: descriptor) else {
          print("Failed to create MTLTexture")
          return nil
      }
      
      // 5. Upload pixel data to Metal
      rawData.withUnsafeBytes { bufferPointer in
          texture.replace(
              region: MTLRegionMake2D(0, 0, Int(newSize.width), Int(newSize.height)),
              mipmapLevel: 0,
              withBytes: bufferPointer.baseAddress!,
              bytesPerRow: bytesPerRow
          )
      }
      
      return texture
  }

  
  
  @MainActor func getHalfFloatTexture(_ t : MTKTextureLoader, width: Int, height: Int) -> MTLTexture? {
      // 1. Create a texture descriptor
      let descriptor = MTLTextureDescriptor()
      descriptor.textureType = .type2D
      descriptor.pixelFormat = .rgba16Float   // 16-bit float per channel
      descriptor.width = width
      descriptor.height = height
      descriptor.usage = [.shaderRead] // Allow reading/writing in shaders

      // 2. Create the texture
      return device.makeTexture(descriptor: descriptor)
  }
  
  @MainActor public convenience init?(ciImage: CIImage) {
    guard let cgImg = TheCIContext.createCGImage(ciImage.oriented(.downMirrored), from: ciImage.extent, format: .ARGB8, colorSpace: CGColorSpace.init(name: CGColorSpace.genericRGBLinear)) else { return nil }
    self.init(cgImage: cgImg, size: CGSize(width: cgImg.width, height: cgImg.height))
  }

  @MainActor public convenience init?(mtlTexture: MTLTexture) {
    //    let cgcs = CGColorSpace.init(name: CGColorSpace.extendedLinearSRGB)!
    let cgcs = CGColorSpace.init(name: CGColorSpace.genericRGBLinear)
    guard let ciImage = CIImage.init(
      mtlTexture: mtlTexture,
      options: [.colorSpace : cgcs as Any])
    else { return nil }
    guard let cgImg = TheCIContext.createCGImage(
      ciImage.oriented(.downMirrored) ,
      from: ciImage.extent, format: .BGRA8,
      colorSpace: cgcs)
    else { return nil }
    self.init(cgImage: cgImg, size: CGSize(width: cgImg.width, height: cgImg.height))

  }

  public func resizedImage(withMaximumSize size : CGSize) -> NSImage? {
    let original_width  = CGFloat(self.size.width)
    let original_height = CGFloat(self.size.height)
    let width_ratio = size.width / original_width
    let height_ratio = size.height / original_height
    let scale_ratio = width_ratio < height_ratio ? width_ratio : height_ratio
    return self.drawImageInBounds( CGRect(x: 0, y: 0, width: round(original_width * scale_ratio), height: round(original_height * scale_ratio)))
  }

  public func drawImageInBounds( _ bounds : CGRect) -> NSImage? {
    return self
  }

  func writePNG(toURL url: URL) {
    guard let data = tiffRepresentation,
          let rep = NSBitmapImageRep(data: data),
          let imgData = rep.representation(using: .png, properties: [.compressionFactor : NSNumber(floatLiteral: 1.0)]) else {

      Swift.print("\(self) Error Function '\(#function)' Line: \(#line) No tiff rep found for image writing to \(url)")
      return
    }

    do {
      try imgData.write(to: url)
    } catch let error {
      Swift.print("\(self) Error Function '\(#function)' Line: \(#line) \(error.localizedDescription)")
    }
  }
}

let emptyImage = NSImage(named: "camera")!.cgImage(forProposedRect: nil, context: nil, hints: nil)!

