import SwiftUI


class WidgetStore: ObservableObject {
    @Published var widgets: [WidgetModel] = []


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
                return []
            }
            let dailyWidgets = try JSONDecoder().decode([WidgetModel].self, from: data)
            return dailyWidgets
        }
        let widgets = try await task.value
        self.widgets = widgets
    }


    func save(widgets: [WidgetModel]) async throws {
        let task = Task {
            let data = try JSONEncoder().encode(widgets)
            let outfile = try Self.fileURL()
            try data.write(to: outfile)
        }
        _ = try await task.value
    }
}
