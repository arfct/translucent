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
      //      try AVAudioSession.sharedInstance().setActive(true)
      
      if let path = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
        
        try? FileManager.default.createDirectory(at: path
          .appendingPathComponent("thumbnails", isDirectory: true), withIntermediateDirectories: true)
      }
      
      
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
    
    WindowGroup("Main", id: "main") { value in
      GeometryReader { mainWindow in
        WidgetPickerView(app: self)
          .onOpenURL {
            showWindowForURL($0)
          }
          .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) {
            showWindowForURL($0.webpageURL)
          }
          .onChange(of: mainWindow.size) {
            windowWidth = mainWindow.size.width
            windowHeight = mainWindow.size.height
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
      .frame(idealWidth: 560, idealHeight: 680,
             alignment: .center)
      .fixedSize(horizontal: true, vertical:true)
      .preferredSurroundingsEffect(.systemDark)
      
    } defaultValue: { "main" }
    .modelContainer(container!)
    .windowResizability(.contentSize)
    .defaultSize(width: 560, height: 680)
    .windowStyle(.plain)

    // MARK: - Widget Windows
    
    WindowGroup("Widget", id: "widget", for: PersistentIdentifier.self) { $id in
      ZStack {
        if let id = id, let widget = container?.mainContext.model(for: id) as? Widget{
          WidgetView(widget:widget, app:self)
            .onAppear() { widget.lastOpened = .now }
        } else { 
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .primary))
            .scaleEffect(1.0, anchor: .center)
        }
      }
      .onContinueUserActivity(Activity.openWidget, perform: { activity in
        if let info = activity.userInfo,
           let data = info["modelId"] as? Data,
           let modelID = try? JSONDecoder().decode(PersistentIdentifier.self, from: data) {
          id = modelID
        }
      })
      .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) {
        showWindowForURL($0.webpageURL)
      }
      .onOpenURL { showWindowForURL($0) }

    }
    .handlesExternalEvents(matching: [Activity.openWidget])
    .modelContainer(container!)
    .windowStyle(.plain)
    .windowResizability(.contentSize)
    .defaultSize(width: 320, height: 320)
    
    
    // MARK: - Settings Window
    // TODO: These don't work with dragging for some reason?
    
    WindowGroup("Settings", id: "widgetSettings", for: Foundation.Data.self) { $data in
      ZStack {
        if let data = data,
           let modelID = try? JSONDecoder().decode(PersistentIdentifier.self, from: data ),
           let widget = container?.mainContext.model(for: modelID) as? Widget{
              WidgetSettingsView(widget:widget, callback: {
                dismissWindow(id: "widgetSettings")
              }).task{
                print("Open Settings for \(widget.name)")
              }
        } else {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .primary))
            .scaleEffect(1.0, anchor: .center)
        }
      }
      .onContinueUserActivity(Activity.openSettings, perform: { activity in
        if let info = activity.userInfo,
           let modelData = info["modelId"] as? Data {
          data = modelData
        }
      })
    }
    .handlesExternalEvents(matching: ["settings"])
    .modelContainer(container!)
    .windowStyle(.automatic)
    .windowResizability(.contentSize)
    .defaultSize(width: 640, height: 640)
    
  
    // MARK: Preview Window
    WindowGroup("Preview", id: "preview", for: URL.self) { $url in
      ZStack {
        PreviewView(url:url)

      }
      .onContinueUserActivity(Activity.openPreview, perform: { activity in
        if let info = activity.userInfo,
          let modelData = info["url"] as? URL {
          url = modelData
        }
      })
    }
    .handlesExternalEvents(matching: [Activity.openPreview])
    .windowStyle(.volumetric)
    
    
    
    // MARK: /Body
  }
}
