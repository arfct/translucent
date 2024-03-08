import SwiftUI
import SwiftData
import RealityKit
import Combine
import QuickLook
import WebKit


// MARK: Coordinator
class BrowserState  {
  weak var webView: WKWebView?
  weak var coordinator: WebViewCoordinator?
  
  var url = URL(string: "about:blank")!
  var location: String = ""
  var displayLocation: String = ""
  var title: String = ""
  
  var canGoBack: Bool = false
  var canGoForward: Bool = false
  var isLoading: Bool = false
  
  //  var alert: Alert? = nil
  //  var alertTitle = ""
  //  var alertMessage = ""
}


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
  @State var showSystemOverlay: Bool = true
  @State var ornamentTimer: Timer?
  @State var clampInitialSize: Bool = true
  @State var foreColor: Color = .white
  @State var currentPhase: ScenePhase = .active
  @State var wasBackgrounded = false
  @State var lastActivation = Date()
  @State var downloadAttachment: URL?
  @State var downloads: [URL] = []
  @State var activeTab: Int = 0
  @State var browserState = BrowserState();
  @State var window: UIWindow?
  
  
  func toggleSettings() {
    withAnimation(.spring) {
      flipped.toggle()
      if !flipped, let location = widget.location {
        browserState.location = location
      }
    }
  }
  
  var drag: some Gesture {
    DragGesture(coordinateSpace: .global)
      
      .onChanged { value in
        print(value)
      }
      .onEnded({ value in
        
        print("xvalue \(value.translation)")
      })
  }
  var body: some View {
    
    let webView = WebView(title: $widget.title,
                          location: $widget.location,
                          widget: $widget,
                          phase:$currentPhase,
                          attachment:$downloadAttachment,
                          browserState:$browserState)
    
    let isTransient = widget.modelContext == nil;
    let tilt = (widget.tilt ?? 0)
    
    GeometryReader { geometry in
 
      // MARK: Tab View
      ZStack(alignment: .center) {
        if let tabs = widget.tabs {
          TabView(selection: $activeTab.onUpdate {
            if let tab = widget.tabs?[activeTab] {
              browserState.coordinator?.open(location:tab.url)
            }
          }) {
            ForEach(tabs.indices, id: \.self) { i in
              let info = tabs[i]
              ZStack {}.tabItem { Label(info.label, systemImage: info.image )}.tag(i)
            }
          }
        }
        
        
        if (flipped) {
          WidgetSettingsView(widget:widget, callback: toggleSettings)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(widget.backColor.opacity(0.2))
            .glassBackgroundEffect(in:RoundedRectangle(cornerRadius: 30))
            .offset(z: flipped ? 1 : 0)
            .opacity(flipped ? 1.0 : 0.0)
            .rotation3DEffect(.degrees(180), axis: (0, 1, 0), anchor: UnitPoint3D(x: 0.5, y: 0, z: 0))
            .disabled(!flipped)
        } else {
          
          // MARK: Web View
          
          webView
            .onLoadStatusChanged { content, loading, error in
              self.isLoading = loading
              if (!loading && !finishedFirstLoad) {
                withAnimation(.easeInOut(duration: 1.0)) {
                  finishedFirstLoad = true;
                }
                if !flipped {scheduleHide()}
              }
              if let error = error { console.log("Loading error: \(error)") }
            }
            .onDownloadCompleted { content, download, error in
              downloads.append(download)
              downloadAttachment = download;
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(widget.effect == "chroma" ? ChromaView() : nil)
            .glassBackgroundEffect(in:RoundedRectangle(cornerRadius: widget.radius),
                                   displayMode: (widget.showGlassBackground ) ? .always : .never)
            .background(widget.backColor)
            
          
            .cornerRadius(widget.radius)
            .opacity(!finishedFirstLoad || !loadedWindow ? 0.8 : 1.0)
            .disabled(flipped)
            .rotation3DEffect(.degrees(90.0 * (tilt ?? 0)),
                              axis: (x: 1, y: 0, z: 0),
                              anchor: .center)
            .offset(z: tilt > 0 
                    ? (geometry.size.height/2 - 80) * tilt
                    : (-geometry.size.height/2 + 80 ) * tilt
            )
            .gesture(TapGesture().onEnded({ gesture in
              showInfo = true
              showSystemOverlay = true
              if !flipped {scheduleHide()}
            }))
            .overlay {
              if !widget.showGlassBackground && showSystemOverlay {
                
                RoundedRectangle(cornerRadius: widget.radius).inset(by: 1)
                  .stroke(Color.white.opacity(0.03), lineWidth: 1)
                
              }
            }
        }
        
//        VStack() {
//          Text("HELLO").padding().gesture(drag)
//        }

      }

      .frame(maxWidth: .infinity, maxHeight: .infinity)
      
      .overlay(alignment: .center) {
        if (!finishedFirstLoad) {
          ProgressView()
        }
      }
      // TODO: Add alert https://developer.apple.com/documentation/swiftui/view/alert(_:ispresented:presenting:actions:message:)-8584l
      //        .alert(isPresented: $showAlert, content: {
      //            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("Close")))
      //        })
      // MARK: Toolbar {
      .toolbar {
        if let tools = widget.tools {
          ToolbarItemGroup(placement:.bottomOrnament) {
            ForEach(tools.indices, id: \.self) { i in
              let info = tools[i]
              Button {
                browserState.coordinator?.open(location:info.url)
              } label: {
                Label(info.label ?? "untitled", systemImage: info.image ?? "")
              }
            }
          }
        }
      }
      
      .ornament(attachmentAnchor: .scene(.topTrailing), ornament: {

      })
      // MARK: Info Button
      .ornament(attachmentAnchor: .scene(.top), contentAlignment:.bottom) {
        if (widget.showBrowserBar) {
          WidgetViewBrowserBar(widget: $widget, browserState: $browserState, infoCallback: toggleSettings)
            .frame(maxWidth:geometry.size.width - 10)
          
        } else {
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
          .simultaneousGesture(
            DragGesture(coordinateSpace: .global)
              .onChanged { value in
                cancelHide()
                var tilt = CGFloat( -3 *  value.translation3D.z)
                if (abs(tilt) < 60.0) { tilt = 0.0 }
                widget.tilt = min(1.0, max(-1.0, (tilt / geometry.size.height)))
              }
              .onEnded { value in
                scheduleHide()
                  withAnimation(.spring()) {
                      
                  }
              }
          )
//          .onDrag {
//            let userActivity = NSUserActivity(activityType: Activity.openSettings)
//            userActivity.targetContentIdentifier = "settings"
//            try? userActivity.setTypedPayload(["modelId": widget.modelID])
//            let itemProvider = NSItemProvider(object: widget.id.uuidString as NSString)
//            itemProvider.registerObject(userActivity, visibility: .all)
//            return itemProvider
//          } preview: {
//            ZStack {
//              Text("Widget Settings")
//            }.frame(width:100, height: 100).fixedSize()
//              .background(.white.opacity(0.2))
//          }
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
          .preferredSurroundingsEffect(widget.effect == "dim" ? .systemDark : nil)
        }
      }
      // MARK: Content view modifiers
      .rotation3DEffect(.degrees(flipped ? -180.0 : 0.0), axis: (0, 1, 0), anchor: UnitPoint3D(x: 0.5, y: 0, z: 0))
      .onChange(of: geometry.size) {
        widget.width = geometry.size.width
        widget.height = geometry.size.height
        console.log("↔️ Widget size changed to \(widget.width)×\(widget.height)")
        widget.save()
      }
      .opacity(wasBackgrounded ? 0.0 : 1.0)
      // .onDisappear { widget.save() }
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
//    .fixedSize(horizontal:clampInitialSize, vertical:clampInitialSize)
    //    .windowGeometryPreferences(
    //      size: CGSize(width: widget.width, height: widget.height),
    //      minimumSize: CGSize(width: widget.minWidth, height: widget.minHeight),
    //      maximumSize: CGSize(width: widget.maxWidth, height: widget.maxHeight),
    //      resizingRestrictions:
    //        widget.resize == "uniform" ? .uniform :
    //        widget.resize == "none" ? .none :
    //          .freeform)
    .onReceive(NotificationCenter.default.publisher(for: Notification.Name.widgetDeleted)) { notif in
      if let anotherWidget = notif.object as? Widget, widget == anotherWidget {
        dismiss()
      }
    }
    .persistentSystemOverlays((flipped || showSystemOverlay) && !wasBackgrounded ? .automatic : .hidden)
    
    .onWindowChange { window in
      self.window = window
    }
    .onAppear(){
      let windowScenes = UIApplication.shared.connectedScenes
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
        loadedWindow = true;

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
          clampInitialSize = false
          
        }
      }
      
    }
    .onDisappear {
      console.log("❌ Closing Widget \(widget.name)")
    }
    .onChange(of: scenePhase) {
      print("Phase \(scenePhase)")
      if (scenePhase == .active) {
        if (wasBackgrounded) {
          // We can't trust this alone - it's triggered by stuff like the camera
          console.log("Widget returned from background \(widget.name)")
          // DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { dismiss() }
          // openWindow(id:"main")
        }
      }
      if (scenePhase == .background) {
        print("💤 Backgrounding \(widget.name)")
        //        wasBackgrounded = true
      }
      currentPhase = scenePhase
    }
  }
  
  func cancelHide() {
    ornamentTimer?.invalidate()
    showSystemOverlay = true
    showInfo = true
  }
  func scheduleHide() {
    cancelHide()
    ornamentTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false, block: { timer in
      showSystemOverlay = false
      showInfo = false
    })
  }
}


#Preview(windowStyle: .plain) {
    WidgetView(widget: Widget(name: "Test", location: "https://example.com"))
}
