import SwiftUI

struct WidgetSettingsView: View {
  @Environment(\.openWindow) private var openWindow
  @Environment(\.openURL) private var openURL
  
  @State var widget: Widget
  var callback: () -> Void
  
  @State var foreColor: Color = .white
  @State var backColor: Color = .clear
  @State var tintColor: Color = .blue
  @State var showAllOptions: Bool = false
  @State var fontMenu: String = ""
  @FocusState private var isTextFieldFocused: Bool
  @State private var locationTempString: String = "about:blank"
  
  let formatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .percent
    return formatter
  }()
  
  func clean(url: String) -> String? {
    if (url.hasPrefix("http")) {
      return url
    } else {
      if (url.contains(".") && !url.contains(" ")) {
        return "https://\(url)"
      }
    }
    return nil
  }
  
  let spacing = 20.0
  let labelWidth = 72.0
  let columns = [
    GridItem(.adaptive(minimum: 96, maximum: 480), spacing: 20)
  ]
  
  var body: some View {
    GeometryReader { g in
      NavigationStack {
        Form {
          Section(header: Text("Content")){
            
            // MARK: Name
            HStack(spacing:spacing) {
              Label("Title", systemImage: "link")
                .labelStyle(.titleOnly)
                .frame(maxWidth: labelWidth, alignment: .leading)
              
              TextField(widget.title ?? "", text: $widget.name)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .keyboardType(.URL)
            }
            
            // MARK: Location
            
            HStack(alignment: .center, spacing:spacing) {
              Label("Clear", systemImage: "link")
                .labelStyle(.titleOnly)
                .frame(maxWidth: labelWidth, alignment: .leading)
              
              TextField("location", text: $locationTempString, axis: .vertical)
              //                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .keyboardType(.URL)
                .onAppear {
                  locationTempString = widget.location!
                  backColor = widget.backColor ?? .clear
                  foreColor = widget.foreColor ?? .white
                  tintColor = widget.tintColor ?? .blue
                }
                .onSubmit {
                  if let url = clean(url:locationTempString) {
                    widget.location = url
                    locationTempString = url
                    callback();
                  }
                }
              
                .focused($isTextFieldFocused)
                .onChange(of: isTextFieldFocused) {
                  if isTextFieldFocused {
                    DispatchQueue.main.async {
                      UIApplication.shared.sendAction(#selector(UIResponder.selectAll(_:)), to: nil, from: nil, for: nil)
                    }
                  }
                }
              
              // MARK: Menu
              Menu {
                Button("User Agent", action: {}).disabled(true)
                Picker("User Agent", selection: $widget.userAgent) {
                  Text("Mobile").tag("mobile")
                  Text("Desktop").tag("desktop")
                }
                Divider()
                Button("Show All Options", action: {
                  showAllOptions.toggle()
                })
              } label: {
                Label("Location", systemImage: "ellipsis")
              }.labelStyle(.iconOnly)
                .buttonStyle(.borderless)
            }
            
          }
          
          Section(header: Text("Appearance")) {
            Picker("Style", selection: $widget.style) {
              ForEach(ViewStyle.allCases, id: \.self) { value in
                Text(value.displayName)
              }
            }
            
            HStack(spacing:spacing) {
              Label("Colors", systemImage: "ellipsis").labelStyle(.titleOnly)
                .frame(maxWidth: labelWidth, alignment:.leading)
              
              LazyVGrid(columns:columns) {
                HStack {
                  ColorPicker(selection: $backColor) {
                    Image(systemName: "square.fill")
                  }.frame(maxWidth:56).onChange(of: backColor) {
                    if let hex = backColor.toHex() { widget.backHex = hex }
                  }.labelsHidden().scaleEffect(1.2)
                  Text("Back")
                }
                HStack {
                  ColorPicker(selection: $foreColor, supportsOpacity: true) {
                    Image(systemName: "textformat.size.smaller")
                  }.frame(maxWidth:56).onChange(of: foreColor) {
                    if let hex = foreColor.toHex() { widget.foreHex = hex }
                  }.labelsHidden().scaleEffect(1.2)
                  Text("Text")
                }
                HStack {
                  ColorPicker(selection: $tintColor, supportsOpacity: true) {
                    Image(systemName: "a.square")
                  }.frame(maxWidth:56).onChange(of: tintColor) {
                    if let hex = tintColor.toHex() { widget.tintHex = hex }
                  }.labelsHidden().scaleEffect(1.2)
                  Text("Tint")
                }
                
                
              }.frame(maxWidth:.infinity)
            }
            
            
            // MARK: Font
            HStack(spacing:spacing) {
              Text("Font")
                .frame(maxWidth: labelWidth, alignment:.leading)
              
              
              TextField("default font", text:$widget.fontName ?? "")
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .frame(maxWidth: .infinity)
              
              TextField("normal", text:$widget.fontWeight ?? "")
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .frame(maxWidth: .infinity)
              
              // MARK: Menu
              Menu {
                Picker("Font Override", selection: $fontMenu) {
                  Text("Default").tag("")
                  Text("System (San Francisco)").tag("-apple-system")
                  Divider()
                  Text("Archivo Narrow").tag("Archivo Narrow")
                  Text("Bungee").tag("Bungee")
                  Text("DM Sans").tag("DM Sans")
                  Text("Space Mono").tag("Space Mono")
                  Text("VF Semi Cond").tag("VF Semi Cond")
                }
                Divider()
                
                Button("More on Google Fonts…") {
                  openURL(URL(string:"https://fonts.google.com")!)
                }
              } label: {
                Label("Location", systemImage: "ellipsis")
              }.onChange(of: fontMenu, {
                widget.fontName = fontMenu;
              })
              .onAppear() {
                fontMenu = widget.fontName ?? ""
              }
              .labelStyle(.iconOnly)
              .buttonStyle(.borderless)
            }
            
            
            
            
            
            
            
          }
          
          
          if (showAllOptions) {
            
            Section(header: Text("Advanced")) {
              
              // MARK: Icon
              HStack(spacing:spacing) {
                Label("Icon", systemImage: "link")
                  .labelStyle(.titleOnly)
                  .frame(maxWidth: labelWidth, alignment: .leading)
                TextField("icon name", text:$widget.icon)
                
                  .autocapitalization(.none)
                  .disableAutocorrection(true)
                  .frame(maxWidth: .infinity)
              }
              HStack(spacing:spacing) {
                Label("Radius", systemImage: "link")
                  .labelStyle(.titleOnly)
                  .frame(maxWidth: labelWidth, alignment: .leading)
                
                TextField("radius", value:$widget.radius, formatter: NumberFormatter())
                
                  .autocapitalization(.none)
                  .disableAutocorrection(true)
                  .frame(maxWidth: .infinity)
              }
              
              // MARK: Viewport
              HStack(spacing:spacing) {
                Label("Zoom", systemImage: "link")
                  .labelStyle(.titleOnly)
                  .frame(maxWidth: labelWidth, alignment: .leading)
                
                TextField("percent", value:$widget.zoom, formatter: formatter)
                
                  .autocapitalization(.none)
                  .disableAutocorrection(true)
                  .frame(maxWidth: .infinity)
                
                Label("Viewport", systemImage: "link")
                  .labelStyle(.titleOnly)
                  .frame(maxWidth: labelWidth, alignment: .leading)
                
                TextField("width", value:$widget.viewportWidth, formatter: NumberFormatter())
                  .autocapitalization(.none)
                  .disableAutocorrection(true)
                  .frame(maxWidth: .infinity)
              }
              
            }
              
              // MARK: Overrides
              
              
              Section(header: Text("CSS Tweaks")){
                HStack(alignment: .top, spacing:spacing) {
                  Label("Clear", systemImage: "link")
                    .labelStyle(.titleOnly)
                    .frame(maxWidth: labelWidth, alignment: .leading)
                  TextField("transparent elements", text:$widget.clearClasses ?? "", axis: .vertical)
                   
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .frame(maxWidth: .infinity)
                }
                HStack(alignment: .top, spacing:spacing) {
                  Label("Hide", systemImage: "link")
                    .labelStyle(.titleOnly)
                    .frame(maxWidth: labelWidth, alignment: .leading)
                  TextField("removed elements", 
                            text: $widget.removeClasses ?? "",
                            axis: .vertical)
                   
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .frame(maxWidth: .infinity)
                }
                HStack(alignment: .top, spacing:spacing) {
                  Label("Override", systemImage: "link")
                    .labelStyle(.titleOnly)
                    .frame(maxWidth: labelWidth, alignment: .leading)
                  TextField("custom css", text:$widget.injectCSS ?? "", axis: .vertical)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .frame(maxWidth: .infinity)
                }
                
              
            }
          }
        }
        .frame(maxWidth: 640, maxHeight: .infinity, alignment: .center)
        
        .toolbar {
          
          ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button { self.callback() } label: {
              Label("Done", systemImage: "chevron.left")
            }
            .labelStyle(.titleOnly)
          }
          ToolbarItemGroup(placement:.navigationBarLeading) {
            
            Button { openWindow(id:"main") } label: {
              Label("List", systemImage: "rectangle.grid.2x2")
            }
            .labelStyle(.iconOnly)
            .buttonBorderShape(.circle)
            
            ShareLink(
              item: URL(string: widget.shareURL)!,
              preview: SharePreview(
                "Widget \(widget.name)",
                image: Image(systemName: "plus"))
            ) {
              Image(systemName: "square.and.arrow.up")
            }
            .buttonBorderShape(.circle)
            
          }
        }
      }        .padding(min(g.size.width/32, 0)) // Collapse small size padding
      
    }
  }
}

#Preview(windowStyle: .automatic) {
  WidgetSettingsView(widget:Widget.preview, callback: {})
}
