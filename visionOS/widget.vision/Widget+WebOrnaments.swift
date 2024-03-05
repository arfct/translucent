import Foundation
import SwiftUI
import SwiftData
import JavaScriptCore
import OSLog


struct Config: Decodable {
  var tabs: [TabItem]?
  var tools: [ToolbarItem]?
  var settings: [SettingsItem]?
}

struct TabItem: Decodable {
    var label: String
    var image: String
    var url: String
}

struct ToolbarItem: Decodable {
  var label: String?
  var image: String?
  var url: String
  var style: String?
}

struct SettingsItem: Decodable {
  var label: String
  var key: String?
  var type: String?
  var value: String?
}

extension Widget {
  @Transient
  var config: Config? {
    if let json = configJSON?.data(using: .utf8) {
      do {
        return try JSONDecoder().decode(Config.self, from: json)
      } catch {
        console.log("Tabs parsing error\(error)")
      }
    }
    return nil
  }
  @Transient
  var tabs: [TabItem]? {
    return config?.tabs;
  }
  
  @Transient
  var tools: [ToolbarItem]? {
    return config?.tools
  }
  
  @Transient
  var settings: [SettingsItem]? {
    return config?.settings
  }
}
