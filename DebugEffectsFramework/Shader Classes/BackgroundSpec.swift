// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import SwiftUI

public class BackgroundSpec : Equatable {
  private var color : CGColor?
  private var image : NSImage?
  private var video : (any VideoStream)?
  
  public init(_ c : CGColor) {
    color = c
  }
  
  public init(_ i : NSImage) {
    image = i
  }
  
  public init(_ v : any VideoStream) {
    video = v
  }
  
  public static func == (lhs: BackgroundSpec, rhs: BackgroundSpec) -> Bool {
    if lhs.color != nil && rhs.color != nil {
      return lhs.color! == rhs.color!
    }
    if lhs.image != nil && rhs.image != nil {
      return lhs.image! == rhs.image!
    }
    
    if lhs.video != nil && rhs.video != nil {
      if lhs.video is WebcamSupport && rhs.video is WebcamSupport {
        return true
      }
      return lhs.video as? VideoSupport == rhs.video as? VideoSupport
    }
    return false
  }
  
 @MainActor public var view : AnyView {
    if let c = color {
      return AnyView( Color(cgColor: c).edgesIgnoringSafeArea(.all) )
    } else if let i = image {
      return AnyView( Image(nsImage: i).resizable().scaledToFit().edgesIgnoringSafeArea(.all) )
    } else if let v = video {
      return AnyView( MyAsyncImage {
        let im = await (v as! VideoSupport).getThumbnail()
        let imx = NSImage(cgImage: im, size: NSSize(width: im.width, height: im.height))
        return imx }
    )
    } else {
      return AnyView(Rectangle())
//      fatalError("video not implemented yet")
    }
  }
  
  public var videoStream : (any VideoStream)? { video }
  public var bgColor : CGColor? { color }
  public var nsImage : NSImage? { image }
}
