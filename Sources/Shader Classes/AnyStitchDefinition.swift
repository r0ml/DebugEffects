// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import SwiftUI
import MetalKit

public protocol AnyStitchDefinition : Identifiable {
  associatedtype T : ArgSetter
  var name : String { get }
  var id : String { get }

  @MainActor func getShaderView(debugFlag: Binding<Bool>) -> AnyView
  @MainActor func getSnapshot(_ s : CGSize) -> any View
  @MainActor func teardown()
//  func getArgs() -> any Instantiatable
}

public protocol Manifest {
  @MainActor init()
  var registered : [String : any AnyStitchDefinition] { get set }
}

extension Manifest {
  mutating public func register(_ n : any AnyStitchDefinition) {
    registered[n.id]=n
  }
}

public struct DummyManifest : Manifest {
  public init() {}
  public var registered : [String : any AnyStitchDefinition] = [:]
  public init(_ n : [String : any AnyStitchDefinition] ) {
    registered = n
  }
}
