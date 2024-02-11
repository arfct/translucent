import SwiftUI

struct WidgetSettingsView: View {
  @Environment(\.openWindow) private var openWindow
  
  @Binding var widget: Widget
  var callback: () -> Void
  
  @State var foreColor: Color = .white
  @State var backColor: Color = .clear
  @State var tintColor: Color = .blue
  
  @FocusState private var isTextFieldFocused: Bool
  @State private var locationTempString: String = "about:blank"
  @State private var selectedOption: String = "Option1"
  
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
  var body: some View {
    ScrollView {
      VStack(alignment:.leading, spacing: 20) { // Settings
        HStack() {
          TextField("location", text: $locationTempString)
            .textFieldStyle(.roundedBorder)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .keyboardType(.URL)
            .onAppear {
              locationTempString = widget.location!
              backColor = widget.backColor
              foreColor = widget.foreColor
              tintColor = widget.tintColor
            }
            .onSubmit {
              print(locationTempString)
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
          
          Menu {
            Button("Use Current", action: {
              // Handle Option 1 tap
            }).disabled(true)
            Divider()
            Picker("User Agent", selection: $selectedOption) {
              Text("Mobile")
              Text("Desktop")
              Text("Custom")
            }.disabled(true)
          } label: {
            Image(systemName: "ellipsis")
          }.buttonStyle(.borderless)
          
        }
        
        
        HStack {
          ColorPicker(selection: $backColor, supportsOpacity: true) {}
            .labelsHidden()
            .onChange(of: backColor) {
              if let hex = backColor.toHex() { widget.backHex = hex }
            }
          
          Picker("Select an option", selection: $widget.style) {
            ForEach(ViewStyle.allCases, id: \.self) { value in
              HStack {
                Text(value.localizedName)
                  .tag(value)
                Image(systemName: value.iconName)
              }
            }
          }
        }
        
        // Foreground
        HStack {
          
          ColorPicker(selection: $foreColor, supportsOpacity: true) {}
            .labelsHidden()
            .onChange(of: foreColor) {
              if let hex = foreColor.toHex() {
                print("changed \(hex)")
                widget.foreHex = hex
              }
            }
          
          TextField("default font", text:$widget.fontName)
            .textFieldStyle(.roundedBorder)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            
//          Picker("Select an option", selection: $widgetModel.font) {
//            ForEach(ViewStyle.allCases, id: \.self) { value in
//              Text("System font")
//            }
//          }
        }
        
        Spacer()
        
      }.padding()
      HStack {
        ShareLink(
          item: URL(string: widget.shareURL)!,
          preview: SharePreview(
            "Widget \(widget.name ?? "")",
                               image: Image(systemName: "plus"))
        
        ) {
          Image(systemName: "square.and.arrow.up")
        }            .buttonBorderShape(.circle)

//        Button("Close") {
//          callback()
//        }
        Button("All Widgets") {
          openWindow(id: "main")
        }
      }
    }
  }
  func shareWidget() {
    
  }
}

//#Preview {
//  WidgetSettingsView(selectedViewStyle: <#Binding<String>#>, locString: <#Binding<String>#>, callback: <#() -> Void#>)
//}
