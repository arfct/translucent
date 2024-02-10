import Foundation
import SwiftUI
import SwiftData


@Model final class Widget {
  var id: UUID
  var name: String?
  var image: String?
  var location: String?
  var style: ViewStyle
  var color: String = "transparent"
  
  var width: CGFloat = 360
  var height: CGFloat = 360
  var radius: CGFloat = 30
  var zoom: CGFloat = 1.0
  var viewportWidth: Int?
  var isLoading: Bool = false
  var lastOpened: Date?
  var options: String = ""
    

  init(id: UUID = UUID(), name: String, image:String? = nil, location: String, style: ViewStyle, width: CGFloat? = nil, height: CGFloat? = nil, zoom: CGFloat? = nil, options: String? = nil) {
    self.id = id
    self.name = name
    
    if let image = image { self.image = image }
    self.location = location
    self.style = style
    if let width = width {self.width = width }
    if let height = height {self.height = height }
    
    if let options = options {
      options.split(separator: ",").forEach({ param in
        let kv = param.split(separator:"=")
        if let key = kv.first, let value = kv.last {
          switch key {
          case "bg":
            self.color = String(value)
          case "wh":
            let dims = value.split(separator: "x")
            if let width = dims.first.map(String.init), let widthDouble = Double(width) {
              self.width = CGFloat(widthDouble)
            }
            if let height = dims.last.map(String.init), let heightDouble = Double(height) {
              self.height = CGFloat(heightDouble)
            }
          case "zoom":
            if let value = Double(value) {
              self.zoom = value
              print("ZOOM \(value)")
            }
          case "vw":
            if let value = Int(value) {
              self.viewportWidth = value
              print("VW \(value)")
            }
          default:
            break
          }
          print("\(key) = \(value)")
        }
      })
      //      {
      //
      //        let dims = //
      //
      //
      //      }
      if options.contains("transparent") {
        self.style = .transparent;
      }
    }
    if let zoom = zoom { self.zoom = zoom }
    if let options = options { self.options = options }
  }
  
}
 
extension Widget {
    @Transient
    var bgColor: Color {
      return Color.red
    }
    
  @Transient
  var displayName: String {
      name ?? "Untitled"
  }
  @Transient
  var hostName: String? {
    URLComponents(string: location!)?.host
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
