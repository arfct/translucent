import SwiftUI

struct WidgetViewBrowserBar: View {
  @Binding var widget: Widget;
  @Binding var browserState: BrowserState;
  
  var infoCallback: () -> Void
  @FocusState private var isTextFieldFocused: Bool
  @State private var locationTempString: String = "about:blank"
    var body: some View {
      HStack {
        Button {
          browserState.coordinator?.webView.goBack()
        } label: {
          Label("Back", systemImage: "chevron.left").labelStyle(.iconOnly)
        }.buttonBorderShape(.circle)
          .buttonStyle(.borderless)
          .disabled(!browserState.canGoBack)
        
        if browserState.canGoForward {
          Button {
            browserState.coordinator?.webView.goForward()

          } label: {
            Label("Forward", systemImage: "chevron.right").labelStyle(.iconOnly)
          }
        }
        
        TextField("location", text:$locationTempString )
        .textFieldStyle(.roundedBorder)
        .cornerRadius(20)
        .autocapitalization(.none)
        .disableAutocorrection(true)
        .keyboardType(.URL)
        .onAppear {
//          isTextFieldFocused ? browserState.url.absoluteString : browserState.url.host()?.replacingOccurrences(of: "www.", with: "") ?? ""
          if let location = widget.location {
            locationTempString = location.replacingOccurrences(of: "https://", with: "")
          }
        }
        
          .onSubmit {
            console.log("location \(locationTempString)" )
            if let location = clean(url:locationTempString),
            let url = URL(string: location) {
              console.log("coordinator \(location)")
              browserState.coordinator?.open(location: location)
            }
          }
        
          .focused($isTextFieldFocused)
          .onChange(of: isTextFieldFocused) {
            if isTextFieldFocused {
              DispatchQueue.main.async {
                UIApplication.shared.sendAction(#selector(UIResponder.selectAll(_:)), to: nil, from: nil, for: nil)
              }
            } else {
//              commitLocation()
            }
          }
        
        Button {
          infoCallback()
        } label: {
          Label("info", systemImage: "gear").labelStyle(.iconOnly)
        }
        .buttonBorderShape(.circle)
          .buttonStyle(.borderless)
      }
      .padding(8)
      .frame(minWidth:310, maxWidth:isTextFieldFocused ? .infinity :  400)
      .glassBackgroundEffect()
      .padding(.bottom, 8)
    }
}

//#Preview {
//    WidgetViewToolbar()
//}
