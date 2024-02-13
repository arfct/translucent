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
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 40, height: 40)
          .padding(.bottom, 10)
        
          .font(Font.title.weight(.light))
        
        
        Text(widget.displayName)
          .font(.headline)
          .foregroundColor(widget.foreColor)
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity)
      .padding(.horizontal, 0)
      .padding(.vertical , 20)
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
