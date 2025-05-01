// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import Foundation
import MetalKit
import os
import AVFoundation
import SwiftUI

let sceneBufferId = 0
let perNodeDataId = 1

// Separating the variables into those that will be constant for the life of the object,
// and those which will be modified during the running of the shader.

@MainActor var lib = MTLCreateSystemDefaultDevice()!.makeDefaultLibrary()!

public struct GenericShader : @unchecked Sendable {
  
  var metadata : MTLRenderPipelineReflection!

  /// this is the clear color for alpha blending?
//  var clearColor : SIMD4<Float> = SIMD4<Float>( 0.16, 0.17, 0.19, 0.1 )
    var clearColor : SIMD4<Float> = SIMD4<Float>( 0, 0, 0, 1)

  let fragmentProgram : MTLFunction?
  let vertexProgram : MTLFunction?

  public let name : String

  // computed properties
  var fragmentName : String? { get { fragmentProgram?.name }}
  var vertexName : String? { get { vertexProgram?.name }}
  public var id : String {
    return name
  }

  var myName : String {
    get {
      return self.id
    }
  }
  // ===================================================================
  // Not initialized, but constant after being set.
    
  var pipelineState : MTLRenderPipelineState!
  

  // ======================================================================
  
  @MainActor public init(_ s : String) {
    
    name = s
    vertexProgram = lib.makeFunction(name: "flatVertexFn")!
    fragmentProgram = lib.makeFunction(name: s ) ?? (device.makeDefaultLibrary()!.makeFunction(name: "passthruFragmentFn")!)
  }
  
  func loadAction(_ : Int) -> MTLLoadAction {
    return .clear
  }
  
  // =============================================================================================================================================
  
  
  @MainActor mutating func setupRenderPipeline( /* _ topo : MTLPrimitiveTopologyClass,  ctrl: PipelineControl */) {
    // ============================================
    // this is the actual rendering fragment shader
    
    //    log.debug("\(#function)")
    let tpx : MTLPrimitiveTopologyClass = .triangle
    
    let psd = MTLRenderPipelineDescriptor()
    
    psd.vertexFunction = vertexProgram
    psd.fragmentFunction = fragmentProgram
    
    // FIXME: srgb or no
    psd.colorAttachments[0].pixelFormat = theOtherPixelFormat
    psd.isAlphaToOneEnabled = false
//    psd.colorAttachments[0].isBlendingEnabled = ctrl.isBlendingEnabled
    
    psd.colorAttachments[0].alphaBlendOperation = .add
    psd.colorAttachments[0].rgbBlendOperation = .add
    psd.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha // I would like to set this to   .one   for some cases
    psd.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
    psd.colorAttachments[0].destinationRGBBlendFactor =  .destinationAlpha //   doesBlend ? .destinationAlpha : .oneMinusSourceAlpha
    psd.colorAttachments[0].destinationAlphaBlendFactor = .destinationAlpha //   doesBlend ? .destinationAlpha : .oneMinusSourceAlpha
    
    psd.rasterSampleCount = multisampleCount
    psd.inputPrimitiveTopology = tpx
    
    if psd.vertexFunction != nil && psd.fragmentFunction != nil {
      do {
        let (res, _) = try device.makeRenderPipelineState(descriptor: psd, options: [.bindingInfo, .bufferTypeInfo ])
        pipelineState = res
        return
      } catch let er {
        os_log("also making render pipeline state: %s", type:.error, er.localizedDescription)
        return
      }
    } else {
      let n = self.name
      os_log("vertex or fragment function missing for \(n)")
    }
    return
  }


  @MainActor func makeBuffers() -> (MTLBuffer, MTLBuffer) {
    let uniformSize = MemoryLayout<SCNSceneBuffer>.stride + 96
    let perNodeSize = MemoryLayout<PerNodeData>.stride
    
    let uni = device.makeBuffer(length: uniformSize, options: [.storageModeShared])!
    let pnd = device.makeBuffer(length: perNodeSize, options: [.storageModeShared])!
    
    uni.label = "SCNSceneBuffer"
    pnd.label = "PerNodeData"
    return (uni, pnd)
  }
}

