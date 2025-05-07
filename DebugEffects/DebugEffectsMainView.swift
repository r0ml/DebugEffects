// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import DebugEffectsFramework


struct DebugEffectsMainView: View {
  @State var selectedLib : String? = UserDefaults.standard.string(forKey: "selectedLib")
  @State var selectedShader : String? = UserDefaults.standard.string(forKey: "selectedShader")
  @State var rescroll : Int = 0
  @State var debugFlag : Bool = false
  
  @FocusState var listFocus : Bool
  
  var shaders: [String : Manifest ] = [
    "Simple" : SimpleManifest(),
    "Background" : BackgroundManifest(),
    "SimpleLayers" : SimpleLayersManifest(),
    "SimpleDistortion" : SimpleDistortionManifest(),
    "SimpleArgs" : SimpleArgsManifest(),
    "ImageArg" : ImageArgManifest(),
  ]
  
  @AppStorage("searchText") var searchText : String = ""
  
  var filteredShaders : [String : Manifest ] {
    if searchText.isEmpty { return shaders }
    var res = [String:Manifest]()
    for (xx, yy) in shaders {
      let a = yy.registered
      let b = a.filter { $0.key.hasPrefix(searchText) }
      if !b.isEmpty {
        let m = DummyManifest(b)
        res[xx] = m
      }
    }
    return res
  }
  
  var body: some View {
    // let _ = Self._printChanges()
    
    return NavigationSplitView(columnVisibility: .constant(.all) ) {
      XSidebarView(selectedLib: $selectedLib, extensions: filteredShaders)
        .onChange(of: selectedLib, initial: false) {
          UserDefaults.standard.setValue(selectedLib, forKey: "selectedLib")
          selectedShader = ""
        }
        .onChange(of: selectedShader, initial: false) { (ov, nv) in
          listFocus = true
          UserDefaults.standard.setValue(nv, forKey: "selectedShader")
          if let ov { shaders[selectedLib!]!.registered[ov]?.teardown() }
          
          // FIXME: need this for when the shader changes while the debug toggle is set.
          // otherwise the metalkit doesn't change
          // possibly a bug in NSViewRepresentable?  makeNSView never gets called after init() (only updateNSView)
          if debugFlag {
            Task { @MainActor in
              debugFlag.toggle()
              await Task.yield()
              debugFlag.toggle()
            }
          }
        }
    } content: {
      if let selectedLib,
         let ss = filteredShaders[selectedLib] {
        AnyView(
        ShaderListView(theManifest: ss.registered, selectedShader: $selectedShader, rescroll: $rescroll )
          .focusable()
          .focused($listFocus)
          .onChange(of: searchText) {
            if let _ = (ss.registered.keys.sorted().first { $0.hasPrefix(searchText) }) {
              rescroll += 1
            }
          }
          .onChange(of: selectedLib) {
            rescroll -= 1
          }
        )
      } else {
        AnyView( Text("Nothing selected") )
      }
    } detail: {
        ShaderViewWrapper(shader: getShader, debugFlag: $debugFlag)
    }
    .searchable(text: $searchText, prompt: "shader name")
    .navigationTitle("\(selectedLib ?? "") > \(selectedShader ?? "")" )
  }
  
  @MainActor var getShader : (any AnyStitchDefinition)? {
    guard let selectedLib, let mm = shaders[selectedLib] else { return nil }
    guard let ext = mm.registered[selectedShader ?? "?"] else {
      return nil
    }
    
    // this needs to be a method call, because ext has been type-erased, and getting the shader view needs access
    // to the generic type.  The method call winds up being evaluated in the generic class
    return ext
  }
}
