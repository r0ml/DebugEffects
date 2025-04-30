// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import SwiftUI
import UniformTypeIdentifiers

public protocol Instantiatable : Equatable {
  init()
}

public protocol AnyArgProtocol {
  associatedtype FloatArgs : Instantiatable

}

@Observable public class ArgProtocol<TFloatArgs : Instantiatable> {
//  associatedtype FloatArgs : Equatable
//  init()
  public var floatArgs : TFloatArgs
  public var otherImage : NSImage?
  public var name : String
  public var background : BackgroundSpec? // = BackgroundSpec(NSColor.systemMint.cgColor) // the background image -- could be a color or video?
  
  init(_ n : String) {
//    self.init()
    name = n
    floatArgs = TFloatArgs.init()
    if let d = UserDefaults.standard.data(forKey: "settings.\(n)") {
      _ = withUnsafeMutableBytes(of: &floatArgs) {
        d.copyBytes(to: $0)
      }
    }
    var bookmarkIsStale: Bool = false

    if let bm = UserDefaults.standard.data(forKey: "otherImage.\(n)") ,
        
        // 2.
        let resolvedUrl = try? URL(resolvingBookmarkData: bm,
                                   options: [.withSecurityScope
                                             //, withoutUI
                                            ],
                                   relativeTo: nil,
                                   bookmarkDataIsStale: &bookmarkIsStale),
       !bookmarkIsStale {
      if resolvedUrl.startAccessingSecurityScopedResource() {
        otherImage = NSImage(contentsOf: resolvedUrl)
      }
    }
    
    if let bm = UserDefaults.standard.data(forKey: "background.\(n)") ,
        
        // 2.
        let resolvedUrl = try? URL(resolvingBookmarkData: bm,
                                   options: [.withSecurityScope
                                             //, withoutUI
                                            ],
                                   relativeTo: nil,
                                   bookmarkDataIsStale: &bookmarkIsStale),
       !bookmarkIsStale {
      if resolvedUrl.startAccessingSecurityScopedResource() {
        // FIXME: need to also create Webcam or Video or Color
        if let ni = NSImage(contentsOf: resolvedUrl) {
          background = BackgroundSpec(ni)
        } else {
          background = BackgroundSpec(NSColor.systemMint.cgColor)
        }
      }
    } else {
//      background = BackgroundSpec(NSImage(named: "london_tower")!)
    }
  }

  /*
  init(_ d : Data) {
//    var dx = Self()
    // FIXME: make sure that the number of bytes copied is the same as the buffer size
    self.init()
    _ = withUnsafeMutableBytes(of: &floatArgs) {
      d.copyBytes(to: $0)
    }
  }
*/
}

extension ArgProtocol {
  func serialized() -> Data {
    withUnsafePointer(to: floatArgs) {
      return Data(bytes: $0, count: MemoryLayout.size(ofValue: floatArgs))
    }
  }
  
  
}

@MainActor public protocol ArgSetter : View {
 associatedtype Args : Instantiatable
  var args : Binding<ArgProtocol<Args>> { get }
  init(args : Binding<ArgProtocol<Args>>) 
}


public struct EmptyStruct : Instantiatable {
  var dummy : Int = 0
  public init() {}
}

/// This is the View (ArgSetter) for those shaders that do not have any parameters.  The settings view is empty.
public struct NoArgs : ArgSetter {
  public var args: Binding<ArgProtocol<EmptyStruct>>
  
  public init(args v : Binding<ArgProtocol<EmptyStruct>>, ) {
    args = v
//    args.wrappedValue.background = BackgroundSpec(NSColor.systemMint.cgColor)
//    args.wrappedValue.background = NSImage(named: "london_tower") ?? Color.mint
  }
 
  public var body : some View {
    BackgroundableView(args.wrappedValue.name, args: args.background)
  }
}

public struct JustImageArg : Equatable {
// FIXME: get image from defaults?
  public init() {}
}

public struct JustImage<T : Instantiatable> : ArgSetter {
  
  @State var hovering = false

  public var args: Binding<ArgProtocol<T>>
  
  public init(args v : Binding<ArgProtocol<T>>) {
    args = v
  }

  public var body : some View {
    // FIXME: use a "empy image" image
    HStack {
      Image(nsImage: args.otherImage.wrappedValue ?? NSImage(named: "arid_mud")!)
        .resizable().scaledToFit()
        .frame(maxWidth: 100)
        .onDrop(of: [.fileURL, .image, .video, .movie], isTargeted: $hovering, perform: doDrop )
      BackgroundableView(args.wrappedValue.name, args: args.background)
    }

  }

  func doDrop(_ p : [NSItemProvider] ) -> Bool {
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
          
          let bookmarkData = try? url.bookmarkData(options: [.securityScopeAllowOnlyReadAccess], includingResourceValuesForKeys: nil, relativeTo: nil)
          Task { @MainActor in
            UserDefaults.standard.set(bookmarkData, forKey: "otherImage.\(args.wrappedValue.name)")
            args.wrappedValue.otherImage = k
          }
        }
      }
    } else if pp.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
      print("movie")
    } else {
      return false
    }
    return true
  }
}



extension ArgProtocol {
  func asShaderArguments() -> [Shader.Argument] {
      var res = [Shader.Argument]()
      if let otherImage {
        res.append(.image(Image(nsImage:otherImage)))
      } else {
        // WARNING: an empty image will cause a crash
        let xx = Image.init(size: CGSize(width: 10, height: 10)) { _ in }
        res.append(.image(xx))
      }
    res.append(Shader.Argument.data(self.serialized()) )
      return res
  }
}
