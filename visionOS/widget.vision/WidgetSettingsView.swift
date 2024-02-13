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
  let leftColumn = 120.0
  
  var body: some View {
    
    ScrollView {
      HStack(spacing:20){
        Button {
          print("back")
          self.callback()
        } label: {
          Label("Done", systemImage: "arrow.left")
        }
        .buttonBorderShape(.circle)
        .labelStyle(.iconOnly)
        Spacer()
        
        Button {
          openWindow(id:"main")
        } label: {
          Label("List", systemImage: "rectangle.grid.2x2")
        }
        .labelStyle(.iconOnly)
        .buttonBorderShape(.circle)
        
        .buttonStyle(.borderless)
        ShareLink(
          item: URL(string: widget.shareURL)!,
          preview: SharePreview(
            "Widget \(widget.name ?? "")",
            image: Image(systemName: "plus"))
          
        ) {
          Image(systemName: "square.and.arrow.up")
        }            .buttonBorderShape(.circle)
        
          .buttonStyle(.borderless)
        
        Menu {
          Button("Use Current", action: {
            // Handle Option 1 tap
          }).disabled(true)
          Divider()
          Picker("User Agent", selection: $widget.userAgent) {
            Text("Mobile").tag("mobile")
            Text("Desktop").tag("desktop")
            //              Text("Custom").tag("custom")
          }
          
          
        } label: {
          Label("Location", systemImage: "ellipsis")
        }.labelStyle(.iconOnly)
          .buttonStyle(.borderless)
      }.padding()
      VStack(alignment:.leading, spacing: 20) { // Settings
        
        
        HStack(spacing:spacing) {
          HStack {
            Label("Location", systemImage: "ellipsis").labelStyle(.titleOnly)
            
            
          }.frame(maxWidth: leftColumn, alignment: .leading)
          
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
          
        }
        
        
        HStack(spacing:spacing) {
          Label("Title", systemImage: "link")
            .labelStyle(.titleOnly)
            .frame(maxWidth: leftColumn, alignment: .leading)
          
          TextField(widget.title ?? "", text: $widget.name)
            .textFieldStyle(.roundedBorder)
          
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .keyboardType(.URL)
        }
        HStack(spacing:spacing) {
          ColorPicker(selection: $backColor, supportsOpacity: true) {
            Text("Style")
          }
          .frame(maxWidth: leftColumn)
          .onChange(of: backColor) {
            if let hex = backColor.toHex() { widget.backHex = hex }
          }
          Picker("Select an option", selection: $widget.style) {
            ForEach(ViewStyle.allCases, id: \.self) { value in
              HStack {
                Text(value.localizedName)
                  .tag(value)
                  .frame(maxWidth: .infinity, alignment:.leading)
//                Image(systemName: value.iconName)
              }
            }
          }
          .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
          
          
          
        }
        
        // Foreground
        HStack(spacing:spacing) {
          
          ColorPicker(selection: $foreColor, supportsOpacity: true) {
            Text("Font")
          }
          
          .frame(maxWidth: leftColumn)
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
            .frame(maxWidth: .infinity)
          //          Picker("Select an option", selection: $widgetModel.font) {
          //            ForEach(ViewStyle.allCases, id: \.self) { value in
          //              Text("System font")
          //            }
          //          }
        }
        
        Spacer()
        
      }.padding(.horizontal, 20)
        .padding(.top, 20)
        .frame(maxWidth: 640, maxHeight: .infinity, alignment: .center)
      
      //          .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
      
      
      
      
      
    }
  }
}

//#Preview {
//  WidgetSettingsView(selectedViewStyle: <#Binding<String>#>, locString: <#Binding<String>#>, callback: <#() -> Void#>)
//}
