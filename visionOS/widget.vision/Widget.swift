import Foundation
import SwiftUI
import SwiftData


@Model final class Widget {
  var id: UUID
  var name: String?
  var image: String?
  var location: String?
  var style: ViewStyle
  var backHex: String = "0000"
  var foreHex: String = "ffff"
  var tintHex: String = "8Aff"
  var fontName: String = ""
  var width: CGFloat = 360
  var height: CGFloat = 360
  var radius: CGFloat = 30
  var zoom: CGFloat = 1.0
  var viewportWidth: Int?
  var isLoading: Bool = false
  var lastOpened: Date?
  var options: String = ""
  var userAgent: String = "mobile"
    

  init(id: UUID = UUID(), name: String, image:String? = nil, location: String, style: ViewStyle, width: CGFloat? = nil, height: CGFloat? = nil, zoom: CGFloat? = nil, options: String? = nil) {
    self.id = id
    self.name = name
    if let image = image { self.image = image }
    self.location = location
    self.style = style
    if let width = width {self.width = width }
    if let height = height {self.height = height }
    
    if let options = options {
      if options.contains("transparent") {
        self.style = .transparent;
      }
      options.split(separator: "&").forEach({ param in
        let kv = param.split(separator:"=")
        if let key = kv.first, let value = kv.last {
          switch key {
          case "style":
            if (value == "transparent") { self.style = .transparent}
          case "bg":
            self.backHex = String(value)
          case "fg":
            self.foreHex = String(value)
          case "tg", "tint":
            self.tintHex = String(value)
          case "sz", "size":
            let dims = value.split(separator: "x")
            if let width = dims.first.map(String.init), let widthDouble = Double(width) {
              self.width = CGFloat(widthDouble)
            }
            if let height = dims.last.map(String.init), let heightDouble = Double(height) {
              self.height = CGFloat(heightDouble)
            }
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
      name ?? "Untitled"
  }
  @Transient
  var hostName: String? {
    URLComponents(string: location!)?.host
  }
  @Transient
  var shareURL: String {
    "https://example.com"
  }
    
  @Transient
  var description: String {
    return "Widget \(id) - \(location ?? "")"
  }
    
    
    static var preview: Widget {
      Widget(name: "Test", location: "https://example.com", style: .glass)
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
  case opaque  = "Opaque"
  
  var localizedName: LocalizedStringKey { LocalizedStringKey(rawValue) }
  var iconName: String {
    switch self {
    case .transparent: return "square.on.square.intersection.dashed"
    case .glass: return "square.on.square"
      //    case .glass_forced: return "square.on.square"
    case .opaque: return "square.filled.on.square"
    }
  }
}