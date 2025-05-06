// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

public struct BackgroundableView : View {
  
  @State var hovering = false
  var name : String
  
  @MainActor public var background : Binding<BackgroundSpec?>
  
  @MainActor public init(_ nam: String, args v : Binding<BackgroundSpec?>) {
    background = v
    name = nam
  }
  
  public var body : some View {
 //   let _ = Self._printChanges()
    
    // FIXME: use a "empty image" image
    var bg : AnyView = AnyView(EmptyView())

    if let i = background.wrappedValue?.nsImage {
      bg = AnyView( Image(nsImage: i).resizable().scaledToFit() )
    } else if let v = background.wrappedValue?.videoStream {
      //        Task { @MainActor in
      if let vv = v as? VideoSupport {
        bg = AnyView( MyAsyncImage {
          let cg = await vv.getThumbnail()
          let ns = NSImage(cgImage: cg, size: CGSize(width: cg.width, height: cg.height))
          return ns
        } ) // Image(decorative: bgx, scale: 1)
//          .resizable().scaledToFit())
        //        }
      } else if let w = v as? WebcamSupport {
        bg = AnyView(Image(nsImage: NSImage(named: "still_life")!))
      }
    } else if let c = background.wrappedValue?.bgColor {
      if let g = background.wrappedValue?.view {
        bg = AnyView( g.frame(maxHeight: 66)  )
      }
    }
    return AnyView(bg.frame(maxWidth: 100)
      .onDrop(of: [.fileURL, .image, .video, .movie], isTargeted: $hovering, perform: { doDrop($0, background) } )
    )
  }
  
  
  func doDrop(_ p : [NSItemProvider] , _ bg : Binding<BackgroundSpec?>) -> Bool {
    let pp = p[0]
    if pp.canLoadObject(ofClass: NSURL.self) {
      print("url")
    } else if pp.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
      pp.loadItem(forTypeIdentifier: UTType.image.identifier) {
        (v, err) in
        if let e = err {
          print("on drop of image \(e.localizedDescription)")
        }
        if let url = v as? URL,
           let k = NSImage.init(contentsOf: url) {
          
          if let bookmarkData = try? url.bookmarkData(options: [.securityScopeAllowOnlyReadAccess], includingResourceValuesForKeys: nil, relativeTo: nil) {
            Task { @MainActor in
              UserDefaults.standard.set(Data([2,0])+bookmarkData, forKey: "background.\(name)")
              self.background.wrappedValue = BackgroundSpec( k )
            }
          }
        }
      }
    } else if pp.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
      pp.loadItem(forTypeIdentifier: UTType.movie.identifier) {
        (v, err) in
        if let e = err {
          print("on drop of movie \(e.localizedDescription)")
        }
        if let url = v as? URL {
          
          if let bookmarkData = try? url.bookmarkData(options: [.securityScopeAllowOnlyReadAccess], includingResourceValuesForKeys: nil, relativeTo: nil) {
            Task { @MainActor in
              let k = VideoSupport(url: url)  //  AVAsset.init(url: url) {
              `UserDefaults`.standard.set(Data([3,0])+bookmarkData, forKey: "background.\(name)")
              self.background.wrappedValue = BackgroundSpec( k )
            }
          }
        }
      }
    } else {
      return false
    }
    return true
  }
}
