import SwiftUI
import SwiftData


struct Activity {
  static let openWidget = "vision.widget.open"
  static let openSettings = "vision.widget.settings"
}


struct WidgetPickerView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \Widget.lastOpened, order: .reverse)
  var widgets: [Widget]
  
  @State private var showAddWidget = false
  @State private var selection: Widget?
  @State private var path: [Widget] = []
  @State private var hue: CGFloat = 0.6
  @Environment(\.openURL) var openURL
  @Environment(\.openWindow) private var openWindow
  @Environment(\.dismissWindow) private var dismissWindow
  @State private var searchText: String = ""
  var app: WidgetApp?
  
  let columns = [
    GridItem(.adaptive(minimum: 200, maximum: 200), spacing: 40, alignment: .center)
  ]
  
  func getMoreWidgets() {
    openURL(URL(string: "https://widget.vision/list")!)
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
      value = innerFrame.minY
    case .maxYEdge:
      start = outerFrame.maxY
      end = outerFrame.maxY - distance
      value = innerFrame.minY
    }

    let fraction = max(0, min(1, (value - start) / (end - start)))
    print("Frac \(start) \(value) \(end) = \(fraction)")
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
        .frame(maxWidth: 480)
        .padding(.horizontal, 60)
        .opacity(0.8)
        .shadow(color:.black, radius: 10, y: 3)
      Button { getMoreWidgets() } label: {
        Label("Get more widgets", systemImage: "plus")
      }.labelStyle(.titleAndIcon)
//        .background(Color(hue: hue, saturation: 0.2, brightness: 0.5))
        .buttonBorderShape(.roundedRectangle(radius: 40))
        .buttonStyle(.borderless)
        .glassBackgroundEffect()
      
      // MARK: Toolbar

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
        ScrollView(.horizontal) {

          
          // MARK: Grid
          LazyHGrid(rows: columns, spacing: 30) {
            ForEach(widgets) { widget in
              GeometryReader { widgetView in
                let minProx = proximity(of:widgetView, to:scrollView, distance:200, at: .minXEdge)
                let maxProx = proximity(of:widgetView, to:scrollView, distance:200, at: .maxXEdge)
                let combinedProx = minProx * maxProx
                
                WidgetListItem(widget: widget)
                  .contentShape(.contextMenuPreview,.rect(cornerRadius: 40))
                  .contextMenu(ContextMenu(menuItems: {
                    Button(role: .destructive) {
                      deleteWidget(widget)
                    } label: {
                      Label("Remove widget", systemImage: "minus.circle")
                    }
                  }))

                  .scaleEffect(minProx, anchor:.trailing)
                  .scaleEffect(maxProx, anchor:.leading)
                
                  .scrollTargetLayout()
                  .offset(z:combinedProx * 100)
                  .blur(radius: (1 - proximity(of:widgetView, to:scrollView)) * 10)
                  .opacity(combinedProx)
                  .rotation3DEffect(.degrees(-90.0 * (1.0 - minProx)), axis: (x: 0, y: 1, z: 0), anchor:.trailing)
                  .rotation3DEffect(.degrees(90.0 * (1.0 - maxProx)), axis: (x: 0, y: 1, z: 0), anchor:.leading)
                  .onDrag {
                    let userActivity = NSUserActivity(activityType: Activity.openWidget)
                    userActivity.targetContentIdentifier = Activity.openWidget
                    try? userActivity.setTypedPayload(["modelId": widget.modelID])
                    let itemProvider = NSItemProvider(object: widget.id.uuidString as NSString)
                    itemProvider.registerObject(userActivity, visibility: .all)
                    return itemProvider
                  } preview: {
                    WidgetListItem(widget: widget, asDrag:true)
                  }
              }.frame(width:200, height:200)
            }
          }
          
        }
        
          .scrollTargetBehavior(.viewAligned)
        .frame(maxHeight:.infinity)
        
        
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
              
            }
          }
        }
      } // MARK: end scroll view
      
      
      
      
    }
    .toolbar() {
      ToolbarItem(placement: .bottomOrnament) {
        
        
        
        
      }
    }
    //    .background(
    //
    //      LinearGradient(gradient: Gradient(colors: [
    //        Color(hue: hue, saturation: 1.0, brightness: 0.3).opacity(0.5),
    //        Color(hue: fmod(hue + 1.0/6.0, 1.0), saturation: 0.2, brightness: 0.1).opacity(0.7)
    //      ]), startPoint: .topLeading, endPoint: .bottomTrailing)
    //      )
    .onAppear() {
      updateHue()
      Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
        updateHue()
      }
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
