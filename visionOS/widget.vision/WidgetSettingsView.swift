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
    GridItem(.adaptive(minimum: 240, maximum: 480), spacing: 20)
  ]
  
  
  var body: some View {
    GeometryReader { g in
      ScrollView {
        
        // MARK: Toolbar
        HStack(spacing:20){
          
          Button { self.callback() } label: {
            Label("Done", systemImage: "chevron.left")
          }
          .labelStyle(.titleOnly)
          
          Spacer(minLength: 0)
          
          Button { openWindow(id:"main") } label: {
            Label("List", systemImage: "rectangle.grid.2x2")
          }
          .labelStyle(.iconOnly)
          .buttonBorderShape(.circle)
          .buttonStyle(.borderless)
          
          ShareLink(
            item: URL(string: widget.shareURL)!,
            preview: SharePreview(
              "Widget \(widget.name)",
              image: Image(systemName: "plus"))
          ) {
            Image(systemName: "square.and.arrow.up")
          }
          .buttonBorderShape(.circle)
          .buttonStyle(.borderless)
          
          // MARK: Menu
          Menu {
            Button("User Agent", action: {}).disabled(true)
            Picker("User Agent", selection: $widget.userAgent) {
              Text("Mobile").tag("mobile")
              Text("Desktop").tag("desktop")
            }
            Divider()
            Button("Show All Options", action: {
              showAllOptions = true
            })
          } label: {
            Label("Location", systemImage: "ellipsis")
          }.labelStyle(.iconOnly)
            .buttonStyle(.borderless)
        }.padding()
        VStack(alignment:.leading, spacing: 20) { // Settings
          
          
          
          // MARK: Style
          LazyVGrid(columns: columns, spacing: 20) {
            HStack() {
              Text("Style").frame(maxWidth: labelWidth, alignment: .leading)
              Picker("Style", selection: $widget.style) {
                ForEach(ViewStyle.allCases, id: \.self) { value in
                  HStack {
                    Text(value.displayName)
                      .tag(value)
                      .frame(maxWidth: .infinity, alignment:.leading)
                    Image(systemName: value.iconName)
                  }
                }
              }
              .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            }.frame(maxWidth:.infinity, alignment:.leading)
            HStack(spacing:10) {
              Spacer()
              ColorPicker(selection: $backColor) {
                Image(systemName: "square.fill")
              }.frame(maxWidth:56).onChange(of: backColor) {
                if let hex = backColor.toHex() { widget.backHex = hex }
              }
              ColorPicker(selection: $foreColor, supportsOpacity: true) {
                Image(systemName: "textformat.size.smaller")
              }.frame(maxWidth:56).onChange(of: foreColor) {
                if let hex = foreColor.toHex() { widget.foreHex = hex }
              }
              ColorPicker(selection: $tintColor, supportsOpacity: true) {
                Image(systemName: "a.square")
              }.frame(maxWidth:56).onChange(of: tintColor) {
                if let hex = tintColor.toHex() { widget.tintHex = hex }
              }
            }.frame(maxWidth:.infinity)
          }
          
          
          // MARK: Location
          HStack(spacing:spacing) {
            HStack {
              Label("URL", systemImage: "ellipsis").labelStyle(.titleOnly)
              
              
            }.frame(maxWidth: labelWidth, alignment: .leading)
            
            TextField("location", text: $locationTempString)
              .textFieldStyle(.roundedBorder)
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
            
          }
          
          // MARK: Name
          HStack(spacing:spacing) {
            Label("Title", systemImage: "link")
              .labelStyle(.titleOnly)
              .frame(maxWidth: labelWidth, alignment: .leading)
            
            TextField(widget.title ?? "", text: $widget.name)
              .textFieldStyle(.roundedBorder)
            
              .autocapitalization(.none)
              .disableAutocorrection(true)
              .keyboardType(.URL)
          }
          
          
          // MARK: Font
          HStack(spacing:spacing) {
            Text("Font")
              .frame(maxWidth: labelWidth, alignment:.leading)
            
            
            TextField("default font", text:$widget.fontName)
              .textFieldStyle(.roundedBorder)
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
              fontMenu = widget.fontName
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
          }
          
          if (showAllOptions) {
            
            LazyVGrid(columns: columns, spacing: 20) {
              // MARK: Icon
              HStack(spacing:spacing) {
                Label("Icon", systemImage: "link")
                  .labelStyle(.titleOnly)
                  .frame(maxWidth: labelWidth, alignment: .leading)
                TextField("icon name", text:$widget.icon)
                  .textFieldStyle(.roundedBorder)
                  .autocapitalization(.none)
                  .disableAutocorrection(true)
                  .frame(maxWidth: .infinity)
              }
              HStack(spacing:spacing) {
                Label("Radius", systemImage: "link")
                  .labelStyle(.titleOnly)
                  .frame(maxWidth: labelWidth, alignment: .leading)
                  
                TextField("radius", value:$widget.radius, formatter: NumberFormatter())
                  .textFieldStyle(.roundedBorder)
                  .autocapitalization(.none)
                  .disableAutocorrection(true)
                  .frame(maxWidth: .infinity)
              }
              
              // MARK: Viewport
              HStack(spacing:spacing) {
                Label("Zoom", systemImage: "link")
                  .labelStyle(.titleOnly)
                  .frame(maxWidth: labelWidth, alignment: .leading)
                  
                TextField("zoom", value:$widget.zoom, formatter: NumberFormatter())
                  .textFieldStyle(.roundedBorder)
                  .autocapitalization(.none)
                  .disableAutocorrection(true)
                  .frame(maxWidth: .infinity)
              }
              
              HStack(spacing:spacing) {
                Label("Viewport", systemImage: "link")
                  .labelStyle(.titleOnly)
                  .frame(maxWidth: labelWidth, alignment: .leading)
                  
                TextField("viewport", value:$widget.viewportWidth, formatter: NumberFormatter())
                  .textFieldStyle(.roundedBorder)
                  .autocapitalization(.none)
                  .disableAutocorrection(true)
                  .frame(maxWidth: .infinity)
              }
            }

            
            // MARK: Overrides
            //          HStack(spacing:spacing) {
            //            Label("Hide", systemImage: "link")
            //              .labelStyle(.titleOnly)
            //              .frame(maxWidth: leftColumn, alignment: .leading)
            //            TextField("clear classes", text:$widget.clearClasses ?? Binding.constant("my string"))
            //              .textFieldStyle(.roundedBorder)
            //              .autocapitalization(.none)
            //              .disableAutocorrection(true)
            //              .frame(maxWidth: .infinity)
            //            TextField("remove classes", text:$widget.removeClasses)
            //              .textFieldStyle(.roundedBorder)
            //              .autocapitalization(.none)
            //              .disableAutocorrection(true)
            //              .frame(maxWidth: .infinity)
            //          }
            
          }
          
        }.padding(.horizontal, 20)
          .padding(.top, 20)
          .frame(maxWidth: 640, maxHeight: .infinity, alignment: .center)
      }
      .padding(min(g.size.width/32, 20)) // Collapse small size padding
    }
  }
}

#Preview(windowStyle: .automatic) {
  WidgetSettingsView(widget:Widget.preview, callback: {})
}
