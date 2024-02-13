import Foundation
import SwiftUI
import SwiftData



@Model final class Widget {
  var id: UUID
  var name: String = ""
  var title: String?
  var image: String?
  var location: String?
  var originalLocation: String?
  var style: ViewStyle
  var backHex: String = "0000"
  var foreHex: String = "ffff"
  var tintHex: String = "8Aff"
  var fontName: String = ""
  var width: CGFloat = 360
  var height: CGFloat = 360
  var minWidth: CGFloat = CGFloat.zero
  var minHeight: CGFloat = CGFloat.zero
  var maxWidth: CGFloat = CGFloat.infinity
  var maxHeight: CGFloat = CGFloat.infinity
  var radius: CGFloat = 30
  var zoom: CGFloat = 1.0
  var viewportWidth: Int?
  var isLoading: Bool = false
  var lastOpened: Date?
  var options: String = ""
  var userAgent: String = "mobile"
  var icon: String = "square.on.square"
  var clearClasses: String?
  var removeClasses: String?

  
  func sizeFor(dimensions: String) -> CGSize {
    let dims = dimensions.split(separator: "x")
    var size = CGSize()
    if let width = dims.first.map(String.init), let widthDouble = Double(width) {
      size.width = CGFloat(widthDouble)
    }
    if let height = dims.last.map(String.init), let heightDouble = Double(height) {
      size.height = CGFloat(heightDouble)
    }
    print("size \(size)")
    return size;
  }
  
  convenience init(url: URL) {
    print("🌐 Opening URL: \(url.absoluteString)")
    var location = url.absoluteString
    var parameters: String?
    if let regex = try? Regex(#"(?:%23|#)wv\?(.*)"#) {
      
      if let match = location.firstMatch(of: regex) {
      
        parameters = String(match[1].substring!)
        location = location.replacing(regex, with: "")
      }
    }
    
    location = location.replacingOccurrences(of: "widget-http", with: "http")
    location = location.replacingOccurrences(of: "https://widget.vision/http", with: "http")
    
    print("LOCATION \(location) PARAM \(parameters) ")
    
    self.init( name:url.host() ?? "NAME", location: location, options:parameters)
  }
  
  init(id: UUID = UUID(), name: String, image:String? = nil, location: String, style: ViewStyle = .glass, width: CGFloat? = nil, height: CGFloat? = nil, zoom: CGFloat? = nil, options: String? = nil) {
    self.id = id
    self.name = name
    if let image = image { self.image = image }
    self.location = location
    self.originalLocation = location
    self.style = style
    if let width = width {self.width = width }
    if let height = height {self.height = height }
    
    if let options = options {
      if options.contains("transparent") {
        self.style = .transparent;
      }
      options.split(separator: "&").forEach({ param in
        let kv = param.split(separator:"=")
        if let key = kv.first?.removingPercentEncoding, let value = kv.last?.removingPercentEncoding {
          switch key {
          case "style":
            if (value == "transparent") { self.style = .transparent}
          case "bg":
            self.backHex = String(value)
          case "fg":
            self.foreHex = String(value)
          case "tg", "tint":
            self.tintHex = String(value)
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
            if let value = Double(value) {
              self.userAgent = String(value)
            }
          case "vw":
            if let value = Int(value) {
              self.viewportWidth = value
            }
          case "ua", "agent":
            if let value = Double(value) {
              self.userAgent = String(value)
            }
          case "remove":
            self.removeClasses = String(value)
          case "clear":
            self.clearClasses = String(value)
          case "icon":
            self.icon = String(value)
          case "name":
            self.name = String(value)
          default:
            break
          }
          print("\(key) = \(value)")
        }
      })


    }
    if let zoom = zoom { self.zoom = zoom }
  }
  
}
 
extension Widget {
  @Transient
  var backColor: Color { Color.withHex(backHex) }
  
  @Transient
  var foreColor: Color { Color.withHex(foreHex) }
  
  @Transient
  var tintColor: Color { Color.withHex(tintHex) }
  
  @Transient
  var displayName: String {
    if name.count > 0 {
      return name;
    }
    
    return title ?? hostName ?? "Untitled";
  }
  
  @Transient
  var hostName: String? {
    URLComponents(string: location!)?.host
  }
  
  @Transient
  var shareURL: String {
    if (originalLocation != nil) {
      return originalLocation!
    }
    let encodedURL = location?.replacingOccurrences(of: "https://", with: "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    let urlString = "https://widget.vision/\(encodedURL)"
    return urlString
  }
    
  @Transient
  var description: String {
    return "Widget \(id) - \(location ?? "")"
  }
    
    
    static var preview: Widget {
      Widget(name: "Test", location: "https://example.com", style: .glass, options: "bg=0000&fg=ffff&tg=8aff&sz=360x360&zoom=1.0&icon=graduationcap")
    }
}

private extension Color {
    static var random: Color {
        var generator: RandomNumberGenerator = SystemRandomNumberGenerator()
        return random(using: &generator)
    }
    
    static func random(using generator: inout RandomNumberGenerator) -> Color {
        let red = Double.random(in: 0..<1, using: &generator)
        let green = Double.random(in: 0..<1, using: &generator)
        let blue = Double.random(in: 0..<1, using: &generator)
        return Color(red: red, green: green, blue: blue)
    }
}

enum ViewStyle: String, Equatable, CaseIterable, Codable {
  case glass = "Glass"
  case transparent  = "Transparent"
  //  case glass_forced  = "Glass (no body background)"
//  case opaque  = "Opaque"
  
  var localizedName: LocalizedStringKey { LocalizedStringKey(rawValue) }
  var iconName: String {
    switch self {
    case .transparent: return "square.on.square.intersection.dashed"
    case .glass: return "square.on.square"
      //    case .glass_forced: return "square.on.square"
//    case .opaque: return "square.filled.on.square"
    }
  }
}
