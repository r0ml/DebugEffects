// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import AppKit
import MetalKit

/** This is the Swift analog to the `ctrl` variable passed in to i`initialize` and the fragment and vertex functions. */
struct PipelineControl {
  var topology : Int32
  var isBlendingEnabled : Bool

  var vertexCount : Int32;
  var instanceCount : Int32;
}

// In order to emulate the SCNProgram calling interface
struct SCNSceneBuffer {
  var viewTransform : float4x4;
  var inverseViewTransform : float4x4; // view space to world space
  var projectionTransform : float4x4;
  var viewProjectionTransform : float4x4;
  var viewToCubeTransform : float4x4; // view space to cube texture space (right-handed, y-axis-up)
  
// ?
  var lastFrameViewProjectionTransform : float4x4
  
  var ambientLightingColor : SIMD4<Float>;
  var fogColor : SIMD4<Float>;
  var fogParameters : SIMD3<Float>; // x: -1/(end-start) y: 1-start*x z: exponent
  
  //?
  var inverseResolution : SIMD2<Float>
  
  
  var time : Float;     // system time elapsed since first render with this shader
  var sinTime : Float;  // precalculated sin(time)
  var cosTime : Float;  // precalculated cos(time)
  var random01 : Float; // random value between 0.0 and 1.0
  
  //?
  var motionBlurIntensity : Float
  var environmentIntensity : Float
  var inverseProjectionTransform : float4x4
  var inverseViewProjectionTransfrom : float4x4
  var nearFar : SIMD2<Float>
}

// Needs to be synced with Common.h
// In order to emulate the SCNProgram calling interface
struct PerNodeData {
  var modelTransform : float4x4;
  var inverseModelTransform : float4x4;
  var modelViewTransform : float4x4;
  var inverseModelViewTransform : float4x4;
  var normalTransform : float4x4; // Inverse transpose of modelViewTransform
  var modelViewProjectionTransform : float4x4;
  var inverseModelViewProjectionTransform : float4x4;
  var boundingBox : float2x3;
  var worldBoundingBox : float2x3;
}
