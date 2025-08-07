// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import SwiftUI

public enum ShaderType {
  case color
  case layer
  case distort
  
  var shaderSuffix : String {
    switch self {
      case .color: return "ColorFragment"
      case .layer: return "LayerFragment"
      case .distort: return "DistortFragment"
    }
  }
}

struct StillView : View {
  var elapsedTime : TimeInterval
  var nn : AnyView //  could be an image or a color
  var location : Location
  
  let shaderType : ShaderType
  let shaderFn : ShaderFunction

  var args : [Shader.Argument]
  
  var body : some View {


    let b = AnyView(nn).background(Color.black) // .containerBackground(Color.black, for: .window) // AnyView(BaseView(image: nn))
    let lp = location.pt

    // This monstrosity is necessary because there is no AnyVisualEffect
    switch shaderType {
      case .distort: return AnyView(b.visualEffect { content, proxy in
        let mouse = CGPoint(x: min(1, max(0, lp.x / proxy.size.width)),
                            y: min(1, max(0, lp.y / proxy.size.height)))
        let art = [Shader.Argument.float(elapsedTime), .float2(proxy.size), .float2(mouse)] + args
        return content.distortionEffect(Shader.init(function: shaderFn, arguments: art),
                                        maxSampleOffset: proxy.size,
                                        isEnabled: shaderFn.name != "???")
      })
      case .color: return AnyView(b.visualEffect { content, proxy in
        let mouse = CGPoint(x: min(1, max(0, lp.x / proxy.size.width)),
                            y: min(1, max(0, lp.y / proxy.size.height)))
        let art = [Shader.Argument.float(elapsedTime), .float2(proxy.size), .float2(mouse)] + args
        return content.colorEffect( Shader.init(function: shaderFn, arguments: art),
                                    isEnabled: shaderFn.name != "???")
      })
        
      case .layer: return AnyView(b.visualEffect { content, proxy in
        let mouse =  CGPoint(x: min(1, max(0, lp.x / proxy.size.width)),
                             y: min(1, max(0, lp.y / proxy.size.height)))
//        print("mouse \(mouse), size \(proxy.size)")
        
        let art = [Shader.Argument.float(elapsedTime), .float2(proxy.size), .float2(mouse)] + args
        
        return content.layerEffect( Shader.init(function: shaderFn, arguments: art ),
                                    maxSampleOffset: proxy.size,
                                    isEnabled: shaderFn.name != "???")
      })
    }
  }
  
  /*
  func ve( _ content: EmptyVisualEffect, _ proxy : GeometryProxy) -> VisualEffect {
    let mouse = CGPoint(x: lp.x / proxy.size.width, y: lp.y / proxy.size.height)
    let art = [Shader.Argument.float(elapsedTime), .float2(proxy.size), .float2(mouse)] + args
    
  }
   */

}
