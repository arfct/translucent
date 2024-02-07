//
//  WidgetViewModel.swift
//  ittybittywidgets
//
//  Created by Nicholas Jitkoff on 1/29/24.
//

import Foundation
class WidgetViewModel {
  static var stub = [
    WidgetModel(id: UUID(), 
                name:"Dimensions",
                location: Bundle.main.url(
                  forResource: "index",
                  withExtension: "html",
                  subdirectory: "html")!.absoluteString,
                style: .glass),
    
    WidgetModel(id: UUID(), name:"Example.com", location: "https://example.com/", style: .glass, zoom:0.4),
    WidgetModel(id: UUID(), name:"Bitty Calc", location: "https://calculator.bitty.app/", style: .glass),
    WidgetModel(id: UUID(), name:"Google News", location: "https://news.google.com/", style: .opaque, zoom:0.75),
    WidgetModel(id: UUID(), name:"Figma Mirror", location: "https://staging.figma.com/proto/qDAryalY0STlk3S8WmdgNT/Figma-Widget?type=design&node-id=32-5&t=1UNLv06qbZtavp5W-0&scaling=contain&page-id=0%3A1&starting-point-node-id=32%3A3&commit-sha=2b7b5c1ef150b7657fcd7dca00c66ef349152ed9", style: .transparent),
  ]
  
  var widgetModels: [WidgetModel] = stub
  subscript(widgetId id: WidgetModel.ID) -> WidgetModel? {
    widgetModels.first(where: {$0.id == id})
  }
}
