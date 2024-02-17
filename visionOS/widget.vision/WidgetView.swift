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
  var app: WidgetApp?


  @State private var flipped: Bool = false
  @State var isLoading: Bool = true
  @State var showOrnaments: Bool = true
  @State var ornamentTimer: Timer?
  @State var clampInitialSize: Bool = true
  @State var foreColor: Color = .white
  func toggleSettings() {
    withAnimation(.spring) {
      try? modelContext.save()
      flipped.toggle()
    }
  }
  
  // Webview var
  private var webView: WebView {
    WebView(title: $widget.title, location: $widget.location, widget: $widget)
  }
  
  
  var body: some View {
    GeometryReader { geometry in
      VStack(alignment: .center) {
        ZStack(alignment: .bottomTrailing) {
          if (!flipped) {
            webView
              .onLoadStatusChanged { content, loading, error in
                self.isLoading = loading
                if let error = error { print("Loading error: \(error)") }
              }
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .disabled(flipped)
              .opacity(flipped ? 0.0 : 1.0)
              .glassBackgroundEffect(in:RoundedRectangle(cornerRadius: widget.radius),
                                     displayMode: (widget.style == .glass ) ? .always : .never)
              .background(widget.backColor)
              .cornerRadius(widget.radius)
              .gesture(TapGesture().onEnded({ gesture in
                showOrnaments = true
                scheduleHide()
              
              }))
          }
          WidgetSettingsView(widget:widget, callback: toggleSettings)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(widget.backColor.opacity(0.2))
            .glassBackgroundEffect(in:RoundedRectangle(cornerRadius: widget.radius))
            .offset(z: flipped ? 1 : 0)
            .opacity(flipped ? 1.0 : 0.0)
            .rotation3DEffect(.degrees(180), axis: (0, 1, 0), anchor: UnitPoint3D(x: 0.5, y: 0, z: 0))
            .disabled(!flipped)
        }
//        .sheet(isPresented: $flipped) {
//          WidgetSettingsView(widget:widget, callback: toggleSettings)
//            .frame(maxWidth:.infinity)
//        }.frame(maxWidth:.infinity)
        .ornament(attachmentAnchor: .scene(flipped ? .topLeading : .topTrailing)) {
          ZStack {
            Button { } label: {
              if isLoading {
                ProgressView()
                  .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                  .scaleEffect(1.0, anchor: .center)
              } else {
                Image(systemName: flipped ? "arrow.backward" : "info")
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .frame(width: 16, height: 16)
              }
            }
            .onDrag {
              let userActivity = NSUserActivity(activityType: Activity.openSettings)
              
              try? userActivity.setTypedPayload(["modelId": widget.modelID])
              let itemProvider = NSItemProvider(object: widget.id.uuidString as NSString)
              itemProvider.registerObject(userActivity, visibility: .all)
              return itemProvider
            } preview: {
              Button { } label: {
                  Image(systemName: flipped ? "arrow.backward" : "info")
                    .resizable()
                    .buttonBorderShape(.circle)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
                
              }
            }
            .simultaneousGesture(LongPressGesture().onEnded { _ in
//              openWindow(id:"main")
              app?.openWindow(id: "widgetSettings", value: widget.modelID)
            })
            .simultaneousGesture(TapGesture().onEnded {
              toggleSettings()
            })
            .buttonBorderShape(.circle)
            .glassBackgroundEffect()
            .transition(.move(edge: .top))
            .buttonStyle(.automatic)
            .labelStyle(.iconOnly)
            .hoverEffect()
            .opacity(showOrnaments && !flipped ? 1.0 : 0.0)
            .animation(.spring(), value: flipped)
            
          }
        }
      }
      .rotation3DEffect(.degrees(flipped ? -180.0 : 0.0), axis: (0, 1, 0), anchor: UnitPoint3D(x: 0.5, y: 0, z: 0))
      .onChange(of: geometry.size) {
        widget.width = geometry.size.width
        widget.height = geometry.size.height
        print("↔️ Widget size changed to \(widget.width)×\(widget.height)")
        try? modelContext.save()
       }
      .onDisappear {
        try? modelContext.save()
      }
    }
    
    // Clamp the size initially to set the base size, but then allow it to change later.
    .frame(minWidth: clampInitialSize ? widget.width : widget.minWidth, idealWidth: widget.width, maxWidth: clampInitialSize ? widget.width : widget.maxWidth,
           minHeight: clampInitialSize ? widget.height : widget.minHeight, idealHeight: widget.height, maxHeight: clampInitialSize ? widget.height : widget.maxHeight)
    
    .persistentSystemOverlays(showOrnaments ? .automatic : .hidden)
  
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
