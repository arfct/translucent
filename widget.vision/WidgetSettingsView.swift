import SwiftUI

struct WidgetSettingsView: View {
  @Binding var widgetModel: Widget
  var callback: () -> Void
  
  @State var fore: Color = .white
  @State var back: Color = .clear
  @State var tint: Color = .blue
  
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
    VStack(alignment:.leading, spacing: 20) { // Settings
      HStack() {
        TextField("location", text: $locationTempString)
          .textFieldStyle(.roundedBorder)
          .autocapitalization(.none)
          .disableAutocorrection(true)
          .keyboardType(.URL)
          .onAppear {
            locationTempString = widgetModel.location!
          }
          .onSubmit {
            print(locationTempString)
            if let url = clean(url:locationTempString) {
              widgetModel.location = url
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
      
      
      
//      Label("Style", image: "link")
      
      // background
      HStack {
        
        ColorPicker(selection: $back, supportsOpacity: true) {
          Image(systemName: "square.fill")
        }.labelsHidden()
        
        Picker("Select an option", selection: $widgetModel.style) {
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
        
        ColorPicker(selection: $fore, supportsOpacity: true) {
          Image(systemName: "textformat.size")
        }.onChange(of: fore) {
          widgetModel.color = fore.description
          callback()
        }.labelsHidden()
          .disabled(true)
        
        Picker("Select an option", selection: $widgetModel.style) {
          ForEach(ViewStyle.allCases, id: \.self) { value in
            Text("System font")
          }
        }.disabled(true)
      }
      
      Spacer()
      Button("Done") {
        callback()
      }
    }.padding()
  }
}

//#Preview {
//  WidgetSettingsView(selectedViewStyle: <#Binding<String>#>, locString: <#Binding<String>#>, callback: <#() -> Void#>)
//}
