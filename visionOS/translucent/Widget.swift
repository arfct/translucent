import Foundation
import GroupActivities
import SwiftUI
import SwiftData

import RealityKit
import RealityKitContent

struct Host {
  static let site = "translucent.site"
  static let directory = "translucent.directory"
  static let widget = "widget.vision"
  static let wwwidget = "www.widget.vision"
}

enum WindowStyle:String {
  case transparent, glass, opaque
}

enum ControlStyle:String {
  case hide, show, suppress, toolbar
}

enum IconStyle:String {
  case fetch, download, thumbnail // , http…, [symbol]
}

@Model final class Widget: Transferable, Codable, ObservableObject {
  
  static var modelContext: ModelContext?
  // MARK: Core Properties
  
  var id: UUID = UUID()
  var wid: String = ""
  var name: String = ""
  var title: String?
  var type: String?
  var symbol: String?
  var icon: String?
  var location: String?
  var manifest: String? // source url or directory id for manifest information
  var lastOpened: Date?
  var favorite: Bool = false
  
  // MARK: Window Properties
  var style: String = WindowStyle.glass.rawValue
  var controls: String?
  var radius: CGFloat = 30
  
  var width: CGFloat = 720
  var height: CGFloat = 720
  var minWidth: CGFloat = 320
  var minHeight: CGFloat = 180
  var maxWidth: CGFloat = CGFloat.infinity
  var maxHeight: CGFloat = CGFloat.infinity

  
  var blending: String?
  var effect: String? // dim
  var resize: String? // nil [freeform], uniform, none, (fitwidth)
  var tilt: CGFloat?
  
  // MARK: Theme Properties
  var backHex: String?
  var foreHex: String?
  var tintHex: String?
  var fontName: String?
  var fontWeight: String?
  
  // MARK: Web Properties
  var zoom: CGFloat = 1.0
  var viewport: String?
  var userAgent: String = "mobile"
  
  // MARK: Web Overrides
  var enableOverrides = true
  var clearSelectors: String?
  var removeSelectors: String?
  var injectCSS: String?
  var injectJS: String?

  var configJSON: String?
  
  // MARK: Spatial Anchoring
  var anchorPoint: String?
  var anchorTransform: String?
  
  @Transient
  var isSpatial: Bool {
    return true
  }
  
  @Transient
  var anchor: AnchoringComponent.Target {
    return .head
//    return .hand(.left, location: .indexFingerTip)
  }
  
  @Transient
  var transform: Transform {
    return Transform.init(translation:.init(x: 0, y: 1, z: -3.3))
  }
  
  @Transient
  var parseError: String?
  
  // MARK: Transient Properties
  @Transient var originalLocation: String?
  @Transient var isLoading: Bool = false
  @Transient var isTemporaryWidget: Bool = false
  
  
  static func find(id: String?) -> Widget? {
    if let wid = id {
      let fetchDescriptor = FetchDescriptor<Widget>(
        predicate: #Predicate<Widget> { $0.wid == wid })
      return try? modelContext?.fetch(fetchDescriptor).first
    }
    return nil
  }
  static func find(location: String?) -> Widget? {
    if let location = location {
      let fetchDescriptor = FetchDescriptor<Widget>(
        predicate: #Predicate<Widget> { $0.location == location })
      return try? modelContext?.fetch(fetchDescriptor).first
    }
    return nil
  }
  
  static func findOrCreate(location: String?) -> Widget? {
    guard let location = location,
          let url = URL(string:location)
          else {return nil}

    let widget = Widget(url:url)
    
    if let match =  Widget.find(location: widget.location) {
      return match
    }
        
    persist(widget: widget)
    
    return widget
  }
  

  
  // MARK: Model Functions

  static func persist(widget: Widget) {
    widget.isTemporaryWidget = false
    modelContext?.insert(widget)
    try? modelContext?.save()
  }
  
  
  @MainActor
  func save() {
    do {
      try modelContext?.save()
    } catch {
      console.log("Could not save ModelContainer: \(error)")
    }
  }
  
  @MainActor
  func delete() {
    modelContext?.delete(self)
    try? modelContext?.save()
  }
  
  static var transferRepresentation: some TransferRepresentation {
    ProxyRepresentation(exporting: \.safeShareURL)
    GroupActivityTransferRepresentation { widget in
        WidgetActivity(widget: widget)
    }
  }
  
  
  

  private enum CodingKeys : String, CodingKey {
      case location
  }
  
  func encode(to encoder: Encoder) throws {
    
      print("encoding from", encoder)
      var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(shareURL?.absoluteString, forKey: .location)
  }
  
  // MARK: init()
  required init(from decoder: Decoder) throws {
    print("decoding from", decoder)
    let container = try decoder.container(keyedBy: CodingKeys.self)
    if let location = try container.decodeIfPresent(String.self, forKey: .location),
       let url = URL(string:location) {
      
      let (location, parameters) = locationAndParams(url: url)
      self.location = location
      self.originalLocation = location
      apply(options: parameters)
    }
  }
  
  
  convenience init(url: URL, name: String? = nil, overrides: WebViewSetup? = nil, isTemporary: Bool = false) {
    
    let (location, parameters) = locationAndParams(url: url)
    self.init( name: name ?? url.host() ??
               url.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "_", with: " "),
               location: location,
               options:parameters)
    
    isTemporaryWidget = isTemporary
    if let overrides = overrides {
      if let w = overrides.windowFeatures.width?.floatValue {  width = CGFloat(w) }
      if let h = overrides.windowFeatures.height?.floatValue {  height = CGFloat(h) }
      isTemporaryWidget = true;
    }
    
    if (url.pathExtension == "usdz") {
      type = "usdz"
    }
  }
  
  init(wid: String = UUID().uuidString, name: String, location: String, options: String? = nil) {
    self.wid = wid
    self.name = name
    self.location = location
    self.originalLocation = location
    apply(options: options)
  }
  
  func apply(options: String?, fromSite: Bool? = false, origin: String? = nil) {

    let isTrusted = fromSite == true || origin == nil || origin == Host.wwwidget || origin == Host.site
    if let options = options {
      console.log("Applying options: \(options)")
      options.split(separator: "&").forEach({ param in
        let kv = param.split(separator:"=")
        if let key = kv.first?.removingPercentEncoding, let value = kv.last?.replacingOccurrences(of: "+", with: " ").removingPercentEncoding {
          switch key {
          case "manifest":
            self.manifest = String(value)
          case "url":
            self.location = String(value)
          case "style":
            self.style = String(value)
          case "name":
            self.name = String(value)
          case "bg", "back":
            self.backHex = String(value)
          case "fg", "fore":
            self.foreHex = String(value)
          case "tg", "tint":
            self.tintHex = String(value)
          case "effect":
            self.effect = String(value)
          case "resize":
            self.resize = String(value)
          case "ms", "sz", "size":
            let size = sizeFor(dimensions: String(value))
            self.width = size.width
            self.height = size.height
          case "minsize", "min":
            let size = sizeFor(dimensions: String(value))
            self.minWidth = size.width
            self.minHeight = size.height
          case "maxsize", "max":
            let size = sizeFor(dimensions: String(value))
            self.maxWidth = size.width
            self.maxHeight = size.height
          case "zm", "zoom":
            if let value = Double(value) {
              self.zoom = value
            }
          case "ua", "agent":
            self.userAgent = String(value)
          case "vw":
            self.viewport = String(value)
          case "remove":
            self.removeSelectors = String(value)
          case "clear":
            self.clearSelectors = String(value)
          case "radius":
            if let value = Double(value) {
              self.radius = value
            }
          case "controls":
            self.controls = String(value)
          case "js":
            if isTrusted { self.injectJS = String(value) }
          case "css":
            self.injectCSS = String(value)
          case "config":
            if isTrusted { self.configJSON = String(value) }
          case "icon":
            self.icon = String(value)
          case "symbol":
            self.symbol = String(value)
          default:
            break
          }
        }
      })
    }
  }
  
  func thumbnailChanged() {
    objectWillChange.send()
  }
  
  static var preview: Widget {
    Widget(name: "Test",
           location: "https://example.com",
           options: "bg=0000&fg=ffff&tg=8aff&sz=360x360&zoom=1.0&icon=download")
  }
}

// MARK: Transient Properties

extension Widget {
  
  @Transient
  var suppressFirstClick: Bool {
    controls == ControlStyle.suppress.rawValue
  }
  
  @Transient
  var autohideControls: Bool {
    controls == ControlStyle.hide.rawValue
    || controls == ControlStyle.suppress.rawValue
  }
  
  @Transient
  var shouldCacheThumbnail: Bool {
    return !shouldCacheIcon
    //    icon == nil || icon == IconStyle.thumbnail.rawValue
  }
  
  @Transient
  var shouldCacheIcon: Bool {
    icon == IconStyle.fetch.rawValue ||
    icon == IconStyle.download.rawValue
  }
  
  
  
  @Transient
  var backColor: Color? {
    if let hex = backHex { return Color.withHex(hex) }
    return nil
  }
  
  @Transient
  var foreColor: Color? {
    if let hex = foreHex { return Color.withHex(hex) }
    return nil
  }
  
  @Transient
  var tintColor: Color? {
    if let hex = tintHex { return Color.withHex(hex) }
    return nil
  }
  
  @Transient
  var displayName: String {
    if name.count > 0 {
      return name;
    }
    return title ?? hostName ?? "Untitled";
  }
  
  @Transient
  var hostName: String? {
    if let loc = location {
      return URLComponents(string: loc)?.host
    }
    return nil;
  }
  
  @Transient
  var modelID: Data {
    do {
      let mid = try JSONEncoder().encode(persistentModelID);
      return mid;
    } catch {
      fatalError("ID Encoding Error \(error) ")
    }
  }
  
  @Transient
  var showGlassBackground: Bool {
    return style.caseInsensitiveCompare("transparent") != .orderedSame
  }
  
  @Transient
  var showBrowserBar: Bool {
    return controls == ControlStyle.toolbar.rawValue
  }
  
  // MARK: Thumbnails
  
  @Transient
  var thumbnailUIImage: UIImage? {
    if let file = thumbnailFile, let image = UIImage(contentsOfFile: file.path) {
      return image;
    }
    return nil;
  }
  
  @Transient
  var thumbnailImage: Image? {
    if let img = thumbnailUIImage {
      return Image(uiImage: img)
    }
    return nil
  }
  
  @Transient
  var thumbnailFile: URL? {
    if let path = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
      let filename = path
        .appendingPathComponent("thumbnails", isDirectory: true)
        .appendingPathComponent(self.wid + ".png")
      return filename
    }
    return nil
  }
  
  @Transient
  var sizeString: String {
    return ("\(width)x\(height)")
  }
  
  // MARK: Share URL
  @Transient
  var safeShareURL:URL {
    return shareURL ?? URL(string:"about:blank")!
  }
  
  @Transient
  var shareURL: URL? {
    var items: [URLQueryItem] = []
    if (!self.showGlassBackground) {
      items.append(URLQueryItem(name: "style", value: "transparent"))
    }
    if name.count > 0  {
      items.append(URLQueryItem(name: "name", value: name))
    }
    if let value = manifest, value.count > 0  {
      items.append(URLQueryItem(name: "manifest", value: value))
    }
    
    if backHex != nil {
      items.append(URLQueryItem(name: "back", value: backHex))
    }
    if foreHex != nil {
      items.append(URLQueryItem(name: "fore", value: foreHex))
    }
    if tintHex != nil {
      items.append(URLQueryItem(name: "tint", value: tintHex))
    }
    if zoom != 1.0 {
      items.append(URLQueryItem(name: "zoom", value: String(describing:zoom)))
    }
    if radius != 30 {
      items.append(URLQueryItem(name: "radius", value: String(describing:radius)))
    }
    if let value = viewport {
      items.append(URLQueryItem(name: "vw", value: value))
    }
    if let value = controls, value.count > 0 {
      items.append(URLQueryItem(name: "controls", value: value))
    }
    if let string = injectJS, string.count > 0 {
      items.append(URLQueryItem(name: "js", value: string))
    }
    if let string = injectCSS, string.count > 0 {
      items.append(URLQueryItem(name: "css", value: string))
    }
    if (userAgent != "mobile") {
      items.append(URLQueryItem(name: "ua", value: userAgent))
    }
    if let string = removeSelectors, string.count > 0 {
      items.append(URLQueryItem(name: "remove", value: string))
    }
    if let string = clearSelectors, string.count > 0 {
      items.append(URLQueryItem(name: "clear", value: string))
    }
    if let string = configJSON, string.count > 0 {
      items.append(URLQueryItem(name: "config", value: string))
    }
    if let string = resize, string.count > 0 {
      items.append(URLQueryItem(name: "resize", value: string))
    }
    if let string = effect, string.count > 0 {
      items.append(URLQueryItem(name: "effect", value: string))
    }
    
    items.append(URLQueryItem(name: "size", value: sizeString))
    
    var components = URLComponents()
    components.queryItems = items;
    
    guard var suffix = components.string else { return nil }
    suffix.removeFirst()
    if (suffix.count > 0) { suffix = "?v=1&" + suffix}
    
    guard let encodedURL = location?.replacingOccurrences(of: "https://", with: "")
      .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else { return nil }
    
    let urlString = "https://\(Host.site)/\(String(describing: encodedURL))\(suffix)"
    
    return URL(string: urlString)!
  }
  
  @Transient
  var manifestURL: URL? {
    
    if let manifest = manifest {
      if manifest.starts(with: "https") {
        return URL(string: manifest)
      }
      return URL(string: "https://\(Host.directory)/links/\(manifest).html")
      
    } else if let hostName = hostName {
      return URL(string: "https://\(Host.directory)/links/\(hostName).html")
    }
    
    return nil;
  }
  
  @Transient
  var iconURL: URL? {
    if let manifest = manifest {
      if manifest.starts(with: "https"), let url = URL(string: manifest) {
        return url
      }
      return URL(string: "https://\(Host.directory)/links/\(manifest).png")
      
    } else if let hostName = hostName {
      return URL(string: "https://\(Host.directory)/links/\(hostName).png")
    }
    
    return nil;
  }
  
  @Transient
  var blendMode: BlendMode {
    return switch(blending) {
    case "screen": .screen
    case "multiply": .multiply
    case "plusLighter": .plusLighter
    case "plusDarker": .plusDarker
    case .none: .normal
    case .some(_): .normal
    }
  }
  
  func incrementRadius(_ direction: CGFloat) {
    let testRadius = radius + direction
    let step: CGFloat =
    testRadius > 200 ? 100 :
    testRadius > 50 ? 10 :
    testRadius > 10 ? 5 : 1
    
    let newRadius = max(0, radius + step * direction)
    radius = newRadius
  }
  
  func incrementZoom(_ direction: Int) {
    let zooms = [0.25, 0.333, 0.5, 0.667, 0.75, 0.875, 1.0, 1.125, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0, 4.0, 5.0]
    
//    let test = zoom + CGFloat(direction) * 0.01
    print("val \(zoom) \(zooms.firstIndex { zoom + 0.01 <= $0 })")
    var index = zooms.firstIndex { zoom <= $0 + 0.04 } ?? zooms.count - 1;
     
    index = max(0, min(zooms.count - 1, index + direction))
  
    zoom = zooms[index]
  }
  
  func updateFromManifest() {
    if let url = manifestURL {
      do {
        let contents = try String(contentsOf: url)
      
        if let regex = try? Regex(#"<meta name="widget" content="([^"]+)">"#) {
          if let match = contents.firstMatch(of: regex) {
            print("match", match)
            let parameters = String(match[1].substring!)
            console.log("Applying updated config: \(parameters)")
            apply(options: parameters, fromSite: false, origin: url.host)

            
          }
        }
      } catch {
        console.log("Failed to fetch config \(error)")
      }
    }
  }
  
  func fetchIcon() {
    if let url = iconURL {
      DispatchQueue.global().async {
        if let path = self.thumbnailFile, let data = try? Data(contentsOf: url) {
          DispatchQueue.main.async {
            print("data", data, path, url)
            try? data.write(to: path)
            self.thumbnailChanged()
          }

        }//make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
      }

    }
  }
  
  @Transient
  var description: String {
    return "Widget \(id) - \(location ?? "")"
  }
  
  @Transient
  var userAgentString: String {
    if (userAgent == "desktop") {
      return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.3.1 Safari/605.1.15"
    } else if (userAgent == "mobile" || userAgent.count == 0) {
      return "Mozilla/5.0 (iPhone; CPU iPhone OS 14_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.2 Mobile/15E148 Safari/604.1"
    } else {
      return userAgent;
    }
  }
  
}



func locationAndParams(url: URL) -> (String, String?){
  
  console.log("🌐 Creating from URL: \(url.absoluteString)")
  var location = url.absoluteString
  var parameters: String?
  if let regex = try? Regex(#"(?:\?)(.*v=\d.*)"#) {
    if let match = location.firstMatch(of: regex) {
      parameters = String(match[1].substring!)
      location = location.replacing(regex, with: "")
    }
  }
  
  if let decodedLocation = location.removingPercentEncoding {
    location = decodedLocation
  }
  
  if (location.hasPrefix("widget")) {
    location = location
      .replacingOccurrences(of: "widget-http", with: "http")
      .replacingOccurrences(of: "widget://", with: "https://")
  } else {
    location = location
      .replacingOccurrences(of: "https://widget.vision/http", with: "http")
      .replacingOccurrences(of: "https://www.widget.vision/http", with: "http")
      .replacingOccurrences(of: "https://widget.vision/", with: "https://")
      .replacingOccurrences(of: "https://translucent.site/http", with: "http")
      .replacingOccurrences(of: "https://translucent.vision/http", with: "http")
      .replacingOccurrences(of: "https://translucent.site/", with: "https://")
  }

  if (parameters == nil) {
    parameters = "style=opaque&size=720x720"
  }
  
  return (location, parameters)
}
