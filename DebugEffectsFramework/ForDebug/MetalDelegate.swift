// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import SwiftUI
import SceneKit
import MetalKit
import SpriteKit
import os


@Observable open class MetalDelegate<T : Instantiatable> : NSObject, MTKViewDelegate {
  
  // FIXME: change the name of this -- there is a global which interferes
  public var times = Times()
  public var iFrame : Int = -1
  let semCount = 1
  var gpuSemaphore : DispatchSemaphore = DispatchSemaphore(value: 1)
  var fpsSamples : [Double] = Array(repeating: 1.0/60.0 , count: 60)
  var fpsX : Int = 0
  public var scale : Float = 1
  
  public let captureFrame = -2
  
  public var frameTimer: FrameTimer
  var renderer : SCNRenderer
  
  public var locations: Locations
  public var imageToSave = ImageToSave()
  
  public var videoRecorder: MetalVideoRecorder?
  public var drawableSize : CGSize?
  
  var shader: GenericShader
  
  var baseTexture : MTLTexture?
  var otherTexture : MTLTexture?
  
  var shaderType : ShaderType
  
  // An array of render/resolve textures for offscreen and/or shadow textures
  var renderTextures : (MTLTexture, MTLTexture)?
  
  var uniformBuffer : MTLBuffer?
  var perNodeData: MTLBuffer?
  var initializationBuffer : MTLBuffer!
  var controlBuffer : MTLBuffer!
  var frameComputeBuffer : MTLBuffer?
  var myDataBuffer : MTLBuffer?
  
  var argBuffer : MTLBuffer
  
  var didBeginShader = false
  /// This is the CPU overlay on the initialization buffer
  
  var textureSize : CGSize?
  
  var renderPassDescriptor : MTLRenderPassDescriptor?
  
  var args : ArgProtocol<T>
  
  var controlState : Binding<ControlState>?
  
  public func setVideoRecorder(_ m : MetalVideoRecorder?) {
    videoRecorder = m
  }
  
  deinit {
    gpuSemaphore.signal()
    gpuSemaphore.signal()
  }
  

  @MainActor public init(name: String,
                         type: ShaderType,
                         args: ArgProtocol<T>) {
    
    self.shader = GenericShader("\(name)_\(type.shaderSuffix)") // linkedFunctions: linkedFunctions)
                                                                //    self.baseImage = baseImage
                                                                //    self.video = video
    self.args = args
    // FIXME: what if the makeBuffer fails?
    self.argBuffer = device
      .makeBuffer(
        length: MemoryLayout.size(ofValue: args.floatArgs ),
        options: .storageModeShared
      )!
    
    self.frameTimer = FrameTimer()
    self.locations = Locations()
    self.renderer = SCNRenderer(device: device)
    //    self.ext = xi
    
    self.shaderType = type
    
    super.init()
  }
  
  
  // Another race condition?
  // If I set a stop here, then the thumbnail preview works for snapshot (but not for animation?)
  @MainActor public func sampleAt(seconds: Double, size: CGSize) async -> NSImage {
    beginShader()

    //    await times.setTime(seconds)
    
    controlState?.wrappedValue.paused = false
    
    guard size.width > 0 && size.height > 0 else { return NSImage() }
    return await draw(size: size, at: seconds)
  }
  
  @MainActor public func beginShader() {
    //    log.debug("\(#function)")
    if didBeginShader {
      return
    }
    didBeginShader = true
    
    
    (self.uniformBuffer, self.perNodeData) = shader.makeBuffers()
    
    shader.setupRenderPipeline( /* ctrl: k */)
  }
  
  public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    
    //    log.debug("\(#function) \(size.width)x\(size.height)")
    let loc = CGPoint(x: size.width / 2.0, y: size.height/2.0 )
    locations.setPointerLocation(loc)
    
    drawableSize = size
  }

  
  /// return false to abort
  func doRunning( /* _ view : MTKView */ ) -> Bool {
    // called per frame
    // log.debug("\(#function)")
    
    // FIXME: sometimes I get trapped here!
    //      print("in gpusem", terminator: "" )
    
    
    
    // FIXME: can I go ahead if the previous frame is still processing on the GPU?
    let gw = gpuSemaphore.wait(timeout: .now() + .microseconds(1) /*    .microseconds(1000/60) */ )
    
    if gw == .timedOut {
      // print("GPU timed out")
      return false }
    
    return true
  }
  
  @MainActor public func saveImage(_ view : MTKView) {
    let lastDrawableDisplayed = view.currentDrawable?.texture
    
    if let ldd = lastDrawableDisplayed,
       let imageOfView = CIImage.init(mtlTexture: ldd, options: nil)?.nsImage {
      imageToSave.theImage = imageOfView
    }
  }
  
  
  
  
  
  @objc(drawInMTKView:) @MainActor public func draw(in view: MTKView) {
    // called per frame
    // log.debug("\(#function)")
    if iFrame == 0 {
      //      log.debug("isRunningx = \(self.isRunningx)")
    }
    
    // This method is called, even when the shader is stopped.
    // So, if the "Shader" has a "capture image now" state, then I can invoke the "save the view here -- where the MTKView is being passed in
    if imageToSave.grabImage {
      imageToSave.grabImage = false
      self.saveImage(view)
    }
    
    if controlState?.wrappedValue.paused == false || controlState?.wrappedValue.singleStep == true  { //  isRunningx || isSteppingx {

      controlState?.wrappedValue.doStep()
        ddraw( view:  view)
    }
  }
  
  
  @MainActor public func draw(size: CGSize, at: Double) async -> NSImage {
    await times.setTime(at)
    await ddraw( size: size)
    
    // FIXME: This works to solve the "SamplingShader image is empty" problem -- which means there is a race condition somewhere.
    // but I can't find it.  I don't think it is the render, because a "waitUntilCompleted" doesn't fix the problem.
    try? await Task.sleep(nanoseconds: 100000000)
    
    guard let rt = renderTextures?.1 else {
      return NSImage() }
    if let j = NSImage(mtlTexture: rt) {
      return j
    } else {
      return NSImage()
    }
  }
  
  // =============================================================
  
  /*
  @MainActor func calculateFPS() async {
    // calculate and display the Frames Per Second
    
    await times.updateTime()
    
    
    // FIXME: put me back
    // just this doubles the CPU requirement.
    // can I make the frameTimer update be more efficient?
    
    let sss = await times.secondsSinceLast()
    fpsSamples[fpsX] = sss
    fpsX += 1
    if fpsX == fpsSamples.count { fpsX = 0 }
    
    if 0 == iFrame % 60 {
      
      let zz = fpsSamples.reduce(0, +)
      let t = Int(round(60.0 / zz))
      
      // format the time for display
      let sos = await times.secondsSinceStart()
      let duration: TimeInterval = TimeInterval(sos)
      _ = Int((duration.truncatingRemainder(dividingBy: 1)) * 100)
      let d = Int(floor(duration))
      let seconds = d % 60
      let minutes = (d / 60) % 60
      let fd = String(format: "%0.2d:%0.2d", minutes, seconds); //   "%0.2d:%0.2d.%0.2d", minutes, seconds, ms)
      
      let ft = frameTimer
      await MainActor.run {
        ft.shaderFPS = String(t)
        ft.shaderPlayerTime = fd
      }
      
    }
  }
  */
  
  
  @MainActor open func ddraw( view: MTKView ) {
    
    iFrame += 1
    
    if iFrame == captureFrame {
      triggerProgrammaticCapture()
    }
    
    // FIXME: set the clear color
    //      view.clearColor = MTLClearColor(red: Double(c[0]), green: Double(c[1]), blue: Double(c[2]), alpha: Double(c[3]))
    
    // FIXME: abort the whole execution if ....
    // if I get an error "Execution of then command buffer was aborted due to an error during execution"
    // in here, any calculations based on difference between this time and last time?
    //    if let rpd = view.currentRenderPassDescriptor {
    
    // to get the running shader to match the preview?
    // rpd.colorAttachments[0].clearColor = view.clearColor
    
    let desc = MTLCommandBufferDescriptor()
    desc.errorOptions = .encoderExecutionStatus
    
    let commandBuffer = commandQueue.makeCommandBuffer(descriptor: desc)!
    commandBuffer.label = "Render command buffer for \(shader.name)"
    
    doMouseDetection(view)
    
    let texz = view.currentDrawable
    let rpd = view.currentRenderPassDescriptor
    
    
    // FIXME: Weirdly, sometimes the uniformBuffer is nil here.  Should not be the case
    if let texz = texz,
       let rpd = rpd,
       let tex = rpd.colorAttachments[0].texture, // resolveTexture,
       let ub = uniformBuffer,
       let pnd = perNodeData {
      
      setUpBaseTexture(rpd, size: CGSize(width: texz.texture.width, height: texz.texture.height) )
      
      
      let textureSizeX = tex.width
      let textureSizeY = tex.height
      //      print("\(textureSizeX) x \(textureSizeY)")
      
      setupUniform(size: CGSize(width: textureSizeX, height: textureSizeY),
                   scale: 1,
                   sceneBuffer: ub,
                   nodeBuffer: pnd,
                   times: times)
      
      //      let bsf = view.window?.screen?.backingScaleFactor
      //      if let bsf {
      //        scale = Float(bsf)
      //      }
      
      moreDraw(commandBuffer: commandBuffer, rpd: rpd)
      
      
      // ???
      /*
       return await withCheckedContinuation { continuation in
       commandBuffer.addCompletedHandler { _ in
       continuation.resume(returning: /* ... */)
       }
       
       commandBuffer.commit()
       }
       */
      
      let kk = rpd.colorAttachments[0]!
      
      commandBuffer.addCompletedHandler { @Sendable commandBuffer in
        self.wrapUp( kk.texture  )
        //       let start = commandBuffer.gpuStartTime
        //       let end = commandBuffer.gpuEndTime
        //       let gpuRuntimeDuration = end - start
      }
      commandBuffer.present(texz)
      
    } else {
      print("why did I get here?")
      print("?")
    }
    commandBuffer.commit()
    
    if iFrame == captureFrame {
      Task {
        await MainActor.run {
          MTLCaptureManager.shared().stopCapture()
        }
      }
    }
  }
  
  @MainActor func ddraw( size: CGSize ) async {
    iFrame += 1
    
    if iFrame == captureFrame {
      triggerProgrammaticCapture()
    }
    
    // FIXME: set the clear color
    //      view.clearColor = MTLClearColor(red: Double(c[0]), green: Double(c[1]), blue: Double(c[2]), alpha: Double(c[3]))
    
    // FIXME: abort the whole execution if ....
    // if I get an error "Execution of then command buffer was aborted due to an error during execution"
    // in here, any calculations based on difference between this time and last time?
    //    if let rpd = view.currentRenderPassDescriptor {
    
    let commandBuffer = commandQueue.makeCommandBuffer()!
    commandBuffer.label = "Render command buffer for \(shader.name)"
    
    // this business is required if my compute shader has an output texture ??
    let mtl = MTLRenderPassDescriptor()
    if let rt = renderTextures {
      mtl.colorAttachments[0].texture = rt.0
      mtl.colorAttachments[0].resolveTexture = rt.1
    } else {
      fatalError("should not be here")
      /*
       let rt = shader.makeRenderPassTexture( "offscreen \(shader.name)", format: theOtherPixelFormat, scale: multisampleCount, size: size)
       mtl.colorAttachments[0].texture = rt!.0
       mtl.colorAttachments[0].resolveTexture = rt!.1
       renderTextures = rt
       */
    }
    
    setUpBaseTexture(mtl, size: size)
    
    // I don't have a config here, so no settable background color
    mtl.colorAttachments[0].clearColor = MTLClearColor.init(red: 0.2, green: 0.2, blue: 0.2, alpha: 0)
    mtl.colorAttachments[0].loadAction = .clear
    mtl.colorAttachments[0].storeAction = .storeAndMultisampleResolve
    
    // FIXME: If the size being requested is different than the cached render textures, recreate the textures.
    let textureSizeX = size.width
    let textureSizeY = size.height
    
    let rpd = mtl
    
    setupUniform(size: CGSize(width: textureSizeX, height: textureSizeY),
                 scale: 1,
                 sceneBuffer: uniformBuffer!,
                 nodeBuffer: perNodeData!,
                 times: times)
    
    moreDraw(commandBuffer: commandBuffer, rpd: rpd)
    
    commandBuffer.addCompletedHandler{ @Sendable commandBuffer in
      self.wrapUp( rpd.colorAttachments[0].resolveTexture  )
    }
    
    commandBuffer.commit()
    
    if iFrame == captureFrame {
      await MainActor.run {
        MTLCaptureManager.shared().stopCapture()
      }
    }
  }
  
  @MainActor public func triggerProgrammaticCapture() {
    let captureManager = MTLCaptureManager.shared()
    let captureDescriptor = MTLCaptureDescriptor()
    captureDescriptor.captureObject = device
    do {
      try captureManager.startCapture(with: captureDescriptor)
    }
    catch
    {
      fatalError("error when trying to capture: \(error)")
    }
  }
  
  @objc public func wrapUp(_ tx : MTLTexture?) {
    // FIXME: this is the thing that will record the video frame
    // self.videoRecorder?.writeFrame(forTexture: view.currentDrawable!.texture)
    if let tx {
      self.videoRecorder?.writeFrame(forTexture: tx)
    }
    self.gpuSemaphore.signal()
  }
  
  var lastTime : Double = 0
  
  
  
  
  
  // this draws the current frame
  @MainActor open func moreDraw(commandBuffer : MTLCommandBuffer, rpd: MTLRenderPassDescriptor) {
    // runs every frame
    // log.debug("\(#function)")
    
    // At this point:
    // If I am doing a multi-pass, then I must:
    // 1) create the render textures for the multiple passes
    // 2) create multiple render passes
    // 3) blit the outputs to inputs for the next frame (or swap the inputs and outputs
    
    // FIXME: should this be a clear or load?
    rpd.colorAttachments[0].loadAction = shader.loadAction(0) // .load
    rpd.colorAttachments[0].storeAction =  .store
    // FIXME: is this wahy colors don't match?
    rpd.colorAttachments[0].clearColor = //  MTLClearColor.init(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
    MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
    
    // snapshot must not call this
    // animation must call this
    
    // FIXME: this should probably be promoted to the caller
    if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd) {
      renderEncoder.label = "render encoder"
      self.setupRenderEncoder(renderEncoder)
    }
  }
  
  
  @MainActor func setUpBaseTexture(_ mtl : MTLRenderPassDescriptor, size: CGSize) {
    
    if let vv = args.background?.videoStream {
      if
        // FIXME: don't need both
        let ii = vv.readBufferAsImage( now() ),
        let sb = NSImage(ciImage: ii.oriented(.down)) {
        let kbt = sb.createTextureWithBlackBorder(device)
        baseTexture = kbt
      }
      
      
    } else if let sb = args.background?.nsImage {
      
      
      if let bt = baseTexture {
        
      } else {
        let kbt = sb.createTextureWithBlackBorder(device)
        baseTexture = kbt
      }
    }
    
    if let sb = args.otherImage {
      let ot = sb.createTextureWithBlackBorder(device)
      // let ot = sb.getTexture(textureLoader)
      otherTexture = ot
    }
  }
  
  // The above ddraw takes a MTKView as an argument, and so it renders the shader into that view.
  // This ddraw does not take a MTKView as an argument because it will render offscreen.  So it needs to create
  // its own RenderPassDescriptor and colorAttachments to render into.
  // Since this gets called on every frame, things like the textures and descriptors need to be created once in a
  // separate initialization function, then used here.
  
  
  
  
  
  
  
  @MainActor func setupRenderEncoder(_ renderEncoder : MTLRenderCommandEncoder) {
    setArguments(renderEncoder)
    finishCommandEncoding(renderEncoder)
    renderEncoder.endEncoding()
  }
  
  @MainActor func doMouseDetection(_ xview : MTKView?)  {
    // FIXME: what is this in iOS land?  What is it in mac land?
    
    let eml = NSEvent.mouseLocation
    if let xvv = xview,
       let xww = xvv.window {
      let wp = xww.convertPoint(fromScreen: eml)
      let ml = xvv.convert(wp, from: nil)
      
      if xvv.isMousePoint(ml, in: xvv.bounds) {
        locations.setPointerLocation(ml)
        let x = (ml.x - xvv.bounds.minX) / xvv.bounds.width
        let y = (ml.y - xvv.bounds.minY) / xvv.bounds.height
        if NSEvent.pressedMouseButtons != 0 {
          locations.setHitLocation( SIMD2<Float>(Float(x), 1-Float(y) ) )
        }
      }
    }
  }
}

struct MyData {
  var mouse : SIMD2<Float>
  var size : SIMD2<Float>
//      var funci : Int32 = 0
}


extension MetalDelegate {
  /** Sets the values for the Uniform value passed to shaders.
   Needs to be called for every frame */
  
  @MainActor func setupUniform( // iFrame: Int,
    size: CGSize, scale : Int,
    sceneBuffer uni: MTLBuffer,
    nodeBuffer pnb : MTLBuffer, times : Times) {
      
      
      let uniform = uni.contents().assumingMemoryBound(to: SCNSceneBuffer.self)
      
  //    Task { self.lastTime = await times.secondsSinceStart() }
      
  //    let tim = Float(self.lastTime )
      
      let tim =  Float( controlState?.wrappedValue.elapsedTime  ?? 0)
      uniform.pointee.time = tim
      
      uniform.pointee.sinTime = sin(tim)
      uniform.pointee.cosTime = cos(tim)
      uniform.pointee.random01 = Float.random(in: 0 ..< 1 )
      uniform.pointee.inverseResolution = SIMD2<Float>(1 / Float(size.width), 1 / Float(size.height))
      
      /*
       uniform.pointee.iTimeDelta = Float(times.currentTime - times.lastTime)
       */
      
      let perNodeData = pnb.contents().assumingMemoryBound(to: PerNodeData.self)
      let bb = ( SIMD3<Float>(0,0,0),SIMD3<Float>(Float(size.width), Float(size.height), 0))
      perNodeData.pointee.boundingBox = float2x3.init(columns: bb )
      perNodeData.pointee.worldBoundingBox = float2x3.init(columns: bb)
      
      // Done.  Sync with GPU
      
//      uni.didModifyRange(0..<uni.length)
//      pnb.didModifyRange(0..<pnb.length)
    }
  
  @MainActor func setArguments(_ renderEncoder : MTLRenderCommandEncoder) {
    
    // FIXME: for Layer shaders,
    // insert a compute kernel which converts the baseTexture to texture2d<half>
    // then construct a SwiftUI::Layer and set the texture, the info, and the sampler.
    
    if let bt = baseTexture {
      renderEncoder.setFragmentTexture(bt, index: 0)
    }

    if let bt = otherTexture {
      renderEncoder.setFragmentTexture(bt, index: 1)
    }
    
    if shaderType == .layer,
       let bt = baseTexture {
      renderEncoder.setFragmentTexture(bt, index: 2)
    }

    renderEncoder.setFragmentBuffer(uniformBuffer, offset: 0, index: sceneBufferId)
    renderEncoder.setFragmentBuffer(perNodeData, offset: 0, index: perNodeDataId)
    
    let mouse = self.locations.getHitLocation()

    // ====================================================================================
    
    // FIXME: don't need this stuff unless vertex shader
    renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: sceneBufferId)
    renderEncoder.setVertexBuffer(perNodeData, offset: 0, index: perNodeDataId)
    
    let sz = 1 / uniformBuffer!.contents().assumingMemoryBound(to: SCNSceneBuffer.self).pointee.inverseResolution
    
    if myDataBuffer == nil {
      myDataBuffer = device.makeBuffer(length: MemoryLayout<MyData>.size, options: .storageModeShared)
    }


    // **WARNING**: by putting the pointee on this line, the memory contents do not get updated
    // the pointee must be on the next (and subsequent) lines
    let kk = myDataBuffer!.contents().assumingMemoryBound(to: MyData.self)
    kk.pointee.mouse = mouse
    kk.pointee.size = sz
    
    renderEncoder.setFragmentBuffer(myDataBuffer!, offset: 0, index: 2)
    renderEncoder.setFragmentBuffer(argBuffer, offset: 0, index: 9)
  }
  
  func finishCommandEncoding(_ renderEncoder : MTLRenderCommandEncoder ) {
    renderEncoder.setRenderPipelineState(shader.pipelineState)
    renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1 )
  }
  
}

