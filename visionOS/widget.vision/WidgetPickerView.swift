import SwiftUI
import SwiftData

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
    GridItem(.adaptive(minimum: 240, maximum: 240), spacing: 40, alignment: .center)
  ]
  
  func getMoreWidgets() {
    openURL(URL(string: "https://widget.vision/list")!)
    dismissWindow(id: "main")

  }
  func updateHue() {
    hue = fmod(floor(Date().timeIntervalSince1970), 360) / 360.0
  }
  
  var body: some View {
    NavigationStack {
      ScrollView {
        
        // MARK: Toolbar
        
        Image("widget.vision")
          .renderingMode(.template)
          .resizable()
          .foregroundColor(Color(hue: hue, saturation: 0.2, brightness: 1.0))
          .aspectRatio(contentMode: .fit)
          .frame(maxWidth: 480)
          .padding(.horizontal, 60)
          .padding(.bottom, 80)
          .padding(.top, 20)
          .opacity(0.8)
        
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

        // MARK: Grid
        LazyVGrid(columns: columns, spacing: 30) {
          ForEach(widgets) { widget in
            WidgetListItem(widget: widget)
              .contextMenu(ContextMenu(menuItems: {
                Button(role: .destructive) {
                  deleteWidget(widget)
                } label: {
                  Label("Remove", systemImage: "trash")
                }
              }))
          }
        }
        .padding(.horizontal, 40)
      }
      .frame(maxHeight:.infinity)
      
     
      .toolbar {

        ToolbarItem(placement: .topBarLeading) {
          Button { getMoreWidgets() } label: {
            Label("Get more widgets", systemImage: "safari")
          }.labelStyle(.titleAndIcon)
            .buttonStyle(.bordered)
//            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
        }
      }
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
    
    }
    .background(
      
      LinearGradient(gradient: Gradient(colors: [
        Color(hue: hue, saturation: 1.0, brightness: 0.3).opacity(0.5),
        Color(hue: fmod(hue + 1.0/6.0, 1.0), saturation: 0.2, brightness: 0.1).opacity(0.7)
      ]), startPoint: .topLeading, endPoint: .bottomTrailing)
      )
    .onAppear() {
      updateHue()
      Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
        updateHue()
      }
    }
  }
  
  private func deleteWidgets(at offsets: IndexSet) {
    withAnimation {
      offsets.map { widgets[$0] }.forEach(deleteWidget)
    }
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
