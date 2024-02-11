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
  @AppStorage("windowWidth") var windowWidth = 500.0
  @AppStorage("windowHeight") var windowHeight = 720.0
  
  private var container: ModelContainer?
  init() {
    do {
      container = try ModelContainer(
        for: Widget.self,
        configurations: ModelConfiguration()
      )
      container?.mainContext.autosaveEnabled = true
    } catch {
      print("An error occurred: \(error)")
      exit(0)
    }
  }
  
  var body: some Scene {
    WindowGroup(id: "main") {
      GeometryReader { geometry in
        WidgetPickerView()
          .onOpenURL { (url) in
            print("🌐 Opening URL: \(url)")
            let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let username = urlComponents?.user?.removingPercentEncoding ?? ""
            var location = url.absoluteString.replacingOccurrences(of: "widget-", with: "")
            if let offset = location.firstIndex(of: "@")?.utf16Offset(in: location) {
              location = "https://" + String(location.dropFirst(offset + 1))
              print("location \(location)")
            }
            let widget = Widget( id: UUID(), name:url.host() ?? "NAME", location: location, style: .glass, options:username)
            container?.mainContext.insert(widget)
            try! container?.mainContext.save()
            print("widget.persistentModelID \(widget.persistentModelID)")
            openWindow(id: "widget", value: widget.persistentModelID)
          }
          .onChange(of: geometry.size) {
            windowWidth = geometry.size.width
            windowHeight = geometry.size.height
          }
      }.frame(minWidth: 480, idealWidth: 500, maxWidth: .infinity, minHeight: 400, idealHeight: 700, maxHeight: .infinity, alignment: .center)
    }
    .modelContainer(container!)
    .windowResizability(.contentSize)
    .defaultSize(width: windowWidth, height: windowHeight)
    
    
    WindowGroup("Widget", id: "widget", for: PersistentIdentifier.self) { $id in
      if let id = id, let widget = container?.mainContext.model(for: id) as? Widget{
        WidgetView(widget:widget)
          .task {
            print("Opened", widget.description)
            widget.lastOpened = .now
          }
      }
    }
    .modelContainer(container!)
    .windowStyle(.plain)
    .windowResizability(.contentSize)
    .defaultSize(width: 360, height: 360)
    
  }
}
