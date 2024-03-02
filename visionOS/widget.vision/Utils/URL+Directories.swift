import SwiftUI

extension URL {
    static var documentsDirectory: URL? {
      return FileManager.default.urls(for: .documentDirectory,
                                                        in: .userDomainMask).first!
    }

    static func urlInDocumentsDirectory(with filename: String) -> URL? {
        return documentsDirectory?.appendingPathComponent(filename)
    }
  
  static var applicationSupportDirectory: URL {
      return FileManager.default.urls(for: .applicationSupportDirectory,
                                                        in: .userDomainMask).first!
  }

}
