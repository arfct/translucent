//
//  WidgetListView.swift
//  ittybittywidgets
//
//  Created by Nicholas Jitkoff on 1/29/24.
//

import SwiftUI
import SwiftData


struct WidgetListView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \Widget.lastOpened, order: .forward)
  var widgets: [Widget]
  
  @Environment(\.openWindow) private var openWindow
  
      @Environment(\.openURL) var openURL
  var viewModel: WidgetStore
  // Define the grid layout
   var data  = Array(1...20)
   let flexibleColumn = [
      GridItem(.flexible(minimum: 200, maximum: 250)),
      GridItem(.flexible(minimum: 200, maximum: 250)),
      GridItem(.flexible(minimum: 200, maximum: 250))
  ]
  
  var body: some View {
  
    HStack {
      Text("widget.vision")
        .font(.extraLargeTitle2)
      Spacer()
      Button {
        openURL(URL(string: "https://widget.vision/more")!)
      } label: {
        Image(systemName: "plus")
      }
      .buttonBorderShape(.circle)
    }.frame(idealWidth:320)
      
    LazyVGrid(columns: flexibleColumn, spacing: 20) {
      ForEach(viewModel.widgets) { widgetModel in
        Button{
          openWindow(value: widgetModel.id)
        } label: {
          VStack {
            Image(systemName: widgetModel.image ?? "globe")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 40, height: 40)
            Text(widgetModel.name).lineLimit(1)
          }
          .padding()
          .frame(maxWidth: .infinity, alignment:.leading)
        }
        .buttonBorderShape(.roundedRectangle)
        .contextMenu(ContextMenu(menuItems: {
          Button {
            viewModel.widgets.remove(at: viewModel.widgets.firstIndex(of: widgetModel)!)
          } label: {
            Label("Remove", systemImage: "trash")
          }
        }))
        .cornerRadius(5)
      }
      
      
      Button {
        openURL(URL(string: "https://widget.vision/more")!)
      } label: {
        VStack {
          Image(systemName: "ellipsis")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 40, height: 40)
          
          Text("More").lineLimit(1)
        }
        .padding()
        .frame(maxWidth: .infinity)
      }
    }.animation(.default)
  }
}

#Preview {
  WidgetListView(viewModel: WidgetStore())
    
}
