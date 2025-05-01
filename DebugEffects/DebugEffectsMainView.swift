// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import DebugEffectsFramework


struct SwiftUIMetalMainView: View {
  @State var selectedLib : String? = UserDefaults.standard.string(forKey: "selectedLib")
  @State var selectedShader : String? = UserDefaults.standard.string(forKey: "selectedShader")
  @State var rescroll : Int = 0
  @FocusState var listFocus : Bool
  
  var extensions: [String : Manifest ] = [
    "Simple" : SimpleManifest(),
    "Background" : BackgroundManifest(),
  ]
  
  @AppStorage("searchText") var searchText : String = ""
  
  var filteredExtensions : [String : Manifest ] {
    if searchText.isEmpty { return extensions }
    var res = [String:Manifest]()
    for (xx, yy) in extensions {
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
    return NavigationSplitView(columnVisibility: .constant(.all) ) {
      XSidebarView(selectedLib: $selectedLib, extensions: filteredExtensions)
        .onChange(of: selectedLib, initial: false) {
          UserDefaults.standard.setValue(selectedLib, forKey: "selectedLib")
//          searchText = ""
          selectedShader = ""
        }
        .onChange(of: selectedShader, initial: false) { (ov, nv) in
          listFocus = true
          UserDefaults.standard.setValue(nv, forKey: "selectedShader")
          if let ov { extensions[selectedLib!]!.registered[ov]?.teardown() }
        }
    } content: {
      if let selectedLib,
         let ss = filteredExtensions[selectedLib] {
        AnyView(
        ShaderListView(theManifest: ss.registered, selectedShader: $selectedShader, rescroll: $rescroll )
          .focusable()
          .focused($listFocus)
          .onChange(of: searchText) {
            if let z = (ss.registered.keys.sorted().first { $0.hasPrefix(searchText) }) {
              rescroll += 1
              //            selectedShader = z
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
        self.shaderView
    }
    .searchable(text: $searchText, prompt: "shader name")
    .navigationTitle("\(selectedLib ?? "") > \(selectedShader ?? "")" )
  }
  
  @MainActor var shaderView : some View {
    guard let selectedLib, let mm = extensions[selectedLib] else { return AnyView(Text("no library selected")) }
    guard let ext = mm.registered[selectedShader ?? "?"] else {
      return AnyView(Text("nothing selected") )
    }
    
    return ext.getShaderView()
  }
}
