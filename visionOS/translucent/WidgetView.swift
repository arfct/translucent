import SwiftUI
import SwiftData
import RealityKit
import Combine
import QuickLook
import WebKit
import GroupActivities
import LinkPresentation

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
  @State var menuVisible = false
  @State var showTilt = false
  @State var clampedSize: CGSize?
  @State var constrainRatio = false
  @State var locationTempString = ""
  
  @FocusState private var isTextFieldFocused: Bool
  
  let toolbarHeight = 68.0;
  
  init(widget: Widget, app: WidgetApp? = nil) {
    self.widget = widget
    self.app = app
    
  }
  
  func toggleSettings() {
    menuVisible.toggle()
  }
  
  func resizeTo(_ size: CGSize) {
    clampedSize = size;
    widget.width = size.width
    widget.height = size.height
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      clampedSize = nil
    }
  }
  
  var drag: some Gesture {
    DragGesture(coordinateSpace: .global)
    
      .onChanged { value in
        print(value)
      }
      .onEnded({ value in
      })
  }
  var body: some View {
    
    let webView = WebView(title: $widget.title,
                          location: $widget.location,
                          widget: $widget,
                          phase:$currentPhase,
                          attachment:$downloadAttachment,
                          browserState:$browserState)
    
    //    let isTransient = widget.modelContext == nil;
    let tilt = menuVisible ? 0 : (widget.tilt ?? 0)
    
    GeometryReader { geometry in
      let menuContents = Group {
        ControlGroup() {
          Group {
            Button  {
              browserState.webView?.goBack()
            } label: {
              Label("Back",systemImage:"arrow.left")
            }.disabled(!browserState.canGoBack)
            
              .menuActionDismissBehavior(.disabled)
            if browserState.canGoForward {
              
              Button {
                browserState.webView?.goForward()
              } label: {
                Label("Forward",systemImage:"arrow.right")
              }.disabled(!browserState.canGoForward)
              
                .menuActionDismissBehavior(.disabled)
            }
            
            
            Button {
              browserState.webView?.reload()
            } label: {
              Label("Reload",systemImage:"arrow.clockwise")
            }
            .menuActionDismissBehavior(.disabled)
            
            ShareLink(
              item: widget,
              preview: SharePreview(
                "Widget \(widget.name)",
                image: Image(systemName: "plus"))
            ) {
              Image(systemName: "square.and.arrow.up")
            }
            
            
            
          }
          .labelStyle(.iconOnly)
          .buttonStyle(.borderless)
          .buttonBorderShape(.circle)
          
          
          
        }.padding(.horizontal, 10)
        Divider()
        Group {
          Menu {
#if DEBUG
            Toggle(isOn: Binding<Bool>(
              get: { widget.showBrowserBar },
              set: { val in widget.controls = (val ? ControlStyle.toolbar.rawValue : nil)}))
            {
              Label("Show Toolbar", systemImage:"ellipsis.rectangle")
            }
#endif
            
            Toggle(isOn: Binding<Bool>(
              get: { widget.autohideControls },
              set: { val in widget.controls = val ? ControlStyle.hide.rawValue : nil}))
            {
              Label("Autohide Controls", systemImage:"eye.slash")
            }
            Divider()
            Toggle(isOn: Binding<Bool>(
              get: { widget.effect == "dim" },
              set: { val in widget.effect = val ? "dim" : nil})) {
                Label("Dim Environment", systemImage:"circle.lefthalf.filled.righthalf.striped.horizontal")
              }
            
            
            Menu {
              Button { menuVisible.toggle()
                resizeTo(CGSize(width: geometry.size.height,
                                height: geometry.size.width))
              } label: {
                Label("Rotate", systemImage:
                        geometry.size.height > geometry.size.width
                      ? "rectangle.landscape.rotate"
                      : "rectangle.portrait.rotate")
              }
              //                    Button { menuVisible.toggle()
              //                      resizeTo(CGSize(width: geometry.size.width,
              //                                      height: geometry.size.width))
              //                    } label: {
              //                      Label("Square",systemImage:"square")
              //                    }
              Button { menuVisible.toggle()
                resizeTo(CGSize(width: geometry.size.width,
                                height: geometry.size.width / 4 * 3))
              } label: {
                Label("Standard (4:3)",systemImage:"rectangle.ratio.4.to.3")
              }
              Button { menuVisible.toggle()
                resizeTo(CGSize(width: geometry.size.width,
                                height: geometry.size.width / 16 * 9))
              } label: {
                Label("Widescreen (16:9)",systemImage:"rectangle.ratio.16.to.9")
              }
              Button { menuVisible.toggle()
                resizeTo(CGSize(width: geometry.size.width,
                                height: geometry.size.width / 64 * 27))
              } label: {
                Label("Cinematic (21:9)",systemImage:"pano")
              }
            } label: {
              Label("Resize Window",systemImage:"aspectratio")
            }
#if DEBUG
            Divider()
            Menu {
              
              Label("Experimental Options",systemImage:"")
              Button { menuVisible.toggle()
                showTilt.toggle()
                if showTilt { widget.tilt = nil }
              } label: {
                Label("Adjust Tilt",systemImage:"rotate.3d")
              }
            } label: {
              
              Label("Experimental",systemImage:"testtube.2")
            }
#endif
            
          } label: {
            Label("Window Options",systemImage:"slider.horizontal.below.rectangle")
          }
          
          Button { menuVisible.toggle()
            openWindow(id: WindowTypeID.main, value: "settings:\(widget.wid)")
          } label: {
            HStack {
              Text("Tweak Website…")
                .frame(maxWidth: .infinity, alignment: .leading)
              Image(systemName: "gear")
            }.padding(.vertical, 16)
          }
          
          Divider()
          
          Button {menuVisible.toggle()
            openWindow(id:WindowTypeID.main, value:WindowID.main)
          } label: {
            HStack {
              Text("Show Favorites")
                .frame(maxWidth: .infinity, alignment: .leading)
              Image(systemName: "square.grid.3x3.fill")
            }.padding(.vertical, 16)
          }
        }
        .frame(maxWidth:.infinity)
        .buttonStyle(.borderless)
        .buttonBorderShape(.roundedRectangle)
        
      }
      let menuView = Menu {
        menuContents
      } label: {
        AnimatedEllipsisView(loading: $isLoading)
      }
      
        .buttonBorderShape(.capsule)
        .buttonStyle(.bordered)
        .tint(menuVisible ? .white : .clear)
        .labelStyle(.iconOnly)
        .transition(.move(edge: .top))
        .onTapGesture {
          cancelHide()
        }
      
      
      let browserBar = HStack {
        HStack(spacing:0) {
          Button {
            browserState.coordinator?.webView?.goBack()
          } label: {
            Label("Back", systemImage: "arrow.left").labelStyle(.iconOnly)
          }.buttonBorderShape(.circle)
            .buttonStyle(.borderless)
            .disabled(!browserState.canGoBack)
          
          if browserState.canGoForward {
            Button {
              browserState.coordinator?.webView?.goForward()
              
            } label: {
              Label("Forward", systemImage: "arrow.right").labelStyle(.iconOnly)
            }.buttonBorderShape(.circle)
              .buttonStyle(.borderless)
          }
        }
        SearchBar(text: $locationTempString,
                  placeholder: .constant(""),
                  onSubmit: { ended in
          print("changed \(ended)")
          if let url = url(from:locationTempString) {
            widget.location = url.absoluteString
          }
        })
        .overlay(alignment:.trailing) {
          Button {
            browserState.webView?.reload()
          } label: {
            Image(systemName: "arrow.clockwise")
              .foregroundColor(.secondary)
          }
          .buttonStyle(.borderless)
          .buttonBorderShape(.circle)
          .scaleEffect(0.8)
        }
        //        TextField("location", text:$locationTempString )
        .padding(.horizontal, -4)
        .frame(maxWidth:320)
        .textFieldStyle(.roundedBorder)
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
          if let location = clean(url:locationTempString){
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
        
        Menu {
          //        infoCallback()
          menuContents
        } label: {
          Label("info", systemImage: "ellipsis").labelStyle(.iconOnly)
        }
        .buttonBorderShape(.circle)
        .buttonStyle(.borderless)
        
      }
        .padding(8)
        .frame(minWidth:310, maxWidth:isTextFieldFocused ? .infinity :  400)
        .glassBackgroundEffect()
      
      
      // MARK: Tab View
      ZStack(alignment: .center) {
        if let tabs = widget.tabs, showSystemOverlay {
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
        
        
        VStack(spacing:0) {
          VStack {
            if (widget.showBrowserBar) {
              browserBar
                .padding(.bottom, 8)
                .padding(.horizontal, 12)
            } else {
              menuView
                .padding(.top, 5)
            }
          }.frame(height:toolbarHeight)
          
          
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
          
            .blendMode(widget.blendMode)
            .allowsHitTesting(showSystemOverlay || !widget.suppressFirstClick )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(widget.effect == "chroma" ? ChromaView() : nil)
            .background(widget.backColor)
            .glassBackgroundEffect(in:RoundedRectangle(cornerRadius: widget.radius),
                                   displayMode: (widget.showGlassBackground ) ? .always : .never)
          
          
          
            .cornerRadius(widget.radius)
            .opacity(!finishedFirstLoad || !loadedWindow ? 0.8 : 1.0)
            .disabled(flipped)
            .rotation3DEffect(.degrees(90.0 * (tilt)),
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
      
      // MARK: Tilt Ornament
      .ornament(attachmentAnchor: .scene(.trailing), contentAlignment: .leading, ornament: {
        if (showTilt) {
          VStack(spacing:10) {
            ZStack (alignment: .center) {
              Circle()
                .fill(.white.opacity(0.5))
                .frame(width:30, height:140)
                .offset(y: -tilt * 50)
                .cornerRadius(15)
            }.frame(width:40, height:140)
              .glassBackgroundEffect()
              .contentShape(RoundedRectangle(cornerRadius: 90))
              .hoverEffect()
              .gesture(
                DragGesture(coordinateSpace: .global)
                  .onChanged { value in
                    cancelHide()
                    var tilt = CGFloat( -2 *  value.translation3D.y)
                    if (abs(tilt) < 60.0) { tilt = 0.0 }
                    widget.tilt = min(1.0, max(-1.0, (tilt / geometry.size.height)))
                  }
                  .onEnded { value in
                    scheduleHide()
                    withAnimation(.spring()) {
                    }
                  }
              )
            
            Button {
              showTilt = false
            } label: {
              Label("Close", systemImage:"xmark")
                .labelStyle(.iconOnly)
            }
            .frame(width:40, height:40)
            .glassBackgroundEffect()
            
          }
          
          .padding(.leading, 10)
          .padding(.top, 50)
        }
        
      })
      
      // MARK: Content view modifiers
      .preferredSurroundingsEffect(widget.effect == "dim" ? .systemDark : nil)
      
      .rotation3DEffect(.degrees(flipped ? -180.0 : 0.0), axis: (0, 1, 0), anchor: UnitPoint3D(x: 0.5, y: 0, z: 0))
      .onChange(of: geometry.size) {
        widget.width = geometry.size.width - toolbarHeight
        widget.height = geometry.size.height - toolbarHeight
        console.log("↔️ Widget size changed to \(Int(widget.width))×\(Int(widget.height))")
        widget.save()
      }
      .animation(.spring(), value: menuVisible)
      .opacity(wasBackgrounded ? 0.0 : 1.0)
      .onDisappear {
        console.log("❌ Closing Widget \(widget.name)")
      }
    }
    
    .quickLookPreview($downloadAttachment, in: downloads)
    
    // Clamp the size initially to set the base size, but then allow it to change later.
    .frame(minWidth: clampedSize?.width ?? widget.minWidth,
           idealWidth: clampedSize?.width ?? widget.width,
           maxWidth: clampedSize?.width ??  widget.maxWidth,
           minHeight: toolbarHeight + (clampedSize?.height ??  widget.minHeight),
           idealHeight: toolbarHeight + (clampedSize?.height ?? widget.height),
           maxHeight: toolbarHeight + (clampedSize?.height ??  widget.maxHeight))
    //    .fixedSize(horizontal:clampInitialSize, vertical:clampInitialSize)
    //    .windowGeometryPreferences(
    //      size: CGSize(width: clampedSize?.width ?? widget.width,
    //                   height: clampedSize?.height ?? widget.height),
    //      resizingRestrictions:
    //        widget.resize == "uniform"  || constrainRatio ? .uniform :
    //        widget.resize == "none" ? .none :
    //          .freeform)
    .onReceive(NotificationCenter.default.publisher(for: Notification.Name.widgetDeleted)) { notif in
      if let anotherWidget = notif.object as? Widget, widget == anotherWidget {
        dismiss()
      }
    }
    .persistentSystemOverlays((flipped || showSystemOverlay) && !wasBackgrounded ? .automatic : .hidden)
    
    .onWindowChange { window in
    }
    .onAppear(){
      resizeTo(CGSizeMake(widget.width, widget.height))
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
        loadedWindow = true;
      }
      
      widget.lastOpened = .now
      if (widget.shouldCacheIcon) { widget.fetchIcon() }
    }
    
    .onChange(of: scenePhase) {
      if (scenePhase == .active) {
        if (wasBackgrounded) {
          // We can't trust this alone - it's triggered by stuff like the camera
          console.log("Widget returned from background \(widget.name)")
          // DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { dismiss() }
          // openWindow(id:"main")
        }
      }
      if (scenePhase == .background) {
        console.log("💤 Backgrounding \(widget.name)")
        //        wasBackgrounded = true
      }
      currentPhase = scenePhase
    }
    
    .onChange(of: menuVisible) {
      if (menuVisible) {
        cancelHide()
      } else {
        scheduleHide()
      }
    }
  }
  
  func cancelHide() {
    ornamentTimer?.invalidate()
    showSystemOverlay = true
    showInfo = true
  }
  func scheduleHide() {
    cancelHide()
    if (widget.autohideControls) {
      ornamentTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false, block: { timer in
        showSystemOverlay = false
        showInfo = false
      })
    }
  }
  
  //
  //  // SHAREPLAY CODE
  //  private func startSharePlaySession() async {
  //
  //
  //    for await session in WidgetView.sessions() {
  //      guard let systemCoordinator = await session.systemCoordinator else { continue }
  //
  //      let isLocalParticipantSpatial = systemCoordinator.localParticipantState.isSpatial
  //
  //      Task.detached {
  //        for await localParticipantState in systemCoordinator.localParticipantStates {
  //          if localParticipantState.isSpatial {
  //            // Start syncing scroll position
  //          } else {
  //            // Stop syncing scroll position
  //          }
  //        }
  //      }
  //
  //      var configuration = SystemCoordinator.Configuration()
  //      configuration.spatialTemplatePreference = .sideBySide
  //      systemCoordinator.configuration = configuration
  //
  //      session.join()
  //    }
  //
  //    let location = "https://example.com"
  //
  //    if let widget = Widget.findOrCreate(location: location) {
  //      // Create the activity
  //      let activity = WidgetView(widget: widget)
  //
  //      // Register the activity on the item provider
  //      let itemProvider = NSItemProvider()
  //      itemProvider.registerGroupActivity(activity)
  //
  //      // Create the activity items configuration
  //      let configuration = await UIActivityItemsConfiguration(itemProviders: [itemProvider])
  //
  //      // Provide the metadata for the group activity
  //      configuration.metadataProvider = { key in
  //        guard key == .linkPresentationMetadata else { return nil }
  //        let metadata = LPLinkMetadata()
  //        metadata.title = "Explore Together"
  //        metadata.imageProvider = NSItemProvider(object: UIImage(named: "explore-activity")!)
  //        return metadata
  //      }
  //      self.activityItemsConfiguration = configuration
  //    }
  //  }
  
  
}

#Preview("Bar", windowStyle: .plain, traits: .fixedLayout(width: 400, height: 480)) {
  let widget = Widget(name: "Test", location: "https://www.example.com", options:"?v=1&controls=toolbar")
  WidgetView(widget: widget)
} cameras: {
  PreviewCamera(from: .front, zoom:1.5, name: "Front")
}



#Preview("Standard", windowStyle: .plain, traits: .fixedLayout(width: 400, height: 400)) {
  let widget = Widget(name: "Test", location: "https://www.example.com")
  WidgetView(widget: widget)
} cameras: {
  PreviewCamera(from: .front, zoom:2, name: "Front")
}

