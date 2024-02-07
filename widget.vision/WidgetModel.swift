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
  var width: CGFloat?
  var height: CGFloat?
  var zoom: CGFloat = 1.0
  var flags: String = ""
  init(id: UUID = UUID(), name: String, image:String? = nil, location: String, style: ViewStyle, width: CGFloat? = nil, height: CGFloat? = nil, zoom: CGFloat? = nil, flags: String? = nil) {
    self.id = id
    self.name = name
    
    if let image = image { self.image = image }
    self.location = location
    self.style = style
    self.width = width
    self.height = height
    if let zoom = zoom { self.zoom = zoom }
    if let flags = flags { self.flags = flags }
  }
  
}


