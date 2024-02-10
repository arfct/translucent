import SwiftUI


class WidgetStore: ObservableObject {
  @Published var widgets: [WidgetModel] = []
  
  static var stub = [
    WidgetModel(id: UUID(),
                name:"Dimensions",
                image:"arrow.up.and.down.and.arrow.left.and.right",
                location: Bundle.main.url(
                  forResource: "index",
                  withExtension: "html",
                  subdirectory: "html")!.absoluteString,
                style: .glass),
    
    WidgetModel(id: UUID(), name:"Bitty Calc", image:"number.square", location: "https://calculator.bitty.app/", style: .glass),
    WidgetModel(id: UUID(), name:"AI Haiku", image:"text.alignleft", location: "https://eink.page/haiku.html", style: .transparent, width: 480, height:300),
    WidgetModel(id: UUID(), name:"Google News", image:"newspaper", location: "https://news.google.com/", style: .opaque, width:800, height:400, zoom:0.75),
    
    WidgetModel(id: UUID(), name:"Figma Mirror", image:"pencil.circle", location: "https://staging.figma.com/proto/qDAryalY0STlk3S8WmdgNT/Figma-Widget?type=design&node-id=32-5&t=1UNLv06qbZtavp5W-0&scaling=contain&page-id=0%3A1&starting-point-node-id=32%3A3&commit-sha=2b7b5c1ef150b7657fcd7dca00c66ef349152ed9", style: .transparent),
  ]
  
  private static func fileURL() throws -> URL {
    try FileManager.default.url(for: .documentDirectory,
                                in: .userDomainMask,
                                appropriateFor: nil,
                                create: false)
    .appendingPathComponent("widgets.data")
  }
  
  
  func load() async throws {
    let task = Task<[WidgetModel], Error> {
      let fileURL = try Self.fileURL()
  
      guard let data = try? Data(contentsOf: fileURL) else {
        print("Using Stub Data")
        
        try await save(widgets: WidgetStore.stub)
        return WidgetStore.stub
      }

      let dailyWidgets = try JSONDecoder().decode([WidgetModel].self, from: data)
      print("Loaded \(dailyWidgets.count) Widgets")
      return dailyWidgets
    }
    let widgets = try await task.value
    self.widgets = widgets
  }
  
  
  func save(widgets: [WidgetModel]?) async throws {
    print("Saving \(widgets?.count) Widgets")
    let task = Task {
      let data = try JSONEncoder().encode(widgets)
      let outfile = try Self.fileURL()
      try data.write(to: outfile)
    }
    _ = try await task.value
  }
  
  subscript(widgetId id: WidgetModel.ID) -> WidgetModel? {
    widgets.first(where: {$0.id == id})
  }
}
