
import SwiftUI

extension URL {
    static var documentsDirectory: URL? {
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
      
        return URL(string: documentsDirectory)
    }

    static func urlInDocumentsDirectory(with filename: String) -> URL? {
      print(documentsDirectory?.appendingPathComponent(filename))
        return documentsDirectory?.appendingPathComponent(filename)
    }
}

struct WidgetListItem: View {
    var widget: Widget
    
    var body: some View {

        HStack {
          ZStack {
//            AsyncImage(url: URL.urlInDocumentsDirectory(with: "36E7AE85-4084-4CE7-97D0-8C502025445D.png"))
//              .frame(width: 300, height: 200)
            VStack(alignment: .leading) {
              Image(systemName: "rectangle.ratio.4.to.3.fill")
                .padding(.bottom, 10)
              Text(widget.displayName)
                .font(.headline)
              Text(widget.hostName ?? "")
                .font(.subheadline)
            }.padding(EdgeInsets(top: 20, leading: 30, bottom: 30, trailing: 30))
          }
        }.buttonBorderShape(.roundedRectangle)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .frame(maxWidth: .infinity, alignment:.leading)
        .glassBackgroundEffect()
    }

}


#Preview("HI?", windowStyle: .automatic, traits: .sizeThatFitsLayout) {
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
