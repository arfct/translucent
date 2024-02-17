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
import AVFAudio
@main
struct WidgetApp: App {
  @Environment(\.openWindow) var openWindow
  @Environment(\.dismissWindow) var dismissWindow
  @Environment(\.scenePhase) private var scenePhase
  @AppStorage("windowWidth") var windowWidth = 540.0
  @AppStorage("windowHeight") var windowHeight = 680.0
  
  // MARK: - ModelContainer
  private var container: ModelContainer?
  init() {
    do {
      container = try ModelContainer(
        for: Widget.self,
        configurations: ModelConfiguration()
      )
      container?.mainContext.autosaveEnabled = true
      
      try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
      try AVAudioSession.sharedInstance().setActive(true)
      
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
    openWindow(id: "widget", value: widget.persistentModelID)
  }
  
  var body: some Scene {
    
    
    // MARK: - Main Window
    
    WindowGroup("Main", id: "main") {
      GeometryReader { geometry in
        WidgetPickerView(app: self)
          .onOpenURL {
            showWindowForURL($0)
            dismissWindow(id: "main")
          }
          .onContinueUserActivity(Activity.openWidget, perform: { activity in
            if let info = activity.userInfo {
              if let data = info["modelId"] as? Data {
                let modelID = try! JSONDecoder().decode(PersistentIdentifier.self, from: data)
                openWindow(id: "widget", value: modelID)
              }
            }
          })
        
          .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) {
            showWindowForURL($0.webpageURL)
          }
          .onChange(of: geometry.size) {
            windowWidth = geometry.size.width
            windowHeight = geometry.size.height
          }
          .onDrop(of: [.url], isTargeted: nil) { providers, point in
            for provider in providers {
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
    
    // MARK: - Widget Windows
    
    WindowGroup("Widget", id: "widget", for: PersistentIdentifier.self) { $id in
      if let id = id, let widget = container?.mainContext.model(for: id) as? Widget{
        WidgetView(widget:widget, app:self)
          .onOpenURL { showWindowForURL($0) }
          .onContinueUserActivity("openWidget", perform: { activity in
            print("Activity")
          })
          .onContinueUserActivity(Activity.openWidget, perform: { activity in
            print("Activity")
            if let info = activity.userInfo {
              if let data = info["modelId"] as? Data {
                let modelID = try! JSONDecoder().decode(PersistentIdentifier.self, from: data)
                openWindow(id: "widget", value: modelID)
              }
            }
          })
        
          .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) {
            showWindowForURL($0.webpageURL)
          }
          .task {
            widget.lastOpened = .now
          }
      } else {
        Text("No Widget with ID: \(id)")
      }
    }
    .handlesExternalEvents(matching: ["openWidget"])
    .modelContainer(container!)
//    .windowStyle(.plain)
    .windowResizability(.contentSize)
    .defaultSize(width: 360, height: 360)
    
    
    // MARK: - Settings Window
    // TODO: These don't work for some reason?
    
    WindowGroup("Settings", id: "widgetSettings", for: Foundation.Data.self) { $data in
      if let data = data {
        if let modelID = try? JSONDecoder().decode(PersistentIdentifier.self, from: data ) {
          if let widget = container?.mainContext.model(for: modelID) as? Widget{
            WidgetSettingsView(widget:widget, callback: {
              dismissWindow(id: "widgetSettings")
            }).task{
              print("Open Settings for \(widget.name)")
            }
          } else {
            
          }
        }
      }
    }
    .handlesExternalEvents(matching: ["settings"])
    .modelContainer(container!)
    .windowStyle(.automatic)
    .windowResizability(.contentSize)
    .defaultSize(width: 480, height: 360)
  }
}
