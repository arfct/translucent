//
//  WidgetViewModel.swift
//  ittybittywidgets
//
//  Created by Nicholas Jitkoff on 1/29/24.
//

import Foundation
class WidgetViewModel {
  static var stub = [
    WidgetModel(id: UUID(), name:"Example.com", location: "https://example.com/", style: .glass_forced),
    WidgetModel(id: UUID(), name:"Size Test", location:
                  Bundle.main.url(
                    forResource: "index",
                    withExtension: "html",
                    subdirectory: "html")!.absoluteString
                , style: .glass),
//    WidgetModel(id: UUID(), name:"Calculator",
//                
//                location:
//                  Bundle.main.url(
//                    forResource: "Calculator",
//                    withExtension: "html",
//                    subdirectory: "html/Calculator.wdgt")!.absoluteString,
//                style: .transparent,
//                width:172,
//                height:248,
//                zoom:2.0
//               ),
    
    
    WidgetModel(id: UUID(), name:"Google News", location: "https://news.google.com/", style: .opaque),
    WidgetModel(id: UUID(), name:"Figma", location: "https://www.figma.com/proto/jTbGiGtJqLxweiB50yNqqp/Untitled?page-id=0%3A1&type=design&node-id=1-2&t=B4Vmz3349d97PQ11-0&scaling=contain&starting-point-node-id=1%3A2", style: .glass_forced),
  ]
  var widgetModels: [WidgetModel] = stub
  
  subscript(widgetId id: WidgetModel.ID) -> WidgetModel? {
    widgetModels.first(where: {$0.id == id})
  }
}
