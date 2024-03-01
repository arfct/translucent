import SwiftUI
import SwiftData


struct Activity {
  static let openWidget = "vision.widget.open"
  static let openSettings = "vision.widget.settings"
  static let openPreview = "vision.widget.preview"
}


struct WidgetPickerDropDelegate: DropDelegate {
  var picker: WidgetPickerView?
  
  
  func dropEntered(info: DropInfo) {
    print("ENTER")
    picker?.isDragDestination = true
  }
  func dropExited(info: DropInfo) {
    print("EXIT")
    picker?.isDragDestination = false
  }
  func validateDrop(info: DropInfo) -> Bool {
    return true;
  }
  func performDrop(info: DropInfo) -> Bool {
    return true
  }
}


struct WidgetPickerView: View {
  @Environment(\.modelContext) private var modelContext
  
  @Query(sort: [SortDescriptor(\Widget.favorite, order: .reverse), SortDescriptor(\Widget.lastOpened, order: .reverse)])
  
  var widgets: [Widget]
  
  @State private var showAddWidget = false
  @State private var selection: Widget?
  @State private var path: [Widget] = []
  @State private var hue: CGFloat = 0.6
  @State private var draggedWidget: Widget?
  @State private var isVisible: Bool = false
  @State var isDragDestination: Bool = false
  @Environment(\.openURL) var openURL
  @Environment(\.openWindow) private var openWindow
  @Environment(\.dismissWindow) private var dismissWindow
  @State private var searchText: String = ""
  var app: WidgetApp?
  
  
  let columns =
  [
    GridItem(.adaptive(minimum: 160, maximum: 160), spacing:24, alignment: .center)
  ]
  
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
    openURL(URL(string: "https://www.widget.vision/list")!)
    dismissWindow(id: "main")
    
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
    
    let fraction = max(0, min(1, (value - start) / (end - start)))
    
    return fraction;
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
    
    let fraction = max(0, min(1, (value - start) / (end - start)))
    return fraction;
  }
  
  
  let widgetSize: CGSize = CGSize(width: 160, height: 120)
  
  var body: some View {
    VStack {
      Image("widget.vision")
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
      
      GeometryReader { scrollView in
        ScrollView() {
          
          // MARK: Grid
          LazyVGrid(columns: columns, alignment: .center, spacing: 16) {
            ForEach((0...max(8, widgets.count - 1)), id: \.self) { index in
              GeometryReader { widgetView in
                let xoffset = position(of:widgetView, to:scrollView, distance:widgetSize.width, at: .maxXEdge)
                //                  let yoffset = position(of:widgetView, to:scrollView, distance:widgetSize.width, at: .maxYEdge)
                let anchor = UnitPoint3D(x: xoffset > 0.5 ? 0 : 1,
                                         y: xoffset > 0.5 ? 0 : 1,
                                         z: 0)
                let minProx = proximity(of:widgetView, to:scrollView, distance:widgetSize.width, at: .minYEdge)
                let maxProx = proximity(of:widgetView, to:scrollView, distance:widgetSize.width, at: .maxYEdge)
                let combinedProx = minProx * maxProx
                
                ZStack {
                  if index >= widgets.count {
                    VStack {
                      RoundedRectangle(cornerRadius: 30)
                        .fill(Color(hue: fmod(hue + 0.1 * Double(index), 1.0), saturation: 0.5, brightness: 1.0).opacity(0.2))
                        .glassBackgroundEffect(in:RoundedRectangle(cornerRadius: 30))
                        .frame(width:widgetSize.width, height:widgetSize.height)
                        .padding(.bottom, 50)
                    }
                    
                  } else {
                    let widget = widgets[index]
                    
                    WidgetPickerItem(widget: widget)
                      .onDrag {
                        draggedWidget = widget
                        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                          draggedWidget = nil
                        }
                        let modelID = widget.modelID
                        let userActivity = NSUserActivity(activityType: Activity.openWidget)
                        userActivity.targetContentIdentifier = Activity.openWidget
                        try? userActivity.setTypedPayload(["modelId": modelID])
                        let itemProvider = NSItemProvider(object: "" as NSString)
                        itemProvider.registerObject(userActivity, visibility: .all)
                        return itemProvider
                      } preview: {
                        WidgetPickerItem(widget: widget, asDrag:true)
                      }
                    
                  }
                }
                // Style

                .scaleEffect(minProx * 0.8 + 0.2, anchor:.bottom)
                .scaleEffect(maxProx * 0.8 + 0.2, anchor:.top)
                .offset(z:combinedProx * 20 + abs(xoffset - 0.5) * 8)
                .blur(radius: (1 - combinedProx) * 10)
                .opacity(combinedProx * (isVisible ? 1.0 : 0.0))
                .offset(z: isVisible ? 0 : 400)
                .rotation3DEffect(.degrees(-30.0 * (xoffset - 0.5)), axis: (x: 0, y: 1, z: 0), anchor:anchor)
                .rotation3DEffect(.degrees(20.0 * (1.0 - minProx)), axis: (x: 1, y: 0, z: 0), anchor:.trailing)
                .rotation3DEffect(.degrees(-20.0 * (1.0 - maxProx)), axis: (x: 1, y: 0, z: 0), anchor:.leading)
                .transition(.move(edge: .trailing))

              } // GeometryReader
              .frame(width:widgetSize.width, height:widgetSize.width)
            } // ForEach
            
          } // LazyVGrid
          .frame(minHeight: scrollView.size.height, alignment:.top)
          .padding(.top, 20)
          .padding(.bottom, 100)
          
          
        }
        
        .padding(.top, -20)
        .padding(.horizontal, 16)
        .frame(maxHeight:.infinity, alignment:.top)
        .padding(.bottom, 40)
        .overlay(alignment: .bottom) {
          if widgets.isEmpty {
            ContentUnavailableView {
              Label("Get Some Widgets", systemImage: "rectangle.3.offgrid.fill")
            } description: {
              Text("Open a widget from the web to add it here.")
              Button {
                getMoreWidgets()
              } label: {
                Label("Add widget", systemImage: "plus")
              }
            }
            .padding()
            .padding(.bottom, -20)
            .frame(maxWidth:320)
            .glassBackgroundEffect()
            .padding(.bottom, 40)
            .offset(z: 50)
          }
          
        } // overlay
        
        // ScrollView
        
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
          startRadius: 230,
          endRadius: 560.0 / 2
        ).offset(z: -100)
      )
      .ornament(attachmentAnchor: .scene(.bottom), contentAlignment:.bottom) {
        if (!widgets.isEmpty) {
          ZStack {
            Button(role: draggedWidget == nil ? .cancel : .destructive) {
              if let draggedWidget = draggedWidget {
                deleteWidget(draggedWidget)
              } else {
                getMoreWidgets()
              }
            } label: {
              Label(draggedWidget == nil ?
                    "Get Widgets" : "Delete Widget",
                    systemImage: draggedWidget == nil ? "plus" : "square.and.arrow.down")
              .padding(10)
            }.labelStyle(.titleAndIcon)
            
            
              .buttonBorderShape(.roundedRectangle(radius: 30))
              .buttonStyle(.borderless)
            
          }
          .dropDestination(for: String.self) { items, location in
            draggedWidget?.delete()
            draggedWidget = nil
            return true
          }
          .padding(10)
          .background(draggedWidget != nil ? .white.opacity(0.5) : .black.opacity(0.0))
          .glassBackgroundEffect()
          .padding(.bottom, 8)
          .animation(.spring(), value: draggedWidget)
          .animation(.spring(), value: isDragDestination)
          .animation(.spring(), value: widgets)
        }
      }
      
    }
//    .task {
//      print("Task")
//    }
    .onAppear() {
//      print("Appear")
      updateHue()
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        withAnimation(.spring) {
          isVisible = true
        }
      }
      
    
      Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
        updateHue()
      }
    }
    .windowGeometryPreferences(resizingRestrictions: .none)
    .defaultHoverEffect(.lift)
  }
  
  
  private func deleteWidget(_ widget: Widget) {
    if widget.persistentModelID == selection?.persistentModelID {
      selection = nil
    }
    modelContext.delete(widget)
  }
}

#Preview {
  WidgetPickerView(app:nil)
}
