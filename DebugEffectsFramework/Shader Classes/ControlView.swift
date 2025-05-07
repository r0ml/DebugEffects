// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import Foundation
@_exported import SwiftUI

// There's a race here:
// between  metronome() setting etas
// and reset()
// FIXME: the unchecked is a lie!
@Observable public final class ControlState : @unchecked Sendable {
  var paused : Bool { get { pauseTime != nil }
    set {
      if newValue {
        if pauseTime == nil {
          self.pauseTime = Date.now
        }
      } else {
        self.deadTime += -pauseTime!.timeIntervalSinceNow
        self.pauseTime = nil
      }
    }
  }
  var pauseTime : Date? = nil
  var deadTime : TimeInterval = 0
  var startTime : Date = Date.now
  var singleStep : Bool = false
  
  var elapsedTime : TimeInterval {
    get {
      -startTime.timeIntervalSinceNow + (paused ? pauseTime!.timeIntervalSinceNow : 0 ) - deadTime
    }
  }
  
  func reset() {
    startTime = Date.now
    deadTime = 0
    if pauseTime != nil {
      pauseTime = Date.now
    }
  }
  
  var elapsedTimeAsString : String { get {
    let d = Int(floor(elapsedTime))
    let seconds = d % 60
    let minutes = (d / 60) % 60
    let fd = String(format: "%0.2d:%0.2d", minutes, seconds); //   "%0.2d:%0.2d.%0.2d", minutes, seconds, ms)
    return fd
    }
  }

  var etas : String = "00:00"
  
  func metronome() async {
    repeat {
            // code you want to repeat
      etas = self.elapsedTimeAsString

      try? await Task.sleep(for: .seconds(0.5)) // exception thrown when cancelled by SwiftUI when this view disappears.
    } while (!Task.isCancelled)
  }
}


let buttonSize : CGFloat = 32

struct ControlView : View {
  @Binding var controlState : ControlState
  
  var body: some View {
    HStack(spacing: 20) {
      Image(systemName: "backward.end").resizable().scaledToFit()
            .frame(width: buttonSize, height: buttonSize).onTapGesture {
              controlState.reset()
              print("reset: \(controlState.elapsedTime)")
              controlState.singleStep = true
          }

//      if shader.isRunningx {
      if !controlState.paused {
            HStack() {
              Image(systemName: "pause.circle").resizable().scaledToFit()
                .frame(width: buttonSize, height: buttonSize).onTapGesture {
                  controlState.paused.toggle()
                 // print("paused")
                }
              // This is `hidden` to keep things in the same place
              Image(systemName: "playpause" /* "chevron.right.to.line" */ /* "arrowkeys.right.fill" */).resizable().scaledToFit().hidden()
                .frame(width: buttonSize, height: buttonSize).onTapGesture {
                 //   print("single-step")
                }
            }
          } else {
            HStack() {
              Image(systemName: "play.circle").resizable().scaledToFit()
                .frame(width: buttonSize, height: buttonSize).onTapGesture {
                  controlState.paused.toggle()
              }
              
              Image(systemName: "chevron.right.to.line" /* "arrowkeys.right.fill" */ ).resizable().scaledToFit()
                .frame(width: buttonSize, height: buttonSize).onTapGesture {
                  controlState.singleStep = true
//                  controlState.paused = false
              }
              
            }
          }
         Spacer()
          
          Text(controlState.etas).font(.system(.body).monospacedDigit())
  //        Text(frameTimer.shaderFPS).font(.system(.body).monospacedDigit())

          Spacer()
 
          Image(systemName: "camera")
            .resizable().scaledToFit()
//            .fileExporter(isPresented: $saveImage,
//                          document: ImageDocument(shader: shader),
//                          contentType: .png
//            ) { z in
//              print("image file exporter \(z)")
//            }

            
            .frame(width: buttonSize, height: buttonSize).onTapGesture {
/*
            shader.imageToSave.grabImage = true
              saveImage = true
              
              Task.detached {
                try? await Task.sleep(for: .milliseconds(20) )
                if let z = await shader.imageToSave.theImage {
                  let fetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumRecentlyAdded, options: nil)
                  fetchResult.enumerateObjects { a, b, c in
                    print(a.localizedTitle ?? "(no title)")
                  }
                  let coll = fetchResult[0]
                  addAsset(image: z, to: coll)
                }
                
              }
 */
              print("export")
            }
          
          
          Image(systemName: "video") // self.shader.videoRecorder == nil ? "video" : "video.fill")
              .resizable().scaledToFit()
          
          // took fileExporter out -- because it creates the file, and AVAssetWriter does not want the file created
/*              .fileExporter(isPresented: $saveVideo,
                            document: EmptyVideoDocument(),
                            contentType: .mpeg4Movie
              ) {z in
                if let u = try? z.get() {
                  startRecorderExporter(u)
                }
                print("end file exporter")
              }
              .onChange(of: saveVideo) {v in
                // I guess I'm not saving -- the fileExporter must have canceled
                print("saveVideo: \(v), \(self.shader.imageToSave.url), \(self.shader.videoRecorder)")
    /*            if !v {
                  self.shader.imageToSave.url = nil
                  self.shader.videoRecorder = nil // this ends recording
                }
     */
              }
  */
              .frame(width:buttonSize, height: buttonSize)
          
              .onTapGesture {
/*                if let v = self.shader.videoRecorder {
                v.endRecording {
                  
                  
                  print("video saved now?")
                  //              Task {
                  //                await MainActor.run {
                  //                  self.shader.imageToSave.videoToSave = self.shader.videoRecorder?.assetWriter.outputURL
                  
                  let ss = self.shader.videoRecorder?.assetWriter.outputURL
                  let tt = self.shader.imageToSave.url!
                  
                  try! FileManager.default.removeItem(at: tt)
                  try! FileManager.default.moveItem(at: ss!, to: tt)
                  
                  
                  self.shader.imageToSave.url = nil
                  self.shader.videoRecorder = nil // this ends recording
                }
                
              } else {
                
                // Stop the shader while the save dialog is up
                self.saveVideo = true
                self.shader.stop()
                
                // FIXME: use this for savePanel version
    //            self.startRecorder()
              }
 */
                print("record")
          }

          Spacer().frame(width: buttonSize)
          
    }.frame(minWidth: 600, minHeight: buttonSize * 1.2)
      .task {
        await controlState.metronome()
      }
    }
  }





