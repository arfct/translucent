import SwiftUI
import SwiftData
import Darwin
import UniformTypeIdentifiers
import AVFAudio
import OSLog

@main
struct WidgetApp: App {
  @Environment(\.openWindow) var openWindow
  @Environment(\.dismissWindow) var dismissWindow
  
  // MARK: - ModelContainer
  //  private var container: ModelContainer

  var container: ModelContainer = {
    console.log("Loading ModelContainer")
    let path  = FileManager.default.urls(for: .applicationSupportDirectory,
                                         in: .userDomainMask).first!
    
    let storePath = path.appendingPathComponent("widget.store")
    let modelConfiguration = ModelConfiguration(url: storePath)
    
    do {
      console.log("Loading ModelContainer from \(storePath)")
      return try ModelContainer(for: Widget.self, configurations: modelConfiguration)
    } catch {
      if SwiftDataError.loadIssueModelContainer == error as? SwiftDataError {
        console.error("Deleting old modelContainer due to \(error)")
        try? FileManager.default.removeItem(at: storePath)
      }
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()
  
   init() {
     
       
    do {
      let path = URL.applicationSupportDirectory
      console.log("Creating directories in \(path)")
      // Create thumbnails directory
      try FileManager.default.createDirectory(at: path
        .appendingPathComponent("thumbnails", isDirectory: true), withIntermediateDirectories: true)
      
      // Create downloads directory
      try FileManager.default.createDirectory(at: path
        .appendingPathComponent("downloads", isDirectory: true), withIntermediateDirectories: true)
      
      //      try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
      // try AVAudioSession.sharedInstance().setActive(true)
      
    } catch {
      fatalError("Could not create directories: \(error)")
    }
     
     
     
  }
  
  @MainActor func showWindowForURL(_ url: URL?) {
    guard let url = url else { return }
    do {
      let widget = Widget(url:url)
      container.mainContext.insert(widget)
      try container.mainContext.save()
      openWindow(id: "widget", value: widget.persistentModelID)
    } catch {
      print("Error opening url \(error)")
    }
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
          .onDrop(of: [.url], isTargeted: nil) { providers, point in
            for provider in providers {
              _ = provider.loadObject(ofClass: URL.self) { url,arg  in
                DispatchQueue.main.async { showWindowForURL(url) }
              }
            }
            return true
          }
      
      }
      
      .frame(idealWidth: 560, idealHeight: 680,
             alignment: .center)
      .fixedSize(horizontal: true, vertical:true)
      
    } defaultValue: { "main" }
      .modelContainer(container)
      .windowResizability(.contentSize)
      .defaultSize(width: 560, height: 680)
      .windowStyle(.plain)
    
    
    // MARK: - Widget Windows
    
    WindowGroup("Widget", id: "widget", for: PersistentIdentifier.self) { $id in
      ZStack {
        if let id = id, let widget = container.mainContext.model(for: id) as? Widget {
          WidgetView(widget:widget, app:self)
            .onAppear() { widget.lastOpened = .now }
        }
      }
      .onOpenURL { showWindowForURL($0) }
      .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { showWindowForURL($0.webpageURL) }
      .onContinueUserActivity(Activity.openWidget, perform: { activity in
        if let info = activity.userInfo,
           let data = info["modelId"] as? Data,
           let modelID = try? JSONDecoder().decode(PersistentIdentifier.self, from: data) {
          id = modelID
        }
      })
    }
    .handlesExternalEvents(matching: [Activity.openWidget])
    .modelContainer(container)
    .windowStyle(.plain)
    .windowResizability(.contentSize)
    .defaultSize(width: 320, height: 320)
    
    
    
    // MARK: - Settings Window
    // TODO: These don't work with dragging for some reason?
    
    WindowGroup("Settings", id: "widgetSettings", for: Foundation.Data.self) { $data in
      ZStack {
        if let data = data,
           let modelID = try? JSONDecoder().decode(PersistentIdentifier.self, from: data ),
           let widget = container.mainContext.model(for: modelID) as? Widget{
          WidgetSettingsView(widget:widget, callback: {
            dismissWindow(id: "widgetSettings")
          }).task{
            print("Open Settings for \(widget.name)")
          }
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
    .modelContainer(container)
    .windowStyle(.automatic)
    .windowResizability(.contentSize)
    .defaultSize(width: 640, height: 640)
    
    
    // MARK: Preview Window
//    WindowGroup("Preview", id: "preview", for: URL.self) { $url in
//      PreviewView(url:url)
//      .onContinueUserActivity(Activity.openPreview, perform: { activity in
//        if let info = activity.userInfo,
//           let modelData = info["url"] as? URL {
//          url = modelData
//        }
//      })
//    }
//    .handlesExternalEvents(matching: [Activity.openPreview])
//    .windowStyle(.volumetric)
    
    
    
    // MARK: /Body
  }
}
