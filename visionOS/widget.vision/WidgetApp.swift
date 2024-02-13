//
//  WebWidgetsApp.swift
//  ittybittywidgets
//
//  Created by Nicholas Jitkoff on 1/28/24.
//

import SwiftUI
import SwiftData
import Darwin
import UniformTypeIdentifiers

@main
struct WidgetApp: App {
  @Environment(\.openWindow) var openWindow
  @Environment(\.scenePhase) private var scenePhase
  @AppStorage("windowWidth") var windowWidth = 540.0
  @AppStorage("windowHeight") var windowHeight = 680.0
  
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
  
  @MainActor func showWindowForURL(_ url: URL?) {
    guard let url = url else { return }
    let widget = Widget(url:url)
    container?.mainContext.insert(widget)
    try! container?.mainContext.save()
    print("widget.persistentModelID \(widget.persistentModelID.id.hashValue)")
    openWindow(id: "widget", value: widget.persistentModelID)
  }
  
  var body: some Scene {
    WindowGroup(id: "main") {
      GeometryReader { geometry in
        WidgetPickerView(app: self)
          .onOpenURL { showWindowForURL($0) }
          .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) {
            showWindowForURL($0.webpageURL)
          }
          .onChange(of: geometry.size) {
            windowWidth = geometry.size.width
            windowHeight = geometry.size.height
          }
          .onDrop(of: [.url], isTargeted: nil) { providers, point in
            
            for provider in providers {

              print("Provider \(provider)");
              _ = provider.loadObject(ofClass: URL.self) { url,arg  in

                DispatchQueue.main.async {
                  showWindowForURL(url)
                }
              }
            }
            
            return true
          }
      }
      .frame(minWidth: 360, idealWidth: 540, maxWidth: .infinity,
              minHeight: 400, idealHeight: 680, maxHeight: .infinity,
              alignment: .center)
    }
    .modelContainer(container!)
    .windowResizability(.contentSize)
    .defaultSize(width: windowWidth, height: windowHeight)
    
    WindowGroup("Widget", id: "widget", for: PersistentIdentifier.self) { $id in
      if let id = id, let widget = container?.mainContext.model(for: id) as? Widget{
        WidgetView(widget:widget)
          .onOpenURL { showWindowForURL($0) }
          .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) {
            showWindowForURL($0.webpageURL)
          }
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
