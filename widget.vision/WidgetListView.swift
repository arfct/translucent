//
//  WidgetListView.swift
//  ittybittywidgets
//
//  Created by Nicholas Jitkoff on 1/29/24.
//

import SwiftUI

struct WidgetListView: View {
  @Environment(\.openWindow) private var openWindow
  
      @Environment(\.openURL) var openURL
  var viewModel: WidgetViewModel
  // Define the grid layout
   var data  = Array(1...20)
   let flexibleColumn = [
      GridItem(.flexible(minimum: 200, maximum: 250)),
      GridItem(.flexible(minimum: 200, maximum: 250)),
      GridItem(.flexible(minimum: 200, maximum: 250))
  ]
  
  var body: some View {
    LazyVGrid(columns: flexibleColumn, spacing: 20) {
      ForEach(viewModel.widgetModels) { widgetModel in
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
          .frame(maxWidth: .infinity)
        }
        .cornerRadius(10)
      }
      
      
      Button {
        openURL(URL(string: "https://widget.vision/more")!)
      } label: {
        VStack {
          Image(systemName: "plus")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 40, height: 40)
          
          Text("More").lineLimit(1)
        }
        .padding()
        .frame(maxWidth: .infinity)
        
        
      }
    }
  }
}

#Preview {
  WidgetListView(viewModel: WidgetViewModel())
    
}
