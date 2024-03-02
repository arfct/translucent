import SwiftUI
import SwiftData
import RealityKit
import RealityKitContent
import Combine
import QuickLook

struct WidgetView: View {
  @Environment(\.openWindow) var openWindow
  @Environment(\.dismissWindow) var dismissWindow
  @Environment(\.dismiss) var dismiss
  @Environment(\.isFocused) var isFocused
  @Environment(\.modelContext) private var modelContext
  @Environment(\.scenePhase) private var scenePhase
  
  @State var widget: Widget
  var app: WidgetApp?
  
  @State var id = UUID()
  @State private var flipped: Bool = false
  @State var isLoading: Bool = true
  @State var finishedFirstLoad: Bool = false
  @State var loadedWindow: Bool = false
  @State var showInfo: Bool = false
  @State var showHandle: Bool = true
  @State var ornamentTimer: Timer?
  @State var clampInitialSize: Bool = true
  @State var foreColor: Color = .white
  @State var currentPhase: ScenePhase = .active
  @State var wasBackgrounded = false
  @State var lastActivation = Date()
  @State var downloadAttachment: URL?
  @State var downloads: [URL] = []
  
  func toggleSettings() {
    withAnimation(.spring) {
      flipped.toggle()
    }
  }
  
  var body: some View {
    GeometryReader { geometry in
      VStack(alignment: .center) {
        
        ZStack(alignment: .center) {
          
          if (!flipped) {
            
            // MARK: Web View
            WebView(title: $widget.title,
                    location: $widget.location,
                    widget: $widget,
                    phase:$currentPhase,
                    attachment:$downloadAttachment)
            .onLoadStatusChanged { content, loading, error in
              self.isLoading = loading
              if (!loading && !finishedFirstLoad) {
                withAnimation(.easeInOut(duration: 1.0)) {
                  finishedFirstLoad = true;
                }
                scheduleHide()
              }
              if let error = error { print("Loading error: \(error)") }
            }
            .onDownloadCompleted { content, download, error in
              downloads.append(download)
              downloadAttachment = download;
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .disabled(flipped)
            .glassBackgroundEffect(in:RoundedRectangle(cornerRadius: widget.radius),
                                   displayMode: (widget.showGlassBackground ) ? .always : .never)
            .background(widget.backColor)
            .cornerRadius(widget.radius)
            .opacity(flipped || !finishedFirstLoad || !loadedWindow ? 0.05 : 1.0)
            .gesture(TapGesture().onEnded({ gesture in
              showInfo = true
              showHandle = true
              scheduleHide()
            }))
          } else {
            
            WidgetSettingsView(widget:widget, callback: toggleSettings)
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .background(widget.backColor.opacity(0.2))
              .glassBackgroundEffect(in:RoundedRectangle(cornerRadius: 30))
              .offset(z: flipped ? 1 : 0)
              .opacity(flipped ? 1.0 : 0.0)
              .rotation3DEffect(.degrees(180), axis: (0, 1, 0), anchor: UnitPoint3D(x: 0.5, y: 0, z: 0))
              .disabled(!flipped)
          }
        }
        .overlay(alignment: .center) {
          if (!finishedFirstLoad) {
            ProgressView()
          }
        }
        
        // MARK: Info Button
        .ornament(attachmentAnchor: .scene(.top), contentAlignment:.bottom) {
          ZStack {
            Button { } label: {
              if isLoading && finishedFirstLoad {
                ProgressView()
                  .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                  .scaleEffect(1.0, anchor: .center)
              } else {
                Image(systemName: "info")
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .frame(width: 16, height: 16)
              }
            }
            .onDrag {
              let userActivity = NSUserActivity(activityType: Activity.openSettings)
              userActivity.targetContentIdentifier = "settings"
              try? userActivity.setTypedPayload(["modelId": widget.modelID])
              let itemProvider = NSItemProvider(object: widget.id.uuidString as NSString)
              itemProvider.registerObject(userActivity, visibility: .all)
              return itemProvider
            } preview: {
              ZStack {
                Text("Widget Settings")
              }.frame(width:100, height: 100).fixedSize()
                .background(.white.opacity(0.2))
            }
            .simultaneousGesture(LongPressGesture().onEnded { _ in
              //              openWindow(id:"main")
              app?.openWindow(id: "widgetSettings", value: widget.modelID)
            })
            .simultaneousGesture(TapGesture().onEnded {
              if (geometry.size.width < 400 || geometry.size.height < 400) {
                app?.openWindow(id: "widgetSettings", value: widget.modelID)
              } else {
                toggleSettings()
              }
            })
            .buttonBorderShape(.circle)
            .buttonStyle(.automatic)
            .labelStyle(.iconOnly)
            .glassBackgroundEffect(displayMode: showInfo ? .always : .never)
            .background(.clear)
            .transition(.move(edge: .top))
            .hoverEffect()
            .offset(y: showInfo || isLoading ? 0 : 40)
            .padding(.bottom, 10)
            .opacity((isLoading || showInfo) && !flipped && !wasBackgrounded && finishedFirstLoad ? 1.0 : 0.0)
            .rotation3DEffect(.degrees(showInfo || isLoading ? 0.0 : 45), axis: (1, 0, 0),
                              anchor: UnitPoint3D(x: 0.5, y: 1.0, z: 0))
            .animation(.spring(), value: flipped)
            .animation(.spring(), value: showInfo)
            .animation(.spring(), value: isLoading)
            
          }
        }
      } // MARK: Content view modifiers
      .rotation3DEffect(.degrees(flipped ? -180.0 : 0.0), axis: (0, 1, 0), anchor: UnitPoint3D(x: 0.5, y: 0, z: 0))
      .onChange(of: geometry.size) {
        widget.width = geometry.size.width
        widget.height = geometry.size.height
        print("↔️ Widget size changed to \(widget.width)×\(widget.height)")
        widget.save()
      }
      .opacity(wasBackgrounded ? 0.0 : 1.0)
      .onDisappear {
        widget.save()
      }
    }
    
//    .sheet(isPresented:Binding<Bool>(
//      get: { self.downloadAttachment != nil },
//      set: { _ in })) {
//        DownloadPanel(downloadAttachment: $downloadAttachment)
//      }
      .quickLookPreview($downloadAttachment, in: downloads)
    
    
    // Clamp the size initially to set the base size, but then allow it to change later.
      .frame(minWidth: clampInitialSize ? widget.width : widget.minWidth,
             idealWidth: widget.width,
             maxWidth: clampInitialSize ? widget.width : widget.maxWidth,
             minHeight: clampInitialSize ? widget.height : widget.minHeight,
             idealHeight: widget.height,
             maxHeight: clampInitialSize ? widget.height : widget.maxHeight)
      .fixedSize(horizontal:clampInitialSize, vertical:clampInitialSize)
      .persistentSystemOverlays(showHandle && !wasBackgrounded && !flipped ? .automatic : .hidden)
    
      .onAppear(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
          clampInitialSize = false
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeInOut(duration: 1.0)) {
              loadedWindow = true;
              
            }
          }
        }

      }
      .onDisappear {
        print("❌ Closing Widget \(widget.name)")
      }
      .onChange(of: scenePhase) {
        if (scenePhase == .active) {
          if (wasBackgrounded) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
              dismiss()
            }
            openWindow(id:"main")
          }
        }
        if (scenePhase == .background) {
          print("💤 Backgrounding \(widget.name)")
          wasBackgrounded = true
        }
        currentPhase = scenePhase
      }
  }
  
  func scheduleHide() {
    ornamentTimer?.invalidate()
    ornamentTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false, block: { timer in
      showHandle = false
      showInfo = false
    })
  }
}


//#Preview(windowStyle: .plain) {
//    WidgetView(widget: Widget(name: "Test", location: "https://example.com", style: .glass))
//}
