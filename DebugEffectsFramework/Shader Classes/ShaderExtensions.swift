// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import SwiftUI

extension Shader.Argument {
  public static func float(_ b : Bool) -> Shader.Argument {
    return self.float(b ? Float(1) : 0)
  }

  public static func float2(_ b1 : Bool, _ b2 : Bool) -> Shader.Argument {
    return self.float2(b1 ? Float(1) : 0, b2 ? Float(1) : 0)
  }

  public static func float3(_ b1 : Bool, _ b2 : Bool, _ b3 : Bool) -> Shader.Argument {
    return self.float3(b1 ? Float(1) : 0, b2 ? Float(1) : 0, b3 ? Float(1) : 0)
  }

  public static func float4(_ b1 : Bool, _ b2 : Bool, _ b3 : Bool, _ b4 : Bool) -> Shader.Argument {
    return self.float4(b1 ? Float(1) : 0, b2 ? Float(1) : 0, b3 ? Float(1) : 0, b4 ? Float(1) : 0)
  }

  public static func float(_ i : Int) -> Shader.Argument {
    return self.float(Float(i) )
  }
  
  public static func float(_ i : Int32) -> Shader.Argument {
    return self.float(Float(i) )
  }
}


public struct ArgColor : Equatable, Sendable {
  public var red : Float16 = 0
  public var green : Float16 = 0
  public var blue : Float16 = 0
  public var alpha : Float16 = 1
  
  public static func == (lhs: ArgColor, rhs: ArgColor) -> Bool {
    return lhs.red == rhs.red &&
    lhs.green == rhs.green &&
    lhs.blue == rhs.blue &&
    lhs.alpha == rhs.alpha
  }
  
  public init(red: Float16, green: Float16, blue: Float16, alpha: Float16) {
    self.red = red
    self.green = green
    self.blue = blue
    self.alpha = alpha
  }
}


public extension Binding {

  static func convert(from c: Binding<ArgColor>) -> Binding<Color> {
    
    Binding<Color>(
      get: { return Color(.displayP3, red: Double(c.wrappedValue.red), green: Double(c.wrappedValue.green), blue: Double(c.wrappedValue.blue), opacity: Double(c.wrappedValue.alpha)) },
      set: { n in
        let j = n.resolve(in: EnvironmentValues())
        c.wrappedValue = ArgColor(red: Float16(j.red), green: Float16(j.green), blue: Float16(j.blue), alpha: Float16(j.opacity) ) }
    )
    }
  
  static func convert<TInt: Sendable, TFloat>(from intBinding: Binding<TInt>) -> Binding<TFloat>
    where TInt:   BinaryInteger,
          TFloat: BinaryFloatingPoint{

        Binding<TFloat> (
            get: { TFloat(intBinding.wrappedValue) },
            set: { intBinding.wrappedValue = TInt($0) }
        )
    }

  static func convert<TFloat: Sendable, TInt>(from floatBinding: Binding<TFloat>) -> Binding<TInt>
    where TFloat: BinaryFloatingPoint,
          TInt:   BinaryInteger {

        Binding<TInt> (
            get: { TInt(floatBinding.wrappedValue) },
            set: { floatBinding.wrappedValue = TFloat($0) }
        )
    }
}
