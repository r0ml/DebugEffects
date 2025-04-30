// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import SwiftUI
import MetalKit
import SceneKit

public struct MetalView<T : Instantiatable> : NSViewRepresentable {
  public var delegate : MetalDelegate<T>
  
  public init(delegate d: MetalDelegate<T>) {
    self.delegate = d
  }
  
  public func makeNSView(context: Context) -> MTKView {
    let mtkView = MTKView()
    mtkView.preferredFramesPerSecond = 60
    
    mtkView.wantsLayer = true
    let ml = mtkView.layer!
//    ml.contentsScale = 1 -- does nothing
    
    // FIXME: is this why the colors don't match
//    ml.backgroundColor = (context.environment.colorScheme == .dark ? XColor.darkGray : XColor.lightGray).cgColor
    ml.backgroundColor = NSColor.black.cgColor

    ml.opacity = 1.0
    
    mtkView.sampleCount = multisampleCount

    mtkView.colorPixelFormat = theOtherPixelFormat
    
    // FIXME: this needs to be added in if depth needed?
    // mtkView.depthStencilPixelFormat = .depth32Float
    
    mtkView.delegate = delegate
    mtkView.device = device
    mtkView.preferredFramesPerSecond = 60

    // If I don't do this, I can't debug
    mtkView.framebufferOnly = false
    return mtkView
  }
  
  public func updateNSView(_ mtkView: MTKView, context: Context) {
//    log.debug("\(#function) \(self.delegate.shader.name)")
    let oldds = (mtkView.delegate as? MetalDelegate<T>)?.drawableSize
    mtkView.delegate = delegate
    (mtkView.delegate as? MetalDelegate<T>)?.drawableSize = oldds
  }
  
 public typealias NSViewType = MTKView
}

