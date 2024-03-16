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

struct WindowID {
  static let main = "main"
}

struct WindowTypeID {
  static let main = "default"
  static let widget = "default"
  static let widgetSettings = "default"
  static let webview = "default"
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
      console.error("Deleting old modelContainer due to \(error)")
      try? FileManager.default.removeItem(at: storePath)
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()
  
  init() {
    do {
      let fm = FileManager.default
      let path = URL.applicationSupportDirectory
      console.log("Creating directories in \(path)")

      // Create thumbnails directory
      try fm.createDirectory(at: path
        .appendingPathComponent("thumbnails", isDirectory: true), withIntermediateDirectories: true)
      
      // Create downloads directory
      try fm.createDirectory(at: path
        .appendingPathComponent("downloads", isDirectory: true), withIntermediateDirectories: true)
 
    } catch {
      fatalError("Could not create directories: \(error)")
    }
    
    Widget.modelContext = container.mainContext
    
  }
  
  @MainActor func showWindowForURL(_ url: URL?) {
    guard let url = url else { return }
    do {
      let widget = Widget(url:url)
      container.mainContext.insert(widget)
      try container.mainContext.save()
      openWindow(id: WindowTypeID.widget, value: widget.wid)
    } catch {
      console.log("Error opening url \(error)")
    }
  }

  @State var windowLoaded: Bool = false;
  
  var body: some Scene {
    
    // MARK: Generic Window
    
    WindowGroup("Main", id: WindowTypeID.main, for: String.self) { $windowID in
      
      let _ = console.log("🪟 Opening \(windowID)");
      Group { // All windows are clustered in this group due to a bug in relaunching any non-main window
        if windowID == WindowID.main {
          if (windowLoaded) {
            WidgetPickerView(app: self)
              .frame(idealWidth: 600, idealHeight: 800, alignment: .center)
              .fixedSize(horizontal: true, vertical:true)
          } else {
            ZStack() {
              
            }.onAppear() {
              print("loaded")
              windowLoaded = true
            }
          }
        }
        
        // Settings window
        else if windowID.starts(with:"settings:"), let widget = Widget.find(id:windowID.replacingOccurrences(of: "settings:", with: ""))  {
          let _ = print("window", widget)
          WidgetSettingsView(widget:widget)
        }
        
        // Widget window
        else if let widget = Widget.find(id:windowID) {
          WidgetView(widget:widget, app:self)
        }
        
        // WebView window
        else if let url = URL(string:windowID) {
          let widget = Widget(url:url, overrides: WebView.newWebViewOverride)
          WidgetView(widget:widget, app:self)
            .onOpenURL { showWindowForURL($0) }
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { showWindowForURL($0.webpageURL) }
        }
      }
      .onOpenURL { showWindowForURL($0) }
      .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { showWindowForURL($0.webpageURL) }
      .onContinueUserActivity(Activity.openWidget, perform: { activity in
        if let info = activity.userInfo, let id = info["wid"] as? String { windowID = id }
      })
      .onDrop(of: [.url], isTargeted: nil) { providers, point in
        for provider in providers { _ = provider.loadObject(ofClass: URL.self) { url,arg  in
          DispatchQueue.main.async { showWindowForURL(url) }
        }}
        return true
      }
      
      
    } defaultValue: {  WindowID.main }
      .windowStyle(.plain)
      .windowResizability(.contentSize)
      .handlesExternalEvents(matching: [Activity.openWidget])
      .modelContainer(container)
      .windowStyle(.plain)
      
      .defaultSize(width: 600, height: 800)
    
  }
}
