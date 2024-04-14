import SwiftUI
import SwiftData
import RealityKit
import OSLog

extension Notification.Name {
  static let mainWindowOpened = Notification.Name("mainWindowOpened")
  static let widgetDeleted = Notification.Name("widgetDeleted")
  static let widgetClosed = Notification.Name("widgetClosed")
}

struct WidgetPickerView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.dismiss) private var dismiss
  
  @Environment(\.openImmersiveSpace) var openImmersiveSpace
  @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
  
  @Query(sort: [SortDescriptor(\Widget.lastOpened, order: .reverse)], animation: .default)
  var widgets: [Widget]
  
  @State private var showAddWidget = false
  @State private var path: [Widget] = []
  @State private var hue: CGFloat = 0.6
  @State private var draggedWidget: Widget?
  @State private var isVisible: Bool = false
  @State var isDragDestination: Bool = false
  @Environment(\.openURL) var openURL
  @Environment(\.openWindow) private var openWindow
  @Environment(\.dismissWindow) private var dismissWindow
  @State private var searchText: String = ""
  @State var uuid: UUID
  
  @State var endDrag: DispatchWorkItem?
  
  @State private var showImmersiveSpace = false
  @State private var immersiveSpaceIsShown = false
  
  var app: WidgetApp?
  
  init(app: WidgetApp? = nil) {
    self.app = app
    self.uuid = UUID()
  }
  
  let columns = [GridItem(.adaptive(minimum: 160, maximum: 160),
                          spacing: 40,
                          alignment: .center)]
  
  let colors = [
    Color.withHex("E03A3E"),
    Color.withHex("F5821F"),
    Color.withHex("FDB827"),
    Color.withHex("FF6489"),
    Color.withHex("FFFFFF"),
    Color.withHex("61BB46"),
    Color.withHex("963D97"),
    Color.withHex("009DDC"),
    Color.withHex("23CDAE")
  ]
  
  func getMoreWidgets() {
    guard let url = URL(string: "https://translucent.directory") else { return }
    //    openWindow(id: "webview", value: url)
    openURL(url)
  }
  
  func updateHue() {
    hue = fmod(floor(Date().timeIntervalSince1970), 360) / 360.0
  }
  
  func position(of innerView: GeometryProxy, to outerView: GeometryProxy, distance: CGFloat = 20.0, at edge: CGRectEdge = .maxYEdge) -> CGFloat{
    let innerFrame = innerView.frame(in: .global)
    let outerFrame = outerView.frame(in: .global)
    
    var start = 0.0
    var end = 1.0
    var value = 0.0
    
    switch edge {
    case .minXEdge, .maxXEdge:
      start = outerFrame.minX
      end = outerFrame.maxX
      value = innerFrame.midX
    case .minYEdge, .maxYEdge:
      start = outerFrame.maxY
      end = outerFrame.minY
      value = innerFrame.midY
    }
    
    return max(0, min(1, (value - start) / (end - start)));
  }
  
  func proximity(of innerView: GeometryProxy, to outerView: GeometryProxy, distance: CGFloat = 20.0, at edge: CGRectEdge = .maxYEdge) -> CGFloat{
    let innerFrame = innerView.frame(in: .global)
    let outerFrame = outerView.frame(in: .global)
    
    var start = 0.0
    var end = 1.0
    var value = 0.0
    
    switch edge {
    case .minXEdge:
      start = outerFrame.minX
      end = outerFrame.minX + distance
      value = innerFrame.maxX
    case .maxXEdge:
      start = outerFrame.maxX
      end = outerFrame.maxX - distance
      value = innerFrame.minX
    case .minYEdge:
      start = outerFrame.minY
      end = outerFrame.minY + distance
      value = innerFrame.maxY
    case .maxYEdge:
      start = outerFrame.maxY
      end = outerFrame.maxY - distance
      value = innerFrame.minY
    }
    
    return max(0, min(1, (value - start) / (end - start)))
  }
  
  
  let iconSize: CGSize = CGSize(width: 160, height: 160)
  
  // MARK: body
  var body: some View {
    VStack {
      Image("translucent")
        .renderingMode(.template)
        .resizable()
        .foregroundColor(Color(hue: hue, saturation: 0.2, brightness: 1.0))
        .aspectRatio(contentMode: .fit)
        .opacity(1.0)
        .shadow(color:.black.opacity(0.5), radius: 6, y: 1)
        .offset(z: 30)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .frame(width: 400)
        .opacity(isVisible ? 1.0 : 0.0)
        .offset(z: isVisible ? 0 : 200)
      
      GeometryReader { scrollView in
        ScrollView() {
          // MARK: Grid
          LazyVGrid(columns: columns, alignment: .center, spacing: 16) {
            ForEach((0...max(8, widgets.count - 1)), id: \.self) { index in
              GeometryReader { widgetView in
                let xoffset = position(of:widgetView, to:scrollView, distance:iconSize.width, at: .maxXEdge)
                //                  let yoffset = position(of:widgetView, to:scrollView, distance:iconSize.width, at: .maxYEdge)
                let anchor = UnitPoint3D(x: xoffset > 0.5 ? 0 : 1,
                                         y: xoffset > 0.5 ? 0 : 1,
                                         z: 0)
                let minProx = proximity(of:widgetView, to:scrollView, distance:iconSize.width, at: .minYEdge)
                let maxProx = proximity(of:widgetView, to:scrollView, distance:iconSize.width, at: .maxYEdge)
                let combinedProx = minProx * maxProx
                
                
                var isSelected = index < widgets.count && widgets[index] == draggedWidget
                ZStack {
                  // MARK: Placeholders
                  
                  if index >= widgets.count {
                    VStack {
                      RoundedRectangle(cornerRadius: 30)
                        .fill(Color(hue: fmod(hue + 0.1 * Double(index), 1.0), saturation: 0.5, brightness: 1.0).opacity(0.2))
                        .glassBackgroundEffect(in:RoundedRectangle(cornerRadius: 30))
                        .frame(width:iconSize.width, height:iconSize.height)
                        .padding(.bottom, 50)
                    }
                    
                  } else {   // MARK: USDZ
                    
                    let widget = widgets[index]
                    
                    if widget.type == "usdz",
                       let loc = widget.location,
                       let url = URL(string:loc) {
                      ZStack() {
                        Model3D(url: url) { model in
                          model
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxDepth:iconSize.height)
                            .frame(maxWidth:iconSize.width, maxHeight: iconSize.height)
                            .padding(10)
                        } placeholder: {
                          ProgressView()
                        }
                      }
                      .frame(maxWidth:iconSize.width, maxHeight:iconSize.height)
                    } else {   // MARK: Widget
                      WidgetPickerItem(widget: widget)
                        .onDrag {
                          draggedWidget = widget
                          
                          endDrag?.cancel()
                          endDrag = DispatchWorkItem { draggedWidget = nil }
                          DispatchQueue.main.asyncAfter(deadline: .now() + 6, execute: endDrag!)
                          
                          let modelID = widget.modelID
                          let userActivity = NSUserActivity(activityType: Activity.openWidget)
                          try? userActivity.setTypedPayload(["wid": widget.wid])
                          let itemProvider = NSItemProvider(object: "" as NSString)
                          itemProvider.registerObject(userActivity, visibility: .all)
                          return itemProvider
                        } preview: {
                          WidgetPickerItem(widget: widget, asDrag:true)
                        }
                    }
                  }
                  
                }
                .scaleEffect(minProx * 0.8 + 0.2, anchor:.bottom)
                .scaleEffect(maxProx * 0.8 + 0.2, anchor:.top)
                .offset(z:combinedProx * 20 + abs(xoffset - 0.5) * 8 )
                .blur(radius: (1 - combinedProx) * 10)
                .opacity(combinedProx * (isVisible ? 1.0 : 0.0))
                
                .rotation3DEffect(.degrees(isSelected ? 0 : -30.0 * (xoffset - 0.5)), axis: (x: 0, y: 1, z: 0), anchor:anchor)
                .rotation3DEffect(.degrees(isSelected ? 0 : 20.0 * (1.0 - minProx)), axis: (x: 1, y: 0, z: 0), anchor:.trailing)
                .rotation3DEffect(.degrees(isSelected ? 0 : -20.0 * (1.0 - maxProx)), axis: (x: 1, y: 0, z: 0), anchor:.leading)
                .transition(.move(edge: .trailing))
                
                .animation(.easeOut(duration: 0.2).delay(0.03 * Double(index))) { content in
                  content
                    .offset(z: isVisible ? 0 : 200)
                    .opacity(isVisible ? 1.0 : 0.0)
                    .brightness(isVisible ? 0.0 : 1.0)
                }
              } // GeometryReader
              .frame(width:iconSize.width, height:iconSize.height + 40)
            } // ForEach
            
          } // MARK: /grid modifiers
          .frame(minHeight: scrollView.size.height, alignment:.top)
          .padding(.top, 20)
          .padding(.bottom, 20)
        }   // MARK: /scroll modifiers
        .padding(.top, -20)
        .padding(.horizontal, 16)
        .frame(maxHeight:.infinity, alignment:.top)
        .padding(.bottom, 80)
        
        // MARK: Empty Placeholder
        .overlay(alignment: .center) {
          if widgets.isEmpty {
            ContentUnavailableView {
              Label("Websites & Widgets", systemImage: "rectangle.3.offgrid.fill")
            } description: {
              Text("Add something from the web\nto see it here.")
              Button {
                getMoreWidgets()
              } label: {
                Label("Browse for More", systemImage: "book")
                
              }
            }
            .padding()
            .padding(.bottom, -20)
            .frame(maxWidth:360)
            .glassBackgroundEffect()
            .padding(.bottom, 110)
            .offset(z: 60)
            .offset(z: isVisible ? 0 : 200)
            .opacity(isVisible ? 1.0 : 0.0)
          }
          
        } // overlay
        
        // ScrollView
        // MARK: /ScrollView
        
      } // ScrollView GeometryReader
      .offset(z: -40)
      
      .background(
        RadialGradient(
          gradient: Gradient(colors: [
            .black.opacity(0.12),
            .black.opacity(0.08),
            .black.opacity(0.04),
            .black.opacity(0.01),
            .black.opacity(0.005),
            .clear]),
          center: .center,
          startRadius: 360.0 / 2,
          endRadius: 600.0 / 2
        ).offset(z: -100)
          .opacity(isVisible ? 1.0 : 0.0)
      )
      // MARK: Bottom Button
      
      .ornament(attachmentAnchor: .scene(.bottom), contentAlignment:.bottom) {
        if (true) { //}!widgets.isEmpty) {
          HStack {
            if (draggedWidget == nil) {
              Button {
                getMoreWidgets()
              } label: {
                Label("Directory", systemImage:  "book" )
              } .labelStyle(.iconOnly)
                .buttonBorderShape(.circle)
                .buttonStyle(.borderless)
            } else {
              Button(role: .destructive) {
                if let draggedWidget = draggedWidget {
                  withAnimation(.spring) {
                    NotificationCenter.default.post(name: Notification.Name.widgetDeleted, object: draggedWidget)
                    
                    draggedWidget.delete()
                    self.draggedWidget = nil
                  }
                }
              } label: {
                Label("Remove Site", systemImage: "trash")
                
                
                  .frame(maxWidth: .infinity, alignment:.leading)
              } .labelStyle(.titleAndIcon)
              //              .buttonBorderShape(.roundedRectangle(radius: 30))
                .buttonBorderShape(.capsule)
                .buttonStyle(.borderless)
                .frame(alignment:.leading)
            }
            
            
            //
            if (draggedWidget == nil) {
              
              SearchBar( text: $searchText,
                         placeholder:.constant(UIPasteboard.general.hasURLs ? "Search" : "Search or enter url"),
                         onSubmit: { bool in
                print("searchText", searchText, clean(url:searchText))
                if let url = url(from: searchText) {
                  app?.showWindowForURL(url)
                  searchText = ""
                }
              })
              .overlay(alignment:.trailing) {
                if (UIPasteboard.general.hasURLs) {
                  PasteButton(payloadType: URL.self) { urls in
                    if let url = urls.first {
                      DispatchQueue.main.async {
                        app?.showWindowForURL(url)
                      }
                    }
                  }
                  .buttonBorderShape(.roundedRectangle(radius: 40))
                  .buttonStyle(.borderless)
                  .labelStyle(.titleOnly)
                  .tint(.black)
                  .opacity(0.667)
                  .padding(.trailing, 6)
                }
              }
              .padding(.horizontal, -4)
            } else {
              //              Text("Drag to remove")
              //                .frame(maxWidth:.infinity)
            }
            
            
            Menu {
              
              Button {
                UIApplication.shared.open(URL(string:"https://translucent.directory/help")!)
              } label: {
                Label("Help", systemImage: "questionmark.circle")
              }
              
              //              Button {
              //                UIApplication.shared.open(URL(string:"https://translucent.directory/discord")!)
              //              } label: {
              //                Label("Discord", systemImage: "bubble")
              //              }
              
              
              Divider()
              ShareLink(item: URL(string:"https://translucent.vision")!) {
                Label("Share Translucent", systemImage:  "square.and.arrow.up")
              }
              
              
              
#if DEBUG
              
              Toggle("Show Immersive Space", isOn: $showImmersiveSpace).labelsHidden()
              Divider()
#endif
              
            } label: {
              Label("Menu", systemImage:"ellipsis")
                .labelStyle(.iconOnly)
              
            }                .buttonStyle(.borderless)
              .buttonBorderShape(.circle)
          }
          
          .dropDestination(for: String.self) { items, location in
            draggedWidget?.delete()
            draggedWidget = nil
            return true
          }
          .cornerRadius(100)
          .frame(width:360)
          .padding(8)
          
          .background(draggedWidget != nil ? .red.opacity(0.1) : .black.opacity(0.0))
          .glassBackgroundEffect()
          .padding(.bottom, 12)
          .animation(.spring(), value: draggedWidget)
          .animation(.spring(), value: isDragDestination)
          .animation(.spring(), value: widgets)
          .animation(.easeOut(duration: 0.2).delay(0.03 * 10)) { content in
            content
              .offset(z: isVisible ? 0 : 200)
              .opacity(isVisible ? 1.0 : 0.0)
          }
        }
      }
      
    } // MARK: /Main View modifiers
    .onChange(of: scenePhase) {
      if (scenePhase == .background) {
        isVisible = false
      }
      if (scenePhase == .active) {
        withAnimation(.easeOut) {
          isVisible = true
        }
      }
    }
    //    .windowGeometryPreferences(resizingRestrictions: .none)
    
    .onAppear() {
      widgets.forEach { widget in
        if widget.wid.count < 1 {
          widget.wid = widget.id.uuidString
        }
      }
      updateHue()
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        if (isVisible) {
          NotificationCenter.default.post(name: Notification.Name.mainWindowOpened, object: self.uuid.uuidString)
        }
      }
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        withAnimation(.easeOut) {
          isVisible = true
        }
      }
      
      Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
        updateHue()
      }
      
      
    }
    .onDisappear() {
      isVisible = false;
    }
    .onReceive(NotificationCenter.default.publisher(for: Notification.Name.mainWindowOpened)) { notif in
      guard let otherID = notif.object as? String else { return }
      
      if (otherID != self.uuid.uuidString) {
        dismiss()
      }
      
      
    }
    .onChange(of: showImmersiveSpace) { _, newValue in
      Task {
        if newValue {
          switch await openImmersiveSpace(id: "ImmersiveSpace") {
          case .opened:
            immersiveSpaceIsShown = true
          case .error, .userCancelled:
            fallthrough
          @unknown default:
            immersiveSpaceIsShown = false
            showImmersiveSpace = false
          }
        } else if immersiveSpaceIsShown {
          await dismissImmersiveSpace()
          immersiveSpaceIsShown = false
        }
      }
    }
    
  }
  
}

#Preview(traits: .fixedLayout(width: 600, height: 800)) {
  //  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  //  let container = try! ModelContainer(for: Widget.self, configurations: config)
  
  //  Widget.modelContext = container.mainContext
  
  WidgetPickerView(app:nil)
  //    .modelContainer(container)
} cameras: {
  PreviewCamera(from: .front, zoom:1.5, name: "Front")
}
