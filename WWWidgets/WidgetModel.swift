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
  case glass_forced  = "Glass (no body background)"
  case transparent  = "Transparent"
  case opaque  = "Opaque"

  var localizedName: LocalizedStringKey { LocalizedStringKey(rawValue) }
}

struct WidgetModel: Identifiable, Codable, Hashable {
  var id: UUID
  var name: String
  var location: String
  var style: ViewStyle
  var width: CGFloat?
  var height: CGFloat?
  var zoom: CGFloat = 1.0
  var flags: String = ""
  init(id: UUID = UUID(), name: String, location: String, style: ViewStyle, width: CGFloat? = nil, height: CGFloat? = nil, zoom: CGFloat? = nil, flags: String? = nil) {
    self.id = id
    self.name = name
    self.location = location
    self.style = style
    self.width = width
    self.height = height
    if let zoom = zoom { self.zoom = zoom }
    if let flags = flags { self.flags = flags }
  }
  
}


