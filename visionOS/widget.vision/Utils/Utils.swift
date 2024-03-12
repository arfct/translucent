import OSLog

extension Logger {
    /// Using your bundle identifier is a great way to ensure a unique identifier.
    private static var subsystem = Bundle.main.bundleIdentifier!

    /// Logs the view cycles like a view that appeared.
  static let console = Logger(subsystem: subsystem, category: "console")
}

var console = Logger.console

import SwiftUI
extension Bool: Comparable {
    public static func <(lhs: Self, rhs: Self) -> Bool {
        // the only true inequality is false < true
        !lhs && rhs
    }
}


extension UIApplication {
    var keyWindow: UIWindow? {
        // Get connected scenes
        return self.connectedScenes
            // Keep only active scenes, onscreen and visible to the user
            .filter { $0.activationState == .foregroundActive }
            // Keep only the first `UIWindowScene`
            .first(where: { $0 is UIWindowScene })
            // Get its associated windows
            .flatMap({ $0 as? UIWindowScene })?.windows
            // Finally, keep only the key window
            .first(where: \.isKeyWindow)
    }
    
}

func sizeFor(dimensions: String) -> CGSize {
  let dims = dimensions.split(separator: "x")
  var size = CGSize()
  if let width = dims.first.map(String.init), let widthDouble = Double(width) {
    size.width = CGFloat(widthDouble)
  }
  if let height = dims.last.map(String.init), let heightDouble = Double(height) {
    size.height = CGFloat(heightDouble)
  }
  return size;
}

func clean(url: String) -> String? {
  if (url.hasPrefix("http") || url.hasPrefix("file://")) {
    return url
  } else {
    if (url.contains(".") && !url.contains(" ")) {
      return "https://\(url)"
    }
  }
  return nil
}

extension URL {
  
}
