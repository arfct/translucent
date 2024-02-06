//
//  WidgetListView.swift
//  ittybittywidgets
//
//  Created by Nicholas Jitkoff on 1/29/24.
//

import SwiftUI

struct WidgetListView: View {
  @Environment(\.openWindow) private var openWindow
  var viewModel: WidgetViewModel
  
  var body: some View {
    ForEach(viewModel.widgetModels) { widgetModel in
      Button{
        openWindow(value: widgetModel.id)
      } label: {
        Text(widgetModel.name)      .frame(maxWidth: .infinity)

      }
      
    }
  }
}

#Preview {
  WidgetListView(viewModel: WidgetViewModel())
    
}
