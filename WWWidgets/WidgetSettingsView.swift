//
//  WidgetSettingsView.swift
//  ittybittywidgets
//
//  Created by Nicholas Jitkoff on 2/2/24.
//

import SwiftUI


struct WidgetSettingsView: View {
  @Binding var widgetModel: WidgetModel
  var callback: () -> Void
  
  @FocusState private var isTextFieldFocused: Bool
  @State private var locationTempString: String = "about:blank"
  @State private var locationTempString2: String = "about:blank"
  
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
      Label("Style", image: "link")
      
      Picker("Select an option", selection: $widgetModel.style) {
        ForEach(ViewStyle.allCases, id: \.self) { value in
          Text(value.localizedName)
            .tag(value)
        }
      }
      
//      TextField("flags", text: $widgetModel.flags)
//        .textFieldStyle(.roundedBorder)
//        .autocapitalization(.none)
//        .disableAutocorrection(true)
//        .keyboardType(.URL)
//
//      TextField("zoom", value: $widgetModel.zoom, formatter: NumberFormatter())
//        .textFieldStyle(.roundedBorder)
//        .keyboardType(.numberPad)

//      HStack {
        Label("Location", image: "link")
//        Spacer()
//        Button("Use Current") {
//          
//        }
//      }
      
      TextField("location2", text: $locationTempString2)
      TextField("location", text: $locationTempString)
        .textFieldStyle(.roundedBorder)
        .autocapitalization(.none)
        .disableAutocorrection(true)
        .keyboardType(.URL)
        .onAppear {
          locationTempString = widgetModel.location
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
        .onChange(of: isTextFieldFocused) { focus in
            if focus {
                DispatchQueue.main.async {
                    UIApplication.shared.sendAction(#selector(UIResponder.selectAll(_:)), to: nil, from: nil, for: nil)
                }
            }
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
