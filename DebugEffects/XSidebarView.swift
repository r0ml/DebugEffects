// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import DebugEffectsFramework

struct XSidebarView : View {
  @Binding var selectedLib : String?
  var extensions : [String : Manifest]
  
  var body: some View {
    let z = Array(extensions.keys).sorted()
    List( selection: $selectedLib) {
        ForEach( z, id: \.self) { zz in
          Text(zz).onTapGesture {
            selectedLib = zz
          }
        }
    }.listStyle(.sidebar)
   
  }
}
