//
//  WebWidgetsApp.swift
//  ittybittywidgets
//
//  Created by Nicholas Jitkoff on 1/28/24.
//

import SwiftUI

@main
struct WidgetApp: App {
    var body: some Scene {
      let viewModel = WidgetViewModel()
      WindowGroup {
        WidgetListView(viewModel: viewModel)
          .onOpenURL { (url) in
              // Handle url here
          print(url)
          }
          .padding()
          .glassBackgroundEffect(displayMode: .never)
      }.defaultSize(CGSize(width:320, height:320))
      
      
      
      WindowGroup(for: WidgetModel.ID.self) { $widgetId in
        if let widgetId = widgetId, let widgetModel = viewModel[widgetId: widgetId] {
          WidgetView(widgetModel:widgetModel)
        }
      }
      .windowStyle(.plain)
      .windowResizability(.contentSize)
      .windowResizability(.contentSize) // <- 2. Add the restriction here
      .defaultSize(CGSize(width: 320, height: 180))
      
      
        
    }
}
