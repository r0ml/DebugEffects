// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2025

import DebugEffectsFramework


extension String : Identifiable {
  public var id : String { self }
}

/// This View is the list of shaders available for the selected library.  They are displayed as snapshots from 10 seconds into the rendering
/// The arguments used are the default values, not the ones stored in UserDefaults.
struct ShaderListView : View {
  @Environment(\.colorScheme) var colorScheme : ColorScheme

  var theManifest : [String : any AnyStitchDefinition]?
  @Binding var selectedShader : String?
  @Binding var rescroll : Int
  @FocusState var lf : Bool
  
  var theView : some View {
    ScrollViewReader { sv in

      Table( theManifest!.values.map { $0.name }.sorted() ) {
        TableColumn("preview") { name in
          // does Table work with ScrollView ?

          // ForEach( theManifest!.values /* k[g]! */.sorted { $0.name < $1.name }, id: \.id) {
          let v = theManifest![name]!
          
          AnyView(v.getSnapshot(CGSize(width: 220, height: 150))) //   previewFor())
            .background( v.id == selectedShader ? (colorScheme == .dark ? Color.init(hue: 124.0 / 360, saturation: 0.77, brightness: 0.4) : Color.init(hue: 124.0 / 360, saturation: 0.77, brightness: 0.8) ) : Color.clear)
            .padding(2)
            .frame(minWidth: 100, maxWidth: 400)
            .frame(height: 150)
            .cornerRadius(24)
            .onTapGesture {
              selectedShader = v.id
            }

        }
      }
      /* this nonsense makes the scrollbars appear to be the
        right size
       */
        .onChange(of: rescroll, initial: true) { ov, nv in
          if nv <= ov {
            Task {
              for _ in 0..<2 {
                try? await Task.sleep(for: .milliseconds(20))
                let k = (theManifest!.values.map { $0.name }) .sorted()
                if let j = k.last {
                  sv.scrollTo(j.id)
                  sv.scrollTo(k.first!.id)
                }
              }
              if let se = selectedShader {
                sv.scrollTo(se, anchor:.center)
              }
            }
          } else {
            if let se = selectedShader {
              Task {
                try await Task.sleep(for: .milliseconds(20) )
                //            await MainActor.run {
                withAnimation(.easeInOut(duration: 60)) { // <-- Not working (changes nothing)
                  sv.scrollTo(se, anchor: .center)
                }
              }
            }
          }
        }
        .focusable()
        .focused($lf)
        .onKeyPress { k in
          let theList = theManifest!.values.sorted {$0.name < $1.name }
          var a : Int? = nil
          if k.key == .downArrow { a = 1 }
          else if k.key == .upArrow { a = -1 }
          if let a {
            if let x = (theList.firstIndex { $0.name == selectedShader }) {
              let y = x.advanced(by: a)
              if y >= theList.startIndex && y < theList.endIndex {
                selectedShader = theList[y].name
                rescroll += 1
              }
            }
            return.handled
          }
          return.ignored
        }
    }.task {
      lf = true
    }
  }
  
  var body: some View {
    if theManifest == nil {
      AnyView(Text("Nothing selected"))
    } else {
      AnyView(theView)
    }
  }
}

