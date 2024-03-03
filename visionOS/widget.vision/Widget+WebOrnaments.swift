import Foundation
import SwiftUI
import SwiftData
import JavaScriptCore

struct TabInfo: Decodable {
  var tabs: [TabItem]
}

struct TabItem: Decodable {
    var label: String
    var image: String
    var url: String
}

struct ToolbarInfo: Decodable {
  var tools: [ToolbarItem]
}

struct ToolbarItem: Decodable {
  var label: String?
  var image: String?
  var url: String
  var style: String?
}


extension Widget {
  @Transient
  var tabs: [TabItem]? {
    if let json = tabsJSON?.data(using: .utf8) {
      do {
        let tabInfo: TabInfo = try JSONDecoder().decode(TabInfo.self, from: json)
        return tabInfo.tabs
      } catch {
        print(error)
        
        print(tabsJSON ?? "")
      }
    }
    return nil
  }
  
  @Transient
  var toolbar: ToolbarInfo? {
    if let json = toolsJSON?.data(using: .utf8) {
      do {
        let toolbarInfo: ToolbarInfo = try JSONDecoder().decode(ToolbarInfo.self, from: json)
        return toolbarInfo
      } catch {
        print(error)
        print(toolsJSON ?? "")
      }
    }
    return nil
  }
}
