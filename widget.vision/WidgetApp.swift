//
//  WebWidgetsApp.swift
//  ittybittywidgets
//
//  Created by Nicholas Jitkoff on 1/28/24.
//

import SwiftUI
import SwiftData
import Darwin

@main
struct WidgetApp: App {
  @Environment(\.openWindow) var openWindow
  @Environment(\.scenePhase) private var scenePhase
  
  private var container: ModelContainer?
  init() {
    do {
      container = try ModelContainer(
        for: Widget.self,
        configurations: ModelConfiguration()
      )
    } catch {
      print("An error occurred: \(error)")
      exit(0)
    }
  }
  
  var body: some Scene {
    WindowGroup {
      WidgetPickerView()
        .onOpenURL { (url) in
          print("🌐 Opening URL: \(url)")
          let location = url.absoluteString.replacingOccurrences(of: "widget-", with: "")
          let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
          let username = urlComponents?.user?.removingPercentEncoding ?? ""
          let widget = Widget( id: UUID(), name:url.host() ?? "NAME", location: location, style: .glass, options:username)
          container?.mainContext.insert(widget)
          try! container?.mainContext.save()
          openWindow(id: "widget", value: widget.persistentModelID)
        }
    }
    .modelContainer(container!)
    .windowResizability(.contentSize)
    .defaultSize(width: 500, height: 720)
    
    WindowGroup("Widget", id: "widget", for: PersistentIdentifier.self) { $id in
      if let id = id, let widget = container?.mainContext.model(for: id) as? Widget{
        WidgetView(widget:widget)
      }
    }
    .modelContainer(container!)
    .windowStyle(.plain)
    .windowResizability(.contentSize)
  }
}
