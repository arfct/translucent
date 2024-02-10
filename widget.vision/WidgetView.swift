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
  
  func toggleSettings() {
    withAnimation(.spring) { flipped.toggle() }
  }

  var body: some View {
    GeometryReader { geometry in
      VStack(alignment: .center) {
        ZStack(alignment: .bottomTrailing) {
          WebView(title: $widget.name, location: $widget.location, widgetModel: $widget)
            .onLoadStatusChanged { loading, error in
              self.isLoading = loading
                if let error = error {
                  print("Error: \(error)")
                }
            }
            .disabled(flipped)
            .opacity(flipped ? 0.0 : 1.0)
            .glassBackgroundEffect(in:RoundedRectangle(cornerRadius: widget.radius), 
                                   displayMode: (widget.style == .glass ) ? .always : .never)
            .cornerRadius(widget.style != .glass ? 20 : 10)

          WidgetSettingsView(widgetModel:$widget, callback: toggleSettings)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .glassBackgroundEffect(in:RoundedRectangle(cornerRadius: widget.radius))
            .offset(z: 1)
            .opacity(flipped ? 1.0 : 0.0)
            .rotation3DEffect(.degrees(180), axis: (0, 1, 0), anchor: UnitPoint3D(x: 0.5, y: 0, z: 0))
            .disabled(!flipped)
          
        }
        .ornament(attachmentAnchor: .scene(.top)) {
          ZStack {
            if widget.isLoading {
              ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                .scaleEffect(1.0, anchor: .center)
            }
            Button("•", systemImage: "circle.fill") { toggleSettings() }
              .buttonBorderShape(.circle)
              .tint(.primary)
              .buttonStyle(.borderless)
              .transition(.move(edge: .top))
              .buttonStyle(.automatic)
              .labelStyle(.titleOnly)
              .hoverEffect()
              .opacity(1.0)
            
          }
        }
      }
      .rotation3DEffect(.degrees(flipped ? 180.0 : 0.0), axis: (0, 1, 0), anchor: UnitPoint3D(x: 0.5, y: 0, z: 0))
    }
    .frame(width: widget.width, height: widget.height)

  }
  
}

#Preview(windowStyle: .plain) {
    WidgetView(widget: Widget(name: "Test", location: "https://example.com", style: .glass))
}
