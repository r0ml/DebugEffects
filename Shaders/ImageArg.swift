// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import DebugEffectsFramework
import Foundation
import SwiftUI

public struct ImageArgManifest : Manifest {
  public var libnam = "ImageArg"
  
  public var registered = [String:any AnyStitchDefinition]()
  
  @MainActor public init() {
    register(StitchDefinition<Alpha>("alphax", .layer, background: "london_tower", imageArg: "london_wheel"))
    register(StitchDefinition<Flip>("flip02", .layer, background: "london_tower", imageArg: "london_wheel"))
    
    register(StitchDefinition<JustImage<EmptyStruct>>("burning", .color, background: "london_tower", imageArg: "london_wheel") )
    register(StitchDefinition<JustImage<EmptyStruct>>("fade", .color, background: "london_tower", imageArg: "london_wheel") )
    register(StitchDefinition<NoiseFade>("noiseFade", .color, background: "london_tower", imageArg: "london_wheel") )
    register(StitchDefinition<JustImage<EmptyStruct>>("cube92", .layer, background: "london_tower", imageArg: "london_wheel") )
    register(StitchDefinition<JustImage<EmptyStruct>>("swap", .layer, background: "london_tower", imageArg: "london_wheel") )
    register(StitchDefinition<Kaleidoscope03>("kaleidoscope03", .layer, background: "london_tower", imageArg: "london_wheel") )
    register(StitchDefinition<Filter93>("filter93", .layer, background: "london_tower") )
    register(StitchDefinition<Filter94>("filter94", .distort, background: "london_tower") )
  }
  
  
  
  // I need to add:
  // a) setting the background (color or image or video or webcam)
  // b) setting the "image" arg (image or video or webcam)
  
  struct Alpha : ArgSetter {
    struct Args : Instantiatable {
      var radius : Float = 0.3
      var blur : Float = 0.5
      var compositing = true
    }
    
    @Bindable var args : ArgProtocol<Args>
    
    @State var color : Color = Color.mint
    @Environment(\.self) var environment
    
    public init(args v : ArgProtocol<Args>, /* image: NSImage? = nil */) {
      self._args = Bindable(v)
    }
    
    var body : some View {
      VStack {
        Toggle("Compositing", isOn: $args.floatArgs.compositing)
        Slider(value: $args.floatArgs.radius, in: 0.1...0.9) { Text("Radius") }
        Slider(value: $args.floatArgs.blur, in: 0.1...1) { Text("Blur") }
        
        ColorPicker.init("Background color", selection: $color).onChange(of: color, initial: true) {
          let cr = color.resolve(in: environment )
          args.background = BackgroundSpec(cr.cgColor)
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
  
  // =========================

  struct Kaleidoscope03 : ArgSetter {
    
    struct Args : Instantiatable {
      var mouse = false
      var gamma = true
      var fix_x = false
      var use_texture = false
      var color_debug = false
      var linear = false
    }
    
    @Bindable var args : ArgProtocol<Args>
    
    var body : some View {
      VStack {
        Toggle("mouse", isOn: $args.floatArgs.mouse)
        Toggle("gamma", isOn: $args.floatArgs.gamma)
        Toggle("fix_x", isOn: $args.floatArgs.fix_x)
        Toggle("use_texture", isOn: $args.floatArgs.use_texture)
        Toggle("color_debug", isOn: $args.floatArgs.color_debug)
        Toggle("linear", isOn: $args.floatArgs.linear)

        JustImage(args: args)
      }
    }
  }

  // =========================
  
  struct Filter93 : ArgSetter {
    enum Variant : Int, CaseIterable, Identifiable {
      case box = 0
      case grayscale
      case emboss
      
      var id : Int { rawValue }
    }
    
    struct Args : Instantiatable {
      var variant : Variant = .box
    }
    
    @Bindable var args : ArgProtocol<Args>
    
    var body : some View {
      VStack {
        Picker("Variant", selection: $args.floatArgs.variant) {
          ForEach(Variant.allCases, id: \.self) { variant in
            Text("\(variant)").tag(variant)
          }
        }.pickerStyle(.segmented)
        JustImage(args: args)
      }
    }
  }
  
  // =========================

  struct Filter94 : ArgSetter {
    enum Variant : Int, CaseIterable, Identifiable {
      case barrel = 0
      case bloating
      
      var id : Int { rawValue }
    }
    
    struct Args : Instantiatable {
      var variant : Variant = .barrel
    }
    
    @Bindable var args : ArgProtocol<Args>
    
    var body : some View {
      VStack {
        Picker("Variant", selection: $args.floatArgs.variant) {
          ForEach(Variant.allCases, id: \.self) { variant in
            Text("\(variant)").tag(variant)
          }
        }.pickerStyle(.segmented)
        JustImage(args: args)
      }
    }
  }
  
  // =========================

  struct NoiseFade : ArgSetter {
    struct Args : Instantiatable {
      var speed : Float = 0.3
    }

    @Bindable var args : ArgProtocol<Args>

/*    init(args: ArgProtocol<Args>) {
      self._args = Bindable(args)
      args.otherImage = NSImage(named: "london_wheel")
    }
  */
    
    var body : some View {
      VStack {
        Slider(value: $args.floatArgs.speed, in: 0.1...1) { Text("Speed \(args.floatArgs.speed)")}
        JustImage(args: args)
      }
    }
  }


}
