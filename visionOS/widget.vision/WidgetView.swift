import SwiftUI
import SwiftData
import RealityKit
import RealityKitContent
import Combine

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
  @State var showOrnaments: Bool = true
  @State var ornamentTimer: Timer?
  @State var clampInitialSize: Bool = true
  
  func toggleSettings() {
    withAnimation(.spring) {
      
      try? modelContext.save()
      flipped.toggle()
    }
    
  }
  
  var body: some View {
    GeometryReader { geometry in
      VStack(alignment: .center) {
        ZStack(alignment: .bottomTrailing) {
          if (!flipped) {
            WebView(title: $widget.name, location: $widget.location, widget: $widget)
              .onLoadStatusChanged { content, loading, error in
                print("Loading - \(loading ? widget.location ?? "" : "done")")
                self.isLoading = loading
                if let error = error {
                  print("Error: \(error)")
                }
              }
              .frame(maxWidth: .infinity, maxHeight: .infinity)
            
              .disabled(flipped)
              .offset(z:flipped ? 1 : 0)
              .opacity(flipped ? 0.0 : 1.0)
              .background(widget.backColor)
              .glassBackgroundEffect(in:RoundedRectangle(cornerRadius: widget.radius),
                                     displayMode: (widget.style == .glass ) ? .always : .never)
              .cornerRadius(widget.style != .glass ? 20 : 10)
          }
          WidgetSettingsView(widget:$widget, callback: toggleSettings)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .background(widget.backColor.opacity(0.2))
            .glassBackgroundEffect(in:RoundedRectangle(cornerRadius: widget.radius))
            .offset(z: flipped ? 1 : 0)
            .opacity(flipped ? 1.0 : 0.0)
            .rotation3DEffect(.degrees(180), axis: (0, 1, 0), anchor: UnitPoint3D(x: 0.5, y: 0, z: 0))
            .disabled(!flipped)
        }
        .ornament(attachmentAnchor: .scene(flipped ? .topLeading : .topTrailing)) {
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
            .opacity(flipped || showOrnaments ? 1.0 : 0.0)
            .animation(.spring)
            
          }
        }
      }
      .rotation3DEffect(.degrees(flipped ? -180.0 : 0.0), axis: (0, 1, 0), anchor: UnitPoint3D(x: 0.5, y: 0, z: 0))
      

      .onChange(of: geometry.size) {
        print("Size: \(geometry.size)");
        widget.width = geometry.size.width
        widget.height = geometry.size.height
        try? modelContext.save()
       }
    }
    .frame(minWidth: clampInitialSize ? widget.width : .zero, idealWidth: widget.width, maxWidth: clampInitialSize ? widget.width : .infinity,
           minHeight: clampInitialSize ? widget.height : .zero, idealHeight: widget.height, maxHeight: clampInitialSize ? widget.height : .infinity)
    
    .persistentSystemOverlays(showOrnaments ? .automatic : .hidden)
    
    .gesture(TapGesture().onEnded({ gesture in
      showOrnaments = true
      scheduleHide()
    
    }))
    .task{
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) { clampInitialSize = false }
      scheduleHide()
    }
    
  }
  
  func scheduleHide() {
    ornamentTimer?.invalidate()
    ornamentTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false, block: { timer in
      showOrnaments = false
    })
  }
}


//#Preview(windowStyle: .plain) {
//    WidgetView(widget: Widget(name: "Test", location: "https://example.com", style: .glass))
//}