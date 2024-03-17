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
  @State var showPopover = false
  @State var showTilt = false
  @State var clampedSize: CGSize?
  @State var constrainRatio = false
  
  
  init(widget: Widget, app: WidgetApp? = nil) {
    self.widget = widget
    self.app = app
    
  }
  
  func toggleSettings() {
    flipped.toggle()
    if !flipped, let location = widget.location {
      browserState.location = location
    }
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
    
    let isTransient = widget.modelContext == nil;
    let tilt = showPopover ? 0 : (widget.tilt ?? 0)
    
    GeometryReader { geometry in
      
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
        
        
        if (flipped) {
          WidgetSettingsView(widget:widget)
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
            .allowsHitTesting(showSystemOverlay || !widget.showGlassBackground)
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
      
      // MARK: Window Menu
      .ornament(attachmentAnchor: .scene(.top), contentAlignment:.bottom) {
        if (widget.showBrowserBar) {
          WidgetViewBrowserBar(widget: $widget, browserState: $browserState, infoCallback: toggleSettings)
            .frame(maxWidth:geometry.size.width - 10)
          
        } else {
          Button {
            withAnimation {
              showPopover = true;
            }
          } label: {
              HStack() {
                let dotSize = 10.0
                Group {
                  Circle().fill(showPopover ? .black : .white.opacity(0.67))
                  Circle().fill(showPopover ? .black : .white.opacity(0.67))
                  Circle().fill(showPopover ? .black : .white.opacity(0.67))
                }
                .frame(width: dotSize, height: dotSize)
            }
          }
          .buttonBorderShape(.capsule)
          .buttonStyle(.bordered)
          .tint(showPopover ? .white : .clear)
          .labelStyle(.iconOnly)
          .transition(.move(edge: .top))
          .hoverEffect()
          .offset(y: showInfo || isLoading || showPopover ? 0 : 40)
          .padding(.bottom, 4)
          .opacity((isLoading || showInfo || showPopover) && !flipped && !wasBackgrounded && finishedFirstLoad ? 1.0 : 0.0)
          .rotation3DEffect(.degrees(showInfo || isLoading || showPopover ? 0.0 : 45), axis: (1, 0, 0),
                            anchor: UnitPoint3D(x: 0.5, y: 1.0, z: 0))
          .animation(.spring(), value: flipped)
          .animation(.spring(), value: showInfo)
          .animation(.spring(), value: isLoading)
          .animation(.spring(), value: showPopover)
          .popover(isPresented: $showPopover, content: {
            
            VStack() {
              HStack() {
                Group {
                  Menu {
                  } label: {
                    Label("Back",systemImage:"arrow.left")
                  }primaryAction: {
                    browserState.webView?.goBack()
                  }.disabled(!browserState.canGoBack)
                  if browserState.canGoForward {
                    Spacer()
                    Menu {
                    } label: {
                      Label("Forward",systemImage:"arrow.right")
                    }primaryAction: {
                      browserState.webView?.goForward()
                    }.disabled(!browserState.canGoBack)
                  }
                  Spacer()

                  Menu {
                    Toggle(isOn: $widget.autohideControls) {
                      Label("Autohide Controls", systemImage:"eye.slash")
                    }
                    Toggle(isOn: Binding<Bool>(
                      get: { widget.effect == "dim" },
                      set: { val in widget.effect = val ? "dim" : nil})) {
                        Label("Dim Environment", systemImage:"circle.lefthalf.filled.righthalf.striped.horizontal")
                      }
                    
                    Divider()
                    Menu {
                      Button { showPopover.toggle()
                        resizeTo(CGSize(width: geometry.size.height,
                                        height: geometry.size.width))
                      } label: {
                        Label("Rotate", systemImage:
                                geometry.size.height > geometry.size.width
                              ? "rectangle.landscape.rotate"
                              : "rectangle.portrait.rotate")
                      }
                      //                    Button { showPopover.toggle()
                      //                      resizeTo(CGSize(width: geometry.size.width,
                      //                                      height: geometry.size.width))
                      //                    } label: {
                      //                      Label("Square",systemImage:"square")
                      //                    }
                      Button { showPopover.toggle()
                        resizeTo(CGSize(width: geometry.size.width,
                                        height: geometry.size.width / 4 * 3))
                      } label: {
                        Label("Standard (4:3)",systemImage:"rectangle.ratio.4.to.3")
                      }
                      Button { showPopover.toggle()
                        resizeTo(CGSize(width: geometry.size.width,
                                        height: geometry.size.width / 16 * 9))
                      } label: {
                        Label("Widescreen (16:9)",systemImage:"rectangle.ratio.16.to.9")
                      }
                      Button { showPopover.toggle()
                        resizeTo(CGSize(width: geometry.size.width,
                                        height: geometry.size.width / 64 * 27))
                      } label: {
                        Label("Cinematic (21:9)",systemImage:"pano")
                      }
                    } label: {
                      
                        Label("Aspect Ratio",systemImage:"aspectratio")
                    }
#if DEBUG
                    Divider()
                    Label("Beta Options",systemImage:"")
                    Button { showPopover.toggle()
                      showTilt.toggle()
                      if showTilt { widget.tilt = nil }
                    } label: {
                      Label("Adjust Tilt (beta)",systemImage:"rotate.3d")
                    }
#endif

                  } label: {
                    Label("Settings",systemImage:"line.horizontal.3")
                  }
                  
                  Spacer()

                  Button {
                    browserState.webView?.reload()
                  } label: {
                    Label("Reload",systemImage:"arrow.clockwise")
                  }
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .buttonBorderShape(.circle)
                
                
                
              }.padding(.horizontal, 10)
                .padding(.bottom, 4)
              Divider()
              Group {
                
                Button { showPopover.toggle()
                  openWindow(id: WindowTypeID.main, value: "settings:\(widget.wid)")
                } label: {
                  HStack {
                    Text("Customize…")
                      .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "gear")
                  }.padding(.vertical, 16)
                }
                Button {showPopover.toggle()
                  openWindow(id:WindowTypeID.main, value:WindowID.main)
                } label: {
                  HStack {
                    Text("Show Dashboard")
                      .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "square.grid.3x3.fill")
                  }.padding(.vertical, 16)
                }
              }
              .frame(maxWidth:.infinity)
              .buttonStyle(.borderless)
              .buttonBorderShape(.roundedRectangle)
            }.frame(minWidth:260).padding()
          })
          .simultaneousGesture(LongPressGesture().onEnded { _ in
        
          })
        }
      }
      // MARK: Content view modifiers
      .preferredSurroundingsEffect(widget.effect == "dim" ? .systemDark : nil)

      .rotation3DEffect(.degrees(flipped ? -180.0 : 0.0), axis: (0, 1, 0), anchor: UnitPoint3D(x: 0.5, y: 0, z: 0))
      .onChange(of: geometry.size) {
        widget.width = geometry.size.width
        widget.height = geometry.size.height
        console.log("↔️ Widget size changed to \(Int(widget.width))×\(Int(widget.height))")
        widget.save()
      }
      .animation(.spring(), value: showPopover)
      .opacity(wasBackgrounded ? 0.0 : 1.0)
      .onDisappear {
        console.log("Widget dissapeared \(widget.name)")
        //widget.save()
      }
    }
    
    //    .sheet(isPresented:Binding<Bool>(
    //      get: { self.downloadAttachment != nil },
    //      set: { _ in })) {
    //        DownloadPanel(downloadAttachment: $downloadAttachment)
    //      }
    
    .quickLookPreview($downloadAttachment, in: downloads)
    
    // Clamp the size initially to set the base size, but then allow it to change later.
    .frame(minWidth: clampedSize?.width ?? widget.minWidth,
           idealWidth: clampedSize?.width ?? widget.width,
           maxWidth: clampedSize?.width ??  widget.maxWidth,
           minHeight: clampedSize?.height ??  widget.minHeight,
           idealHeight: clampedSize?.height ?? widget.height,
           maxHeight: clampedSize?.height ??  widget.maxHeight)
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
      let windowScenes = UIApplication.shared.connectedScenes
      resizeTo(CGSizeMake(widget.width, widget.height))

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
        loadedWindow = true;
      }
      
    widget.lastOpened = .now
    }
    .onDisappear {
      console.log("❌ Closing Widget \(widget.name)")
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
    
    .onChange(of: showPopover) {
      if (showPopover) {
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
}


#Preview(windowStyle: .plain) {
  WidgetView(widget: Widget(name: "Test", location: "https://example.com"))
}
