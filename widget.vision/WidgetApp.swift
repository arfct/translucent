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
  @StateObject private var store = WidgetStore()

    var body: some Scene {
      let viewModel = WidgetViewModel()
      WindowGroup {
        WidgetListView(viewModel: viewModel)
          .onOpenURL { (url) in
            print("url \(url)")
            let location = url.absoluteString.replacingOccurrences(of: "widget-", with: "")
            let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let username = urlComponents?.user?.removingPercentEncoding ?? ""
              
            let newWidgetModel = WidgetModel( id: UUID(), name:url.host() ?? "", location: location, style: .glass, options:username)
            openWindow(value: newWidgetModel)
            
          }
          .padding(40)
          .glassBackgroundEffect(displayMode: .never)
          .task {
            do {
              try await store.load()
            } catch {
              fatalError(error.localizedDescription)
            }
          }
      }
      .windowResizability(.contentSize)
//      .defaultSize(CGSize(width:720, height:480))
      
      
      
      WindowGroup(for: WidgetModel.ID.self) { $widgetId in
        if let widgetId = widgetId, let widgetModel = viewModel[widgetId: widgetId] {
          WidgetView(widgetModel:widgetModel)
            .frame(minWidth: widgetModel.width, maxWidth: .infinity,
                 minHeight: widgetModel.height, maxHeight: .infinity)
            .task {
              print(widgetModel)
            }
        }
      }
      .windowStyle(.plain)
      .windowResizability(.contentSize)
      .defaultSize(CGSize(width: 360, height: 180))
      
      WindowGroup(for: WidgetModel.self) { $widgetModel in
        if let widgetModel = widgetModel {
          WidgetView(widgetModel: widgetModel)

            .frame(minWidth: widgetModel.width, maxWidth: .infinity,
                 minHeight: widgetModel.height, maxHeight: .infinity)
        }
      }
      .windowStyle(.plain)
      .windowResizability(.contentSize)
      .defaultSize(CGSize(width: 360, height: 180))
      
      
      
        
    }
}
