// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import SwiftUI

public class BackgroundSpec : Equatable {
  public var color : CGColor?
  public var image : NSImage?
  public var video : (any VideoStream)?
  
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
  
  public var view : AnyView {
    if let c = color {
      return AnyView( Color(cgColor: c).edgesIgnoringSafeArea(.all) )
    } else if let i = image {
      return AnyView( Image(nsImage: i).resizable().scaledToFit().edgesIgnoringSafeArea(.all) )
    } else {
      fatalError("video not implemented yet")
    }
  }
}
