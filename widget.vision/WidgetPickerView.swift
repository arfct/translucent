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
      GridItem(.adaptive(minimum: 80))
  ]
  var body: some View {
    NavigationStack {
      List(selection: $selection) {
        ForEach(widgets) { widget in
          WidgetListItem(widget: widget)
            .swipeActions(edge: .trailing) {
              Button(role: .destructive) {
                deleteWidget(widget)
                
              } label: {
                Label("Delete", systemImage: "trash")
              }
            }
            .onTapGesture {
              openWindow(id: "widget", value: widget.persistentModelID)
            }
            .onLongPressGesture {
              deleteWidget(widget)
            }
        }
        .onDelete(perform: deleteWidgets(at:))
      }
      .overlay {
        if widgets.isEmpty {
          ContentUnavailableView {
            Label("No Widgets", systemImage: "rectangle.3.offgrid.fill")
          } description: {
            Text("Open a widget from the web to add it")
          }
        }
      }
      .navigationTitle("Widgets")
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          EditButton()
            .disabled(widgets.isEmpty)
        }
        ToolbarItemGroup(placement: .navigationBarTrailing) {
          Spacer()

          Button {

            openURL(URL(string: "https://widget.vision/more")!)
          } label: {
            Label("Add widget", systemImage: "plus")
//            Label(title: "Add", icon: "plus")
          }
        }
      }
    }      .frame(width:500)

  }
  
  private func deleteWidgets(at offsets: IndexSet) {
    withAnimation {
      offsets.map { widgets[$0] }.forEach(deleteWidget)
    }
  }
  
  private func deleteWidget(_ widget: Widget) {
    /**
     Unselect the item before deleting it.
     */
    if widget.persistentModelID == selection?.persistentModelID {
      selection = nil
    }
    modelContext.delete(widget)
  }
}
//
//#Preview {
//    ContentView()
//        .modelContainer(PreviewSampleData.container)
//}
