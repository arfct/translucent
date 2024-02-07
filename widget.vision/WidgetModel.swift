//
//  WidgetModel.swift
//  ittybittywidgets
//
//  Created by Nicholas Jitkoff on 1/29/24.
//

import Foundation
import SwiftUI



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

struct WidgetModel: Identifiable, Codable, Hashable {
  var id: UUID
  var name: String
  var image: String?
  var location: String
  var style: ViewStyle
  var color: String = "transparent"
  var width: CGFloat = 360
  var height: CGFloat = 360
  var radius: CGFloat = 30
  var zoom: CGFloat = 1.0
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
            print("\(self.width)x\(self.height)")
          case "zoom":
            if let value = Double(value) {
              self.zoom = value
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
    print("\(self.width)x\(self.height)")
    if let zoom = zoom { self.zoom = zoom }
    if let options = options { self.options = options }
  }
  
}


