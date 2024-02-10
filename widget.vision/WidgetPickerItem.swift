
import SwiftUI

struct WidgetListItem: View {
    var widget: Widget
    
    var body: some View {
        NavigationLink(value: widget) {
            HStack {
                RoundedRectangle(cornerRadius: 8)
//                    .fill(widget.color)
                    .frame(width: 64, height: 64)
                    .overlay {
                        Text(String(widget.displayName))
                            .font(.system(size: 48))
                            .foregroundStyle(.background)
                    }
                    .padding(.trailing)
                
                VStack(alignment: .leading) {
                    Text(widget.displayName)
                        .font(.headline)
                    Text(widget.hostName ?? "")
                        .font(.subheadline)
                    
                    if case let (start?) = (widget.lastOpened) {
                        Divider()
                        HStack {
                            Text(start, style: .date)
                            Image(systemName: "arrow.right")
                        }
                        .font(.caption)
                    }
                }
            }
        }
    }
}
//
//#Preview {
//    ModelContainerPreview(PreviewSampleData.inMemoryContainer) {
//        List {
//            WidgetListItem(widget: .preview)
//        }
//    }
//}
