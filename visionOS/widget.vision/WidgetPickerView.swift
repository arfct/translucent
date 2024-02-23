import SwiftUI
import SwiftData


struct Activity {
  static let openWidget = "vision.widget.open"
  static let openSettings = "vision.widget.settings"
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
  @State private var dragging = false
  @Environment(\.openURL) var openURL
  @Environment(\.openWindow) private var openWindow
  @Environment(\.dismissWindow) private var dismissWindow
  @State private var searchText: String = ""
  var app: WidgetApp?
  
  
  let columns =
  [
    GridItem(.adaptive(minimum: 200, maximum: 200), spacing: 20, alignment: .center)
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
        .padding(.bottom, -20)
      
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
                //                  .contextMenu(ContextMenu(menuItems: {
                //                    Button() {
                //                      widget.favorite.toggle()
                //                    } label: {
                //                      Label("Favorite", systemImage: widget.favorite ? "star.fill" : "star")
                //                    }
                //
                //                    ShareLink(
                //                      item: widget,
                //                      preview: SharePreview(
                //                        "\(widget.name) – Widget",
                //                        image: Image("AppIcon")
                //                      )
                //                    ) {
                //                      Text("Share Widget")
                //                      Image(systemName: "square.and.arrow.up")
                //                    }
                //                    .buttonBorderShape(.circle)
                //                    Divider()
                //                    Button(role: .destructive) {
                //                      deleteWidget(widget)
                //                    } label: {
                //                      Label("Remove Widget", systemImage: "minus.circle")
                //                    }
                //
                //                  }))
                
                  .scaleEffect(minProx * 0.8 + 0.2, anchor:.bottom)
                  .scaleEffect(maxProx * 0.8 + 0.2, anchor:.top)
                  .offset(z:combinedProx * 20)
                  .blur(radius: (1 - combinedProx) * 10)
                  .opacity(combinedProx)
                  .rotation3DEffect(.degrees(20.0 * (1.0 - minProx)), axis: (x: 1, y: 0, z: 0), anchor:.trailing)
                  .rotation3DEffect(.degrees(-20.0 * (1.0 - maxProx)), axis: (x: 1, y: 0, z: 0), anchor:.leading)
                  .onDrag {
                    dragging = true
                    let userActivity = NSUserActivity(activityType: Activity.openWidget)
                    userActivity.targetContentIdentifier = Activity.openWidget
                    try? userActivity.setTypedPayload(["modelId": widget.modelID])
                    let itemProvider = NSItemProvider(object: widget.id.uuidString as NSString)
                    itemProvider.registerObject(userActivity, visibility: .all)
                    return itemProvider
                  } preview: {
                    WidgetPickerItem(widget: widget, asDrag:true)
                  }
              }.frame(width:200, height:200)
            }
            .offset(x:
                      widgets.count == 1 ?  200.0 + 20.0 :
                      widgets.count == 2 ?  100.0 + 10.0 : 0)
            
            
            
            
          }   // Make the scroll view full-width
          .frame(minHeight: scrollView.size.height, alignment:.center)
          .padding(.bottom, 80)
          
        }
        .padding(.vertical, 20)
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
    .toolbar() {
      ToolbarItem(placement: .bottomOrnament) {
        if (!widgets.isEmpty) {
          Button { getMoreWidgets() } label: {
            Label(dragging ? "Delete widget" : "Get more widgets", systemImage: dragging ? "remove" : "plus")
          }.labelStyle(.titleAndIcon)
            .buttonBorderShape(.roundedRectangle(radius: 30))
            .buttonStyle(.borderless)
            .dropDestination(for: Data.self) { items, location in
              print("items \(items.first) \(type(of:items.first)) \(location)")
//              let modelID = try? JSONDecoder().decode(PersistentIdentifier.self, from: items.first) {
////                  let id = modelID
//                }

              return true
            }

        }
        
        
        
      }
    }.offset(z: -40)
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
