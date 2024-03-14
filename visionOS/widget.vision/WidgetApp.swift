import SwiftUI
import SwiftData
import Darwin
import UniformTypeIdentifiers
import AVFAudio
import OSLog

struct Activity {
  static let openWidget = "vision.widget.open"
  static let openSettings = "vision.widget.settings"
  static let openPreview = "vision.widget.preview"
  static let openWebView = "vision.widget.webview"
}

struct WindowTypeID {
  static let main = "main"
  static let widget = "widget"
  static let widgetSettings = "widgetSettings"
  static let webview = "webview"
  
}


@main
struct WidgetApp: App {
  @Environment(\.openWindow) var openWindow
  @Environment(\.dismissWindow) var dismissWindow
  
  // MARK: - ModelContainer
  //  private var container: ModelContainer
  static var modelContext: ModelContext?
  
  var container: ModelContainer = {
    console.log("Loading ModelContainer")
    let path  = FileManager.default.urls(for: .applicationSupportDirectory,
                                         in: .userDomainMask).first!
    
    let storePath = path.appendingPathComponent("widget.store")
    let modelConfiguration = ModelConfiguration(url: storePath)
    
    do {
      let container = try ModelContainer(for: Widget.self, configurations: modelConfiguration)
      return container;
    } catch {
//      if SwiftDataError.loadIssueModelContainer == error as? SwiftDataError {
      console.error("Deleting old modelContainer due to \(error)")
      try? FileManager.default.removeItem(at: storePath)
    
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
      
      WidgetApp.modelContext = container.mainContext

      // Create downloads directory
      try FileManager.default.createDirectory(at: path
        .appendingPathComponent("downloads", isDirectory: true), withIntermediateDirectories: true)
      
      // try AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
      // try AVAudioSession.sharedInstance().setIntendedSpatialExperience(.fixed(soundStageSize: .automatic))
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
      console.log("Error opening url \(error)")
    }
  }
  @State var launchComplete = true;
  var body: some Scene {
    
    // MARK: Main Window
    
    WindowGroup("Main", id: WindowTypeID.main) { // value in // removed because it causes a crash in window restoration by reading PersistentIDs as strings
      if (!launchComplete) {
        LaunchView(completed: $launchComplete)
      } else {
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
          .frame(idealWidth: 600, idealHeight: 800, alignment: .center)
          .fixedSize(horizontal: true, vertical:true)
      }
    }
    .windowStyle(.plain)
    .modelContainer(container)
    .windowResizability(.contentSize)
    .defaultSize(width: 600, height: 800)
    
    
    // MARK: Widget Windows
    
    WindowGroup("Widget", id: WindowTypeID.widget, for: PersistentIdentifier.self) { $id in
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
    
    
    
    // MARK: Widget Settings Windows
    // TODO: These don't work with dragging for some reason?
    
    WindowGroup("Settings", id: WindowTypeID.widgetSettings, for: Foundation.Data.self) { $data in
      ZStack {
        if let data = data,
           let modelID = try? JSONDecoder().decode(PersistentIdentifier.self, from: data ),
           let widget = container.mainContext.model(for: modelID) as? Widget{
          WidgetSettingsView(widget:widget, callback: {
            dismissWindow(id: "widgetSettings")
          })
        }
      }
      .onContinueUserActivity(Activity.openSettings, perform: { activity in
        if let info = activity.userInfo,
           let modelData = info["modelId"] as? Data {
          data = modelData
        }
      })
    }
    .windowResizability(.contentMinSize)
    .handlesExternalEvents(matching: ["settings"])
    .modelContainer(container)
    .windowStyle(.automatic)
    .defaultSize(width: 512, height: 512)
    
    // MARK: Widget Windows
    
    WindowGroup("WebView", id:WindowTypeID.webview, for: URL.self) { $url in
      if let url = url {
        let widget = Widget(url:url, overrides: WebView.newWebViewOverride)
        WidgetView(widget:widget, app:self)
          .onOpenURL { showWindowForURL($0) }
          .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { showWindowForURL($0.webpageURL) }
      }
    }
    .handlesExternalEvents(matching: [Activity.openWebView])
    .modelContainer(container)
    .windowStyle(.plain)
    .windowResizability(.contentSize)
    
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
    
    
  }
}
