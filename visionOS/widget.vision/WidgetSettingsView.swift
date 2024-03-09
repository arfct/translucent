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
  
  let percentFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.multiplier = 100
    return formatter
  }()
  
  let simpleFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    return formatter
  }()
  
  func commitLocation() {
    if let url = clean(url:locationTempString) {
      widget.location = url
      locationTempString = url
    }
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
          Section(){
            
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
              Label("URL", systemImage: "link")
                .labelStyle(.titleOnly)
                .frame(maxWidth: labelWidth, alignment: .leading)
              
              TextField("location", text: $locationTempString)
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
                  commitLocation()
                }
              
                .focused($isTextFieldFocused)
                .onChange(of: isTextFieldFocused) {
                  if isTextFieldFocused {
                    DispatchQueue.main.async {
                      UIApplication.shared.sendAction(#selector(UIResponder.selectAll(_:)), to: nil, from: nil, for: nil)
                    }
                  } else {
                    commitLocation()
                  }
                }
              
              // MARK: Menu
              Menu {
                Button("User Agent", action: {}).disabled(true)
                Picker("User Agent", selection: $widget.userAgent) {
                  Text("Mobile").tag("mobile")
                  Text("Desktop").tag("desktop")
                }
              } label: {
                Label("Location", systemImage: "ellipsis")
              }.labelStyle(.iconOnly)
                .buttonStyle(.borderless)
            }
            
            HStack(spacing:spacing - 18) {
              Label("Style", systemImage: "ellipsis").labelStyle(.titleOnly)
                .frame(maxWidth: labelWidth, alignment:.leading)
              
              Picker("", selection: Binding<String>(
                get: { self.widget.style.lowercased() },
                set: { self.widget.style = $0 })) {
                  Text("Transparent").tag("transparent")
                  Text("Frosted Glass").tag("glass")
                  //                  Text("Mini Browser").tag("browser")
                }
                .pickerStyle(.menu)
                .buttonStyle(.borderless)
                .frame(alignment: .leading)
                .labelsHidden()
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
            
            // MARK: Colors
            HStack(spacing:spacing - 16) {
              Label("Colors", systemImage: "ellipsis").labelStyle(.titleOnly)
                .frame(maxWidth: labelWidth, alignment:.leading)
              
              LazyVGrid(columns:columns) {
                
                HStack {
                  ColorPicker(selection: $foreColor, supportsOpacity: true) {
                    Image(systemName: "textformat.size.smaller")
                  }.frame(maxWidth:56).onChange(of: foreColor) {
                    if let hex = foreColor.toHex() { widget.foreHex = hex }
                  }.labelsHidden().scaleEffect(1.0)
                  Text("Text")
                }
                HStack {
                  ColorPicker(selection: $tintColor, supportsOpacity: true) {
                    Image(systemName: "a.square")
                  }.frame(maxWidth:56).onChange(of: tintColor) {
                    if let hex = tintColor.toHex() { widget.tintHex = hex }
                  }.labelsHidden().scaleEffect(1.0)
                  Text("Tint")
                }
                HStack {
                  ColorPicker(selection: $backColor) {
                    Image(systemName: "square.fill")
                  }.frame(maxWidth:56).onChange(of: backColor) {
                    if let hex = backColor.toHex() { widget.backHex = hex }
                  }.labelsHidden().scaleEffect(1.0)
                  Text("Back")
                }
                
              }.frame(maxWidth:.infinity)
            }
          } footer: { // MARK: Footer
            if (!showAllOptions) {
              HStack() {
                Spacer()
                Button {
                  showAllOptions.toggle()
                } label: {
                  Label("Show All Options", systemImage: "chevron.down")
                }
                .labelStyle(.iconOnly)
                .buttonBorderShape(.circle)
                .buttonStyle(.borderless)
                .frame(alignment:.center)
                Spacer()
              }
            }
          }.listRowBackground(Color.clear)
          
          
          
          
          // MARK: Advanced Options
          if (showAllOptions) {
            Section(header: Text("CSS Tweaks")){
              
              HStack(alignment: .top, spacing:spacing) {
                Label("Clear", systemImage: "link")
                  .labelStyle(.titleOnly)
                  .frame(maxWidth: labelWidth, alignment: .leading)
                TextField("transparent elements", text:$widget.clearSelectors ?? "", axis: .vertical)
                
                  .autocapitalization(.none)
                  .disableAutocorrection(true)
                  .frame(maxWidth: .infinity)
              }
              HStack(alignment: .top, spacing:spacing) {
                Label("Hide", systemImage: "link")
                  .labelStyle(.titleOnly)
                  .frame(maxWidth: labelWidth, alignment: .leading)
                TextField("removed elements",
                          text: $widget.removeSelectors ?? "",
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
            
            Section {
              
              HStack(spacing:spacing) {
                // MARK: Icon
                HStack(spacing:spacing) {
                  Label("Icon", systemImage: "link")
                    .labelStyle(.titleOnly)
                    .frame(maxWidth: labelWidth, alignment: .leading)
                  TextField("icon name", text:$widget.icon ?? "globe")
                  
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
              }
              
              // MARK: Viewport
              HStack(spacing:spacing) {
                Label("Zoom", systemImage: "link")
                  .labelStyle(.titleOnly)
                  .frame(maxWidth: labelWidth, alignment: .leading)
                
                TextField("percent", value:$widget.zoom, formatter: percentFormatter)
                
                  .autocapitalization(.none)
                  .disableAutocorrection(true)
                  .frame(maxWidth: .infinity)
                
                Label("Viewport", systemImage: "link")
                  .labelStyle(.titleOnly)
                  .frame(maxWidth: labelWidth, alignment: .leading)
                
                TextField("width", text:$widget.viewport ?? "device-width")
                  .autocapitalization(.none)
                  .disableAutocorrection(true)
                  .frame(maxWidth: .infinity)
              }
              HStack(alignment: .top, spacing:spacing) {
                Label("Config", systemImage: "link")
                  .labelStyle(.titleOnly)
                  .frame(maxWidth: labelWidth, alignment: .leading)
                TextField("json ui configuration", text:$widget.configJSON ?? "", axis: .vertical)
                  .autocapitalization(.none)
                  .disableAutocorrection(true)
                  .keyboardType(.asciiCapable)
                  .frame(maxWidth: .infinity)
              }
            } header: {
              Text("Advanced")
            } footer: {
              if let error = widget.parseError {
                Text(error)
              }
            }
          }
        }
        .frame(maxWidth: 640, maxHeight: .infinity, alignment: .center)
        
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.widgetDeleted)) { notif in
          if let anotherWidget = notif.object as? Widget, widget == anotherWidget {
            callback()
          }
        }
        // MARK: Toolbar
        .toolbar {
          
          ToolbarItemGroup(placement:.topBarTrailing) {
            
            Button {
              openWindow(id:"main")
              callback()
            } label: {
              Label("List", systemImage: "rectangle.grid.2x2")
            }
            .labelStyle(.iconOnly)
            .buttonBorderShape(.circle)
            .buttonStyle(.borderless)
            
          }
          
          ToolbarItemGroup(placement: .topBarTrailing) {
            ShareLink(
              item: widget,
              preview: SharePreview(
                "Widget \(widget.name)",
                image: Image(systemName: "plus"))
            ) {
              Image(systemName: "square.and.arrow.up")
            }
            .buttonBorderShape(.circle)
            .buttonStyle(.borderless)
            
          }
          ToolbarItemGroup(placement: .navigation) {
            Button {
              DispatchQueue.main.async { widget.save() }
              self.callback()
            } label: {
              Label("Done", systemImage: "xmark")
            }
            .labelStyle(.iconOnly)
          }
        }
      }
      .padding(min(g.size.width/32, 0)) // Collapse small size padding
    }      
    .frame(minWidth:512, minHeight:showAllOptions ? 720 : .zero)
  }
}

#Preview(windowStyle: .automatic) {
  WidgetSettingsView(widget:Widget.preview, callback: {})
}
