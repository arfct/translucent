//
//  WebWidgetsApp.swift
//  ittybittywidgets
//
//  Created by Nicholas Jitkoff on 1/28/24.
//

import SwiftUI

@main
struct WidgetApp: App {
  @Environment(\.openWindow) var openWindow
//  @StateObject private var store = WidgetStore()

    var body: some Scene {
      let viewModel = WidgetViewModel()
      WindowGroup {
        WidgetListView(viewModel: viewModel)
          .onOpenURL { (url) in
  
            let newWidgetModel = WidgetModel( id: UUID(), name:"", location: url.absoluteString.replacingOccurrences(of: "widget-", with: ""), style: .glass)
            openWindow(value: newWidgetModel)
          print(url)
          }
          .padding()
          .glassBackgroundEffect(displayMode: .never)
//          .task {
//                           do {
//                               try await store.load()
//                           } catch {
//                               fatalError(error.localizedDescription)
//                           }
//                       }
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
      
      WindowGroup(for: WWWidgets.WidgetModel.self) { $widgetModel in
        if let widgetModel = widgetModel {
          WidgetView(widgetModel: widgetModel)
        }
      }
      .windowStyle(.plain)
      .windowResizability(.contentSize)
      .defaultSize(CGSize(width: 320, height: 180))
      
      
        
    }
}
