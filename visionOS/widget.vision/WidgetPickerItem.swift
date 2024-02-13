import SwiftUI

struct WidgetListItem: View {
  
  @Environment(\.openWindow) private var openWindow
  @Environment(\.dismissWindow) private var dismissWindow
    var widget: Widget
    
  var body: some View {
    
    Button {
      openWindow(id: "widget", value: widget.persistentModelID)
    } label: {
      VStack(alignment: .center) {
        Image(systemName: widget.icon)
          .padding(.bottom, 10)
        Text(widget.displayName)
          .font(.headline)
          .foregroundColor(widget.foreColor)
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity)
      .padding()
    }
    .buttonStyle(.borderless)
    .buttonBorderShape(.roundedRectangle)
    .background(.white.opacity(0.1))
    .cornerRadius(30)
//  .blendMode(.multiply)
//    .glassBackgroundEffect()
    .frame(maxWidth: .infinity, maxHeight:200, alignment:.leading)
  }
}


#Preview("Preview", windowStyle: .automatic, traits: .sizeThatFitsLayout) {
  WidgetListItem(widget: .preview)
}
