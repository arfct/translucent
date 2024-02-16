import SwiftUI

struct WidgetListItem: View {
  
  @Environment(\.openWindow) private var openWindow
  @Environment(\.dismissWindow) private var dismissWindow
  var widget: Widget
  
  var body: some View {
    VStack(alignment: .center) {
      Button {
        openWindow(id: "widget", value: widget.persistentModelID)
      } label: {
        
        
        ZStack() {
          if let file = widget.thumbnailFile, let image = UIImage(contentsOfFile: file.path) {
            if (image.size.width / image.size.height > 1.618) {
              Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth:240, maxHeight:170, alignment: .center)
                .fixedSize()
                .background(widget.backColor)
                .cornerRadius(widget.radius / widget.width * 200)
                .glassBackgroundEffect(in:RoundedRectangle(cornerRadius: 40),
                                       displayMode: (widget.style == .glass ) ? .always : .never)
              
            } else {
              Image(uiImage: image)
                .resizable()
                .scaledToFill()
              
                .frame(maxWidth:240, maxHeight:170, alignment: .top)
                .fixedSize()
                .background(widget.backColor)
                .glassBackgroundEffect(in:RoundedRectangle(cornerRadius: 40),
                                       displayMode: (widget.style == .glass ) ? .always : .never)
            }
          } else {
            Image(systemName: widget.icon)
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 24, height: 24)
              .padding(.bottom, 10)
              .font(Font.title.weight(.light))
          }
        }
        .cornerRadius(30)
        .frame(maxWidth:.infinity)
      }
      
      .frame(maxWidth: .infinity)
      
      HStack(alignment: .center, spacing: 10) {
        Text(widget.displayName)
          .font(.headline)
          .lineLimit(1)
      }.padding(.top, 4)
    }
    .buttonBorderShape(.roundedRectangle(radius: 40))
    .buttonStyle(.borderless)
    .hoverEffect(.lift)
    .frame(maxWidth: .infinity, alignment:.leading)
  }
}


#Preview("Preview", windowStyle: .automatic, traits: .sizeThatFitsLayout) {
  WidgetListItem(widget: .preview)
}
