import SwiftUI
import CodeEditor

struct WidgetSettingsView: View {
  @Environment(\.openWindow) private var openWindow
  @Environment(\.openURL) private var openURL
  @Environment(\.dismiss) private var dismiss
  
  @State var widget: Widget
  
  @State var foreColor: Color = .white
  @State var backColor: Color = .clear
  @State var tintColor: Color = .blue
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
  let sizeWidth = 48.0
  let columns = [
    GridItem(.adaptive(minimum: 96, maximum: 480), spacing: 20)
  ]
  
  var body: some View {
    GeometryReader { g in
      NavigationStack {
        Form {
          Section(){
            
            // MARK: Location
            
            HStack(alignment: .center, spacing:spacing) {
              Text("URL")
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
              //              Menu {
              //                Button("Use Current", action: {}).disabled(true)
              //              } label: {
              //                Label("Location", systemImage: "ellipsis")
              //              }.labelStyle(.iconOnly)
              //                .buttonStyle(.borderless)
              
            }
            // MARK: Name
            HStack(spacing:spacing) {
              Text("Title")
                .labelStyle(.titleOnly)
                .frame(maxWidth: labelWidth, alignment: .leading)
              
              TextField(widget.title ?? "", text: $widget.name)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .keyboardType(.URL)
            }
            
            HStack(spacing:spacing - 18) {
              Text("Style")
                .frame(maxWidth: labelWidth, alignment:.leading)
              
              Picker("", selection: Binding<String>(
                get: { self.widget.style.lowercased() },
                set: { self.widget.style = $0 })) {
                  Text("Transparent").tag("transparent")
                  Text("Frosted Glass").tag("glass")
                  Text("Opaque").tag("opaque")
                }
                .pickerStyle(.menu)
                .buttonStyle(.borderless)
                .frame(alignment: .leading)
                .labelsHidden()
              Spacer()
              HStack {
                CustomColorPickerView(colorValue: $backColor)
                  .onChange(of: backColor) {
                    if let hex = backColor.toHex() { widget.backHex = hex }
                  }
                  .disabled(self.widget.style == "opaque")
              }
            }
            
            
          }.listRowBackground(Color.clear)
          
          
          
          
          // MARK: Advanced Options
          
          Section {
            
            
            NavigationLink {
              Form {
                
                Section() {
                  HStack(spacing:spacing) {
                    Text("Controls")
                      .frame(maxWidth: labelWidth, alignment:.leading)
                    Spacer()
                    Picker("", selection:$widget.controls ?? ControlStyle.show.rawValue) {
                      Text("Browser Toolbar").tag(ControlStyle.toolbar.rawValue)
                      Text("Show Controls").tag(ControlStyle.show.rawValue)
                      Text("Autohide Controls").tag(ControlStyle.hide.rawValue)
                      Text("Hide and Suppress Click").tag(ControlStyle.suppress.rawValue)
                      }
                      .pickerStyle(.navigationLink)
                      .buttonStyle(.borderless)
                      .frame(alignment: .leading)
                      .labelsHidden()
                  } // Controls
                  
                  NavigationLink {
                    Form {
                      
                      HStack(spacing: spacing) {
                        Text("Resize")
                          .frame(maxWidth: labelWidth , alignment:.leading)
                        Spacer()
                        Picker("", selection: Binding<String>(
                          get: { self.widget.resize ?? "" },
                          set: { self.widget.resize = $0 })) {
                            Text("Resizeable").tag("")
                            Text("Maintain Aspect Ratio").tag("uniform")
                            Text("Fixed Size").tag("none")
                          }
                        
                          .pickerStyle(.menu)
                          .buttonStyle(.borderless)
                          .frame(alignment: .trailing)
                          .labelsHidden()
                      } // Resize
                      
                      HStack(spacing:spacing) {
                        Text("Size")
                          .frame(maxWidth: labelWidth , alignment:.leading)
                        Spacer()
                        TextField("width", value:$widget.width, formatter:NumberFormatter())
                          .autocapitalization(.none)
                          .disableAutocorrection(true)
                          .frame(maxWidth: sizeWidth, alignment:.leading)
                        
                        Text("×")
                        
                        TextField("height", value:$widget.height, formatter:NumberFormatter())
                          .autocapitalization(.none)
                        
                          .multilineTextAlignment(.trailing)
                          .disableAutocorrection(true)
                          .frame(maxWidth: sizeWidth, alignment:.leading)
                        
                        
                      } // Size
                      
                      HStack(spacing:spacing) {
                        Text("Min")
                          .frame(maxWidth: labelWidth, alignment:.leading)
                        Spacer()
                        TextField("width", value:$widget.minWidth, formatter:NumberFormatter())
                          .autocapitalization(.none)
                          .disableAutocorrection(true)
                          .frame(maxWidth: sizeWidth, alignment:.leading)
                        
                        Text("×")
                        
                        TextField("height", value:$widget.minHeight, formatter:NumberFormatter())
                          .autocapitalization(.none)
                        
                          .multilineTextAlignment(.trailing)
                          .disableAutocorrection(true)
                          .frame(maxWidth: sizeWidth, alignment:.leading)
                        
                      } // Min
                      
                      HStack(spacing:spacing) {
                        Text("Max")
                          .frame(minWidth: labelWidth, alignment:.leading)
                        Spacer()
                        TextField("width", value:$widget.maxWidth, formatter:NumberFormatter())
                          .autocapitalization(.none)
                          .disableAutocorrection(true)
                          .frame(maxWidth: sizeWidth, alignment:.leading)
                        
                        Text("×")
                        TextField("height", value:$widget.maxHeight, formatter:NumberFormatter())
                          .autocapitalization(.none)
                          .multilineTextAlignment(.trailing)
                          .disableAutocorrection(true)
                          .frame(maxWidth: sizeWidth, alignment:.leading)
                        
                      } // Max
                      
                    }.navigationTitle("Window Size")
                  } label: {
                    HStack {
                      Text("Window Size")
                      Spacer()
                      Text("\(Int(widget.width)) × \(Int(widget.height))").foregroundColor(.secondary)
                    }
                 
                  } // Window Size
                  HStack(spacing:spacing) {
                    Label("Radius", systemImage: "link")
                      .labelStyle(.titleOnly)
                      .frame(maxWidth: labelWidth, alignment: .leading)
                    
                    TextField("radius", value:$widget.radius, formatter: NumberFormatter())
                      .multilineTextAlignment(.trailing)
                      .autocapitalization(.none)
                      .disableAutocorrection(true)
                      .frame(maxWidth: .infinity)
                    
    
                    HStack {
                      Button { widget.incrementRadius(-1)
                      } label: { Image(systemName: "minus") }
                      Button { widget.incrementRadius(1)
                      } label: { Image(systemName: "plus") }
                    }
                    .labelsHidden()
                    .buttonBorderShape(.circle)
                    .buttonStyle(.borderless)
                    .buttonRepeatBehavior(.enabled)
    
                  } // Radius

                  HStack(spacing:spacing) {
                    
                    Label("Zoom", systemImage: "link")
                      .labelStyle(.titleOnly)
                      .frame(maxWidth: labelWidth, alignment: .leading)
                    
                    TextField("percent", value:$widget.zoom, formatter: percentFormatter)
                      .multilineTextAlignment(.trailing)
                      .autocapitalization(.none)
                      .disableAutocorrection(true)
                      .frame(maxWidth: .infinity)
                    
                    HStack {
                      Button { widget.incrementZoom(-1)
                      } label: { Image(systemName: "minus") }
                      Button { widget.incrementZoom(1)
                      } label: { Image(systemName: "plus") }
                    }
                    .labelsHidden()
                    .buttonBorderShape(.circle)
                    .buttonStyle(.borderless)
                    .buttonRepeatBehavior(.enabled)
                  } // Zoom

                                    
                  HStack(spacing:spacing) {
                    Label("Viewport", systemImage: "link")
                      .labelStyle(.titleOnly)
                      .frame(maxWidth: labelWidth, alignment: .leading)
                    
                    TextField("width", text:$widget.viewport ?? "device-width")
                      .autocapitalization(.none)
                      .disableAutocorrection(true)
                      .multilineTextAlignment(.trailing)
                      .frame(maxWidth: .infinity)
                    
                    Menu {
                      Button {
                        widget.viewport = "device-width"
                      } label: {
                        Label("Automatic", systemImage: "rectangle.and.arrow.up.right.and.arrow.down.left")
                      }
                      Button { widget.viewport = "375" } label: {
                        Label("375", systemImage: "iphone")
                      }
                      Button { widget.viewport = "1024" } label: {
                        Label("1024", systemImage: "ipad.landscape")
                      }
                      Button { widget.viewport = "1280" } label: {
                        Label("1280", systemImage: "display")
                      }
                    } label: {
                      Image(systemName: "ellipsis")
                    }
                    .buttonStyle(.borderless)
                    .buttonBorderShape(.circle)
                    
                  } // Viewport
                  
                  HStack(spacing:spacing) {
                    Label("User Agent", systemImage: "link")
                      .labelStyle(.titleOnly)
                    
                    TextField("width", text:$widget.userAgent)
                      .autocapitalization(.none)
                      .disableAutocorrection(true)
                      .multilineTextAlignment(.trailing)
                      .frame(maxWidth: .infinity)
                    
                    Menu {
                      Button { widget.userAgent = "mobile" } label: {
                        Label("Mobile", systemImage: "iphone")
                      }
                      Button { widget.userAgent = "desktop" } label: {
                        Label("Desktop", systemImage: "display")
                      }
                    } label: {
                      Image(systemName: "ellipsis")
                    }
                    .buttonStyle(.borderless)
                    .buttonBorderShape(.circle)
                    
                  } // User Agent
                  
                 

                  
                } // Size Section
                .listRowBackground(Color.clear)
                Section() {
                  Toggle(isOn: Binding<Bool>(
                    get: { widget.effect == "dim" },
                    set: { val in widget.effect = val ? "dim" : nil}), label: {
                      Text("Dim Environment")
                    })
                  HStack(spacing:spacing - 18) {
                    Text("Blending")
                      .frame(maxWidth: labelWidth, alignment:.leading)
                    
                    Spacer()
                    Picker("", selection: $widget.blending ?? "") {
                      Text("Normal").tag("")
                      Text("Plus Lighter").tag("plusLighter")
                      Text("Plus Darker").tag("plusDarker")
                      Text("Screen").tag("screen")
                      Text("Multiply").tag("multiply")
                      }
                      .pickerStyle(.menu)
                      .buttonStyle(.borderless)
                      .frame(alignment: .leading)
                      .labelsHidden()
                  }
                  
                }
                .listRowBackground(Color.clear)
              }   .navigationTitle("View Options")
                
            } label: {
              HStack {
                Text("View Options")
                Spacer()
                Text("\(Int(widget.zoom * 100))%").foregroundColor(.secondary)
              }
            }
            
            NavigationLink {
              Form {
                Section() {
                  
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
                  HStack(spacing:spacing) {
                    Text("Colors")
                      .frame(maxWidth: labelWidth, alignment:.leading)
                    
                      HStack {
                        CustomColorPickerView(colorValue: $foreColor)
                          .onChange(of: foreColor) {
                          if let hex = foreColor.toHex() { widget.foreHex = hex }
                        }
                        Text("Text")
                      }
                      HStack {
                        
                        CustomColorPickerView(colorValue: $tintColor)
                          .onChange(of: tintColor) {
                            if let hex = tintColor.toHex() { widget.tintHex = hex }
                          }
                        Text("Tint")
                      }
                    
                  }
//                }
//                Section(header: Text("CSS Tweaks")){
                  
                  HStack(alignment: .top, spacing:spacing) {
                    Text("Clear")
                      .labelStyle(.titleOnly)
                      .frame(maxWidth: labelWidth, alignment: .leading)
                    TextField("transparent elements", text:$widget.clearSelectors ?? "", axis: .vertical)
                      .autocapitalization(.none)
                      .disableAutocorrection(true)
                      .keyboardType(.asciiCapable)
                      .frame(maxWidth: .infinity)
                  }
                  HStack(alignment: .top, spacing:spacing) {
                    Text("Hide")
                      .labelStyle(.titleOnly)
                      .frame(maxWidth: labelWidth, alignment: .leading)
                    TextField("removed elements",
                              text: $widget.removeSelectors ?? "",
                              axis: .vertical)
                    
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.asciiCapable)
                    .frame(maxWidth: .infinity)
                  }
                  HStack {
                    Text("Custom CSS")
                  }
            

                } footer: {
                  
                  CodeEditor(source: $widget.injectCSS ?? "", language: .css, indentStyle: .softTab(width: 2))
                  
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .cornerRadius(16)
                    .padding(.horizontal, -20)
                    .padding(.top, -40)
                    .keyboardType(.asciiCapable)
                    .frame(minHeight:124)
                    .navigationTitle("Style Overrides")
                }.listRowBackground(Color.clear)
              
              }
              .navigationTitle("Style Overrides")
              .navigationBarTitleDisplayMode(.inline)
              .toolbar {
                
                ToolbarItemGroup(placement: .topBarTrailing) {
                  Toggle(isOn: $widget.enableOverrides, label: {
                    Text("Enabled")
                  }).toggleStyle(.switch).labelsHidden()
            
                    
                }
              }
              
            } label: {
              Text("Style Overrides")
            }
            
            
            NavigationLink {
              Form {
                
              
                
                HStack(alignment: .center, spacing:spacing) {
                  Text("ID")
                    .labelStyle(.titleOnly)
                    .frame(maxWidth: labelWidth, alignment: .leading)
                  
                  TextField("url or directory id", text:Binding<String>(
                    get: { self.widget.manifest ?? "" },
                    set: { self.widget.manifest = $0 }))
                  .autocapitalization(.none)
                  .disableAutocorrection(true)
                  .keyboardType(.asciiCapable)
                  
                  Button {
                    widget.updateFromManifest()
                  } label: {
                    Label("Reset configuration", systemImage: "arrow.triangle.2.circlepath").labelStyle(.iconOnly)
                  }.opacity((widget.manifest?.count ?? 0) > 0 ? 1.0 : 0.0)
                }
                // MARK: Icon
                HStack(spacing:spacing) {
                  Text("Icon")
                    .labelStyle(.titleOnly)
                    .frame(maxWidth: labelWidth, alignment: .leading)
                  TextField("icon name", text:$widget.icon ?? "globe")
                  
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .frame(maxWidth: .infinity)
                }
                
                
                
                HStack(alignment: .top, spacing:spacing) {
                  Text("Config")
                    .frame(maxWidth: labelWidth, alignment: .leading)
                  TextField("json ui configuration", text:$widget.configJSON ?? "", axis: .vertical)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.asciiCapable)
                    .frame(maxWidth: .infinity)
                }

              }
            } label: {
              Text("Metadata")
            }
          } header: {
            Text("Advanced")
          } footer: {
            if let error = widget.parseError {
              Text(error)
            } else {
              Text("Learn more about how to customize a site at  \nhttps://translucent.wiki").padding(.bottom, 20)
            }
          }.listRowBackground(Color.clear)
          
        }
        //        .padding(.horizontal, -24)
        .frame(maxWidth: 640, maxHeight: .infinity, alignment: .center)
        
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.widgetDeleted)) { notif in
          if let anotherWidget = notif.object as? Widget, widget == anotherWidget {
            //            callback()
            dismiss()
          }
        }
        // MARK: Toolbar
        .toolbar {
          
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
              dismiss()
            } label: {
              Label("Done", systemImage: "xmark")
            }
            .labelStyle(.iconOnly)
          }
        }
      }
      .padding(min(g.size.width/32, 0)) // Collapse small size padding
    }
    .frame(minWidth:400, maxHeight:600)
  }
}

#Preview(windowStyle: .plain) {
  WidgetSettingsView(widget:Widget.preview).frame(maxWidth:400, maxHeight:600)
}
