import SwiftUI
import SwiftData

struct WidgetPickerView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \Widget.lastOpened, order: .forward)
  var widgets: [Widget]
  
  @State private var showAddWidget = false
  @State private var selection: Widget?
  @State private var path: [Widget] = []
  
  @Environment(\.openURL) var openURL
  @Environment(\.openWindow) private var openWindow
  
  let columns = [
    GridItem(.adaptive(minimum: 200, maximum: 300))
  ]
  
  func getMoreWidgets() {
    openURL(URL(string: "https://widget.vision/more")!)
  }
  
  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVGrid(columns: columns, spacing: 16) {
          ForEach(widgets) { widget in
            WidgetListItem(widget: widget)
              .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                  withAnimation {
                    deleteWidget(widget)
                  }
                } label: {
                  Label("Delete", systemImage: "trash")
                }
              }
              .onTapGesture {
                openWindow(id: "widget", value: widget.persistentModelID)
              }
              .contentShape(RoundedRectangle(cornerRadius: 80, style: .continuous))
              .contextMenu(ContextMenu(menuItems: {
                Button {
                  deleteWidget(widget)
                } label: {
                  Label("Remove", systemImage: "trash")
                }
              }))
          }
          .onDelete(perform: deleteWidgets(at:))
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
        ToolbarItem(placement: .navigationBarLeading) {
          Image("widget.vision")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 240)
            .padding(.leading, 20)
        }
        ToolbarItemGroup(placement: .navigationBarTrailing) {
          Spacer()
          
          Button {
            getMoreWidgets()
          } label: {
            Label("Add widget", systemImage: "plus")
          }
        }
      }
    }
    .frame(minWidth: 400, idealWidth: 500, maxWidth: .infinity, minHeight: 400, idealHeight: 700, maxHeight: .infinity, alignment: .center)
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
