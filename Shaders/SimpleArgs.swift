// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import DebugEffectsFramework
import Foundation
import SwiftUI

public struct SimpleArgsManifest : Manifest {
  public var libnam = "Parameterized"
  
  public var registered = [String:any AnyStitchDefinition]()
  
  @MainActor public init() {
    register(StitchDefinition<Hypnotic02>("hypnotic02", .color))
    register(StitchDefinition<Thingy2>("thingy2", .color))
    register(StitchDefinition<Triangle>("triangle", .color))
    register(StitchDefinition<SimpleEffect>("simpleEffect", .color, background: "london_tower"))
    register(StitchDefinition<Alpha>("alphax", .layer, background: "london_tower"))
    register(StitchDefinition<Flip>("flip", .layer, background: "london_tower"))
    register(StitchDefinition<Cartoon>("cartoon", .layer, background: "london_tower"))
    register(StitchDefinition<Sobel>("sobel", .layer, background: "london_tower"))
  }
  
  
  // ==============================
  
  struct Hypnotic02 : ArgSetter {
    struct Args : Instantiatable {
      var zoom : Bool = false
      var double : Bool = false
    }
    
    @Bindable var args : ArgProtocol<Args>
    
    var body : some View {
      VStack {
        Toggle(isOn: $args.floatArgs.zoom) { Text("Zoom In")}
        Toggle(isOn: $args.floatArgs.double) { Text("Double")}
      }
      
    }
  }
  
  // ===================
  
  struct Thingy2 : ArgSetter {

    struct Args : Instantiatable {
      var sides : Int32 = 5
    }
    
    @Bindable var args : ArgProtocol<Args>
    
    var body : some View {
      VStack {
        Slider(value: .convert(from: $args.floatArgs.sides), in: 3...8, step: 1) { Text("Sides \(args.floatArgs.sides)")}
      }
    }
  }

  // =========================
  
  struct Triangle : ArgSetter {
    struct Args : Instantiatable {
      var sizex : Float = 1
      var showdist : Bool = false
      var spin : Bool = false
    }

    @Bindable var args : ArgProtocol<Args>
    
    var body : some View {
      HStack {
        Toggle(isOn: $args.floatArgs.spin) { Text("spin") }
        Toggle(isOn: $args.floatArgs.showdist) { Text("show dist")}
        Slider(value: $args.floatArgs.sizex, in: 0.5...1.5) { Text("Size \(args.floatArgs.sizex)") }
      }
    }
  }

  // =========================
  

  struct SimpleEffect : ArgSetter {
    enum Variant : Int, CaseIterable, Identifiable {
      case Grayscale
      case Contrast
      case Invert
      case Noise
      case Sepia
      case Vignette
      case Channels
      
      var id: Int { rawValue }
    }
    struct Args : Instantiatable {
      var effect = Variant.Grayscale
    }

    @Bindable var args : ArgProtocol<Args>
    
    var body : some View {
      VStack {
        Picker(selection: $args.floatArgs.effect, label: Text("Effect")) {
          ForEach(Variant.allCases) {i in
            Text("\(i)").tag(i)
          }
          }.pickerStyle(.segmented)
        }
      }
  }

  // =========================

  
  
  // I need to add:
  // a) setting the background (color or image or video or webcam)
  // b) setting the "image" arg (image or video or webcam)

  struct Alpha : ArgSetter {
    
    struct Args : Instantiatable {
      var radius : Float = 0.3
      var blur : Float = 0.5
      var compositing = true
      //    var clem : Float = 33
    }

    @Bindable var args : ArgProtocol<Args>

    @State var color : Color = Color.mint
    
    
     @Environment(\.self) var environment
    
    
    public init(args v : ArgProtocol<Args>, ) {
      self._args = Bindable(v)
    }
    
//    public init(args v : Bindable<ArgProtocol<Args>>) {
//      _args = v
//    }
    
    var body : some View {
      VStack {
        Toggle("Compositing", isOn: $args.floatArgs.compositing)
        Slider(value: $args.floatArgs.radius, in: 0.1...0.9) { Text("Radius") }
        Slider(value: $args.floatArgs.blur, in: 0.1...1) { Text("Blur") }
        //      HStack {
        //        Image.init(importing: url)
        //      }


        ColorPicker.init("Background color", selection: $color).onChange(of: color, initial: true) {
          let cr = color.resolve(in: environment )
          args.background = BackgroundSpec(cr.cgColor)
          //        UserDefaults.default.set( cr.cgColor.components?, forKey: "background.\(self.name)")
          
        }
        JustImage(args: args)

      }
    }
  }

  // =========================


  struct Flip : ArgSetter {
    struct Args : Instantiatable {
      var slices : Int32 = 10
      var rspeed : Float = 30
    }
    
    @Bindable var args : ArgProtocol<Args>
    
    var body : some View {
      VStack {
        Slider(value: .convert(from: $args.floatArgs.slices), in: 3...20, step: 1) { Text("Slices") }
        Slider(value: $args.floatArgs.rspeed, in: 1...10) { Text("Melt speed") }
        JustImage(args: args)
      }
    }
  }

  // ==================
  
  struct Cartoon : ArgSetter {

    struct Args : Instantiatable {
      var strength : Int32 = 20
      var bias : Float = -0.5
      var power : Float = 1
      var precision : Float = 6
      var color = ArgColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
    }
    
    @Bindable var args : ArgProtocol<Args>
    
    var body : some View {
      VStack {
        Slider(value: .convert(from: $args.floatArgs.strength), in: 5...100, step: 1) { Text("Strength") }
        Slider(value: $args.floatArgs.bias, in: -2...2.0) { Text("Bias") }
        Slider(value: $args.floatArgs.power, in: 0.5...3) { Text("Power") }

        ColorPicker("Color", selection: .convert(from: $args.floatArgs.color))
        
        
        Slider(value: $args.floatArgs.precision, in: 2...10, step: 1) { Text("Precision") }
        JustImage(args: args)

      }
    }
  }
  
  // ==================
  
  struct Sobel : ArgSetter {
    enum Variant : Int, CaseIterable, Identifiable {
      case lengthx = 0
      case lumina
      case graysc
      case edge_glow
      case dfdx
      case fwidth
      case test
      
      var id : Int { rawValue }
    }
    
    struct Args : Instantiatable {
      var threshold : Float = 0.2
      var image = false
      var variant = Variant.lengthx;
    }
    
    @Bindable var args : ArgProtocol<Args>
    
    var body : some View {
      VStack {
        Toggle("image", isOn: $args.floatArgs.image)
        Slider(value: $args.floatArgs.threshold, in: 0...1) { Text("Threshold") }
        Picker("Variant", selection: $args.floatArgs.variant) {
          ForEach(Variant.allCases, id: \.self) { variant in
            Text("\(variant)").tag(variant)
          }
        }.pickerStyle(.segmented)
        JustImage(args: args)
      }
    }
  }


}
