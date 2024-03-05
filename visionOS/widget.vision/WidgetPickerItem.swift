import SwiftUI
import RealityKit

struct WidgetPickerItem: View {
  
  @Environment(\.openWindow) private var openWindow
  @Environment(\.dismissWindow) private var dismissWindow
  @ObservedObject var widget: Widget
  @State var asDrag = false;
  
  let iconSize = CGSize(width: 160, height: 160)
  
  var body: some View {
    VStack(alignment: .center) {
      // MARK: icon
      Button {
        openWindow(id: "widget", value: widget.persistentModelID)
      } label: {
        
        ZStack() {
          if let image = widget.thumbnailUIImage {
            
          
            if (image.size.width / image.size.height > (iconSize.width / iconSize.height)) {
              // Wide widget
              Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth:iconSize.width, maxHeight:iconSize.height, alignment: .center)
                .fixedSize()

              
            } else {
              // Tall widget
              Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth:iconSize.width, maxHeight:iconSize.height, alignment: .top)
                .fixedSize()

            }
          } else {
            // Widget without thumbnail
            VStack {
              Image(systemName: widget.icon ?? "globe")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64)
                .font(Font.title.weight(.light))
            }
            .frame(minWidth:iconSize.width, maxWidth:.infinity, minHeight:iconSize.height, maxHeight:iconSize.height, alignment: .center)
          }
        }
        .background(widget.backColor)
        .background(asDrag ? .white.opacity(0.05) : .clear)
        .glassBackgroundEffect(in:RoundedRectangle(cornerRadius: 30),
                               displayMode: (true && !asDrag) ? .always : .never)
        .cornerRadius(30)
        .frame(maxWidth:.infinity)
        
      } // MARK: /icon
      .frame(maxWidth: .infinity)
      
      HStack(alignment: .center, spacing: 10) {
        Text(widget.displayName)
          .font(.headline)
          .lineLimit(1)
          .opacity(asDrag ? 0.0 : 1.0)
          .padding(.top, 4)
      }
    }
    .buttonBorderShape(.roundedRectangle(radius: 30))
    .buttonStyle(.borderless)
    .frame(maxWidth: .infinity, alignment:.leading)

  }
}


#Preview("Preview", windowStyle: .automatic, traits: .sizeThatFitsLayout) {
  WidgetPickerItem(widget: .preview)
}
