import SwiftUI

struct WidgetListItem: View {
  
  @Environment(\.openWindow) private var openWindow
  @Environment(\.dismissWindow) private var dismissWindow
    var widget: Widget
    
    var body: some View {

          Button {
            openWindow(id: "widget", value: widget.persistentModelID)
          } label: {
            VStack(alignment: .leading) {
              Image(systemName: widget.icon)
                .padding(.bottom, 10)
              Text(widget.displayName)
                .font(.headline)
                .foregroundColor(widget.foreColor)
              Text(widget.hostName ?? "")
                .font(.subheadline)
                .foregroundColor(widget.tintColor)
              
            }
            .frame(maxWidth: .infinity, alignment:.leading)
//            .padding(EdgeInsets(top: 20, leading: 30, bottom: 30, trailing: 30))
            .buttonBorderShape(.roundedRectangle)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1))
              
          

          }
        }
}


#Preview("Preview", windowStyle: .automatic, traits: .sizeThatFitsLayout) {
  WidgetListItem(widget: .preview)
}


//
//Button{
//          openWindow(value: widgetModel.id)
//        } label: {
//          VStack {
//            Image(systemName: widgetModel.image ?? "globe")
//              .resizable()
//              .aspectRatio(contentMode: .fit)
//              .frame(width: 40, height: 40)
//            Text(widgetModel.name).lineLimit(1)
//          }
//          .padding()
//          .frame(maxWidth: .infinity, alignment:.leading)
//        }
//        .buttonBorderShape(.roundedRectangle)
//        .contextMenu(ContextMenu(menuItems: {
//          Button {
//            viewModel.widgets.remove(at: viewModel.widgets.firstIndex(of: widgetModel)!)
//          } label: {
//            Label("Remove", systemImage: "trash")
//          }
//        }))
