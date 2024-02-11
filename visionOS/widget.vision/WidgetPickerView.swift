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
    GridItem(.adaptive(minimum: 240, maximum: 480))
  ]
  
  func getMoreWidgets() {
    openURL(URL(string: "https://widget.vision/more")!)
    dismissWindow(id: "main")

  }
  
  var body: some View {
    VStack {
      ScrollView {
        Image("widget.vision")
          .renderingMode(.template)
          .resizable()
          .foregroundColor(Color(hue: hue, saturation: 0.2, brightness: 1.0))
          .aspectRatio(contentMode: .fit)
          .frame(maxWidth: 480)
          .padding(60)
          .padding(.top,40)
          .opacity(0.8)
        LazyVGrid(columns: columns, spacing: 20) {
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
        .padding(.horizontal, 20)
      }
      .frame(maxHeight:.infinity)
      .overlay(
        Button { getMoreWidgets() } label: {
          Label("Add widget", systemImage: "plus")
        }
          .padding(.bottom, 40), alignment: .bottom
      )
      
      .overlay {
        if widgets.isEmpty {
          ContentUnavailableView {
            Label("No Widgets", systemImage: "rectangle.3.offgrid.fill")
          } description: {
            Text("Open a widget from the web to add it")
//            Button {
//              getMoreWidgets()
//            } label: {
//              Label("Add widget", systemImage: "plus")
//            }

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
    .task {
      Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
        
        let currentTime = floor(Date().timeIntervalSince1970)
        let hueDeg = fmod(currentTime, 360)
        hue = hueDeg / 360.0
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
