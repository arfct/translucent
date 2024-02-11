import SwiftUI
import SwiftData
import RealityKit
import RealityKitContent

extension Animation {
  static func ripple() -> Animation {
    Animation.spring(dampingFraction: 0.5)
      .speed(2)
  }
}

struct WidgetView: View {
  @Environment(\.openWindow) var openWindow
  @Environment(\.isFocused) var isFocused
  @Environment(\.modelContext) private var modelContext
  
  @State var widget: Widget
  @State private var flipped: Bool = false
  @State var isLoading: Bool = true
  @State var settingsButtonVisible: Bool = true
  
  
  @State var startingUp: Bool = true
  
  func toggleSettings() {
    withAnimation(.spring) { flipped.toggle() }
  }
  
  var body: some View {
    VStack(alignment: .center) {
      ZStack(alignment: .bottomTrailing) {
        WebView(title: $widget.name, location: $widget.location, widget: $widget)
          .onLoadStatusChanged { content, loading, error in
            print("status: \(loading)")
            self.isLoading = loading
            if let error = error {
              print("Error: \(error)")
            }
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)

          .disabled(flipped)
          .opacity(flipped ? 0.0 : 1.0)
          .background(widget.backgroundColor)
          .glassBackgroundEffect(in:RoundedRectangle(cornerRadius: widget.radius),
                                 displayMode: (widget.style == .glass ) ? .always : .never)
          .cornerRadius(widget.style != .glass ? 20 : 10)
        
        WidgetSettingsView(widgetModel:$widget, callback: toggleSettings)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .padding()
          .glassBackgroundEffect(in:RoundedRectangle(cornerRadius: widget.radius))
          .offset(z: flipped ? 1 : 0)
          .opacity(flipped ? 1.0 : 0.0)
          .rotation3DEffect(.degrees(180), axis: (0, 1, 0), anchor: UnitPoint3D(x: 0.5, y: 0, z: 0))
          .disabled(!flipped)
        
      }
      .ornament(attachmentAnchor: .scene(.topLeading)) {
        ZStack {
          if widget.isLoading {
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle(tint: .primary))
              .scaleEffect(1.0, anchor: .center)
          }
          Button("•", systemImage: flipped ? "arrow.backward" : "info") {
            toggleSettings()
          }
          .buttonBorderShape(.circle)
          .glassBackgroundEffect()
          .transition(.move(edge: .top))
          .buttonStyle(.automatic)
          .labelStyle(.iconOnly)
          .hoverEffect()
          .opacity(flipped || settingsButtonVisible ? 1.0 : 0.0)
          .animation(.spring)
          
        }
      }
    }
    .rotation3DEffect(.degrees(flipped ? 180.0 : 0.0), axis: (0, 1, 0), anchor: UnitPoint3D(x: 0.5, y: 0, z: 0))
    
    .frame(minWidth: 100, idealWidth: widget.width, maxWidth: startingUp ? widget.width : 800,
           minHeight: 100, idealHeight: widget.height, maxHeight: startingUp ? widget.height : 800)
    
    .persistentSystemOverlays(.hidden)
    //    .gesture(TapGesture().onEnded({ gesture in
    //      settingsButtonVisible = true
    //      DispatchQueue.main.asyncAfter(deadline: .now() +  3) {
    //        settingsButtonVisible = false
    //      }
    //    }))
    
  }
  
}

//#Preview(windowStyle: .plain) {
//    WidgetView(widget: Widget(name: "Test", location: "https://example.com", style: .glass))
//}
