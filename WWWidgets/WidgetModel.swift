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
  case glass_forced  = "Glass (remove background)"
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
  var zoom: CGFloat?
  init(id: UUID = UUID(), name: String, location: String, style: ViewStyle, width: CGFloat? = nil, height: CGFloat? = nil, zoom: CGFloat? = nil) {
    self.id = id
    self.name = name
    self.location = location
    self.style = style
    self.width = width
    self.height = height
    self.zoom = zoom
  }
  
}


