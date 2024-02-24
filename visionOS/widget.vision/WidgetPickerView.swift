import SwiftUI
import SwiftData


struct Activity {
  static let openWidget = "vision.widget.open"
  static let openSettings = "vision.widget.settings"
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
  @Environment(\.scenePhase) private var scenePhase
  
  @Query(sort: [SortDescriptor(\Widget.favorite, order: .reverse), SortDescriptor(\Widget.lastOpened, order: .reverse)])
  
  var widgets: [Widget]
  
  @State private var showAddWidget = false
  @State private var selection: Widget?
  @State private var path: [Widget] = []
  @State private var hue: CGFloat = 0.6
  @State private var draggedWidget: Widget?
  @State var isDragDestination: Bool = false
  @Environment(\.openURL) var openURL
  @Environment(\.openWindow) private var openWindow
  @Environment(\.dismissWindow) private var dismissWindow
  @State private var searchText: String = ""
  var app: WidgetApp?
  
  
  let columns =
  [
    GridItem(.adaptive(minimum: 200, maximum: 200), spacing: 20, alignment: .center)
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
  
  
  let widgetHeight = 200
  
  var body: some View {
    VStack {
      Image("widget.vision")
        .renderingMode(.template)
        .resizable()
        .foregroundColor(Color(hue: hue, saturation: 0.2, brightness: 1.0))
        .aspectRatio(contentMode: .fit)
        .opacity(1.0)
        .shadow(color:.black.opacity(0.5), radius: 10, y: 3)
        .offset(z: 40)
        .padding(.bottom, -80)
      
      if (false){
        HStack() {
          TextField("Search", text: $searchText)
            .padding()
            .frame(maxWidth:320)
          PasteButton(payloadType: URL.self) { urls in
            if let url = urls.first {
              DispatchQueue.main.async {
                app?.showWindowForURL(url)
              }
            }
          }
          .buttonBorderShape(.circle)
          .buttonStyle(.borderless)
          .labelStyle(.titleOnly)
          .tint(.secondary)
        }.padding(.horizontal, 20)
          .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 100))
        Spacer(minLength: 20)
      }
      
      GeometryReader { scrollView in
        ScrollView() {
          
          // MARK: Grid
          LazyVGrid(columns: columns, alignment: .center, spacing: 20) {
            
            ForEach(widgets) { widget in
              GeometryReader { widgetView in
                let minProx = proximity(of:widgetView, to:scrollView, distance:200, at: .minYEdge)
                let maxProx = proximity(of:widgetView, to:scrollView, distance:200, at: .maxYEdge)
                let combinedProx = minProx * maxProx
                
                WidgetPickerItem(widget: widget)
                  .contentShape(.contextMenuPreview,.rect(cornerRadius: 30).inset(by: 1))
                  .scaleEffect(minProx * 0.8 + 0.2, anchor:.bottom)
                  .scaleEffect(maxProx * 0.8 + 0.2, anchor:.top)
                  .offset(z:combinedProx * 20)
                  .blur(radius: (1 - combinedProx) * 10)
                  .opacity(combinedProx)
                  .rotation3DEffect(.degrees(20.0 * (1.0 - minProx)), axis: (x: 1, y: 0, z: 0), anchor:.trailing)
                  .rotation3DEffect(.degrees(-20.0 * (1.0 - maxProx)), axis: (x: 1, y: 0, z: 0), anchor:.leading)
                  .transition(.move(edge: .trailing))
                  .onDrag {
                    print(widget)
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
              }.frame(width:200, height:200)
            }

   
            if (widgets.count < 9) {
              ForEach((widgets.count...8), id: \.self) { index in
                VStack {
                  RoundedRectangle(cornerRadius: 30)
                    .fill(colors[index].opacity(0.3))
                    .glassBackgroundEffect()
                    .frame(width:200, height:150)
                }.padding(.bottom, 50)
                
              }
            }
            
            
          }   // Make the scroll view full-width
          .frame(minHeight: scrollView.size.height, alignment:.center)
        }
        .padding(.vertical, 0)
        .padding(.horizontal, 20)
        .frame(maxHeight:.infinity, alignment:.top)

        .overlay {
          if widgets.isEmpty {
            ContentUnavailableView {
              Label("No Widgets", systemImage: "rectangle.3.offgrid.fill")
            } description: {
              Text("Open a widget from the web to add it")
              Button {
                getMoreWidgets()
              } label: {
                Label("Add widget", systemImage: "plus")
              }
              
            }.glassBackgroundEffect()
          }
        }
        .frame(maxHeight:.infinity, alignment:.center)
        
      } // MARK: end scroll view
      
      
    }
    
    .offset(z: -40)
    
    .background(
      RadialGradient(
        gradient: Gradient(colors: [
          .black.opacity(0.10),
          .black.opacity(0.08),
          .black.opacity(0.04),
          .black.opacity(0.01),
          .black.opacity(0.005),
          .clear]),
        center: .center,
        startRadius: 200,
        endRadius: 320
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
                  "Get More Widgets" : "Drag to Delete",
                  systemImage: draggedWidget == nil ? "plus" : "trash")
            .padding(draggedWidget == nil ? 10 : 20)
          }.labelStyle(.titleAndIcon)
          
          
            .buttonBorderShape(.roundedRectangle(radius: 30))
            .buttonStyle(.borderless)
            .frame(minWidth:260)
          
        }
//        .onDrop(
//          of: ["public.text"],
//          delegate: WidgetPickerDropDelegate(picker:nil)
//        )
        .dropDestination(for: String.self) { items, location in
          draggedWidget?.delete()
          draggedWidget = nil
          return true
        }
        .padding(10)

        .background(draggedWidget != nil ? .white.opacity(0.7) : .black.opacity(0.0))
        .glassBackgroundEffect()
        .animation(.spring(), value: draggedWidget)
        .animation(.spring(), value: isDragDestination)
        .animation(.spring(), value: widgets)
      }
    }
    
    
    .onAppear() {
      updateHue()
      Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
        updateHue()
      }
    }
    .onChange(of: scenePhase) {
      print("MainWindow Phase \(scenePhase)")
    }
    
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
