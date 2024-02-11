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
  
  let columns = [
    GridItem(.adaptive(minimum: 200, maximum: 300))
  ]
  
  func getMoreWidgets() {
    openURL(URL(string: "https://widget.vision/more")!)
    dismissWindow(id: "main")

  }
  
  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVGrid(columns: columns, spacing: 16) {
          ForEach(widgets) { widget in
            WidgetListItem(widget: widget)
              .contextMenu(ContextMenu(menuItems: {
                Button {
                  deleteWidget(widget)
                } label: {
                  Label("Remove", systemImage: "trash")
                }
              }))
          }
        }
      }
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
      .padding(40)
      .toolbar {
        ToolbarItem(placement: .principal) {
          Image("widget.vision")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 240)
            .padding(.leading, 20)
            .opacity(0.5)
            .mask(Color.blue)
        }
        ToolbarItemGroup(placement: .navigationBarTrailing) {
          Button { getMoreWidgets() } label: {
            Label("Add widget", systemImage: "plus")
          }
        }
      }
    }
    .background(
      LinearGradient(gradient: Gradient(colors: [
        Color(hue: hue, saturation: 1.0, brightness: 0.5).opacity(0.4),
        Color(hue: hue + 0.1, saturation: 0.5, brightness: 0.1).opacity(0.8)
      ]), startPoint: .topLeading, endPoint: .bottomTrailing)
      )
    .task {
      Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
        
        let currentTime = floor(Date().timeIntervalSince1970)
        let hueDeg = fmod(currentTime, 360)
        hue = hueDeg / 360.0
        
        print("Hue \(hueDeg)")
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
    WidgetPickerView()
//        .modelContainer(PreviewSampleData.container)
}
