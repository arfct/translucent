import SwiftUI

struct SearchBar: View {
  @Binding var text: String
  @Binding var placeholder: String
  var onSubmit: (Bool) -> Void
  
  var body: some View {
    _SearchBar(text: $text, placeholder:$placeholder ,onSubmit: onSubmit)
      .padding(.horizontal, -24)
      .padding(.vertical, -24)
  }
}

struct _SearchBar: UIViewRepresentable {
  @Binding var text: String
  @Binding var placeholder: String
  var onSubmit: (Bool) -> Void
  
  func makeUIView(context: Context) -> UISearchBar {
    let searchBar = CircularSearchBar()
    searchBar.delegate = context.coordinator
    searchBar.searchBarStyle = .minimal
    searchBar.keyboardType = .webSearch
    searchBar.autocorrectionType = .no
    searchBar.autocapitalizationType = .none
    // These calls do not work, but should...
    // searchBar.setShowsCancelButton(false, animated: false)
    // searchBar.showsCancelButton = false
    return searchBar
  }
  
  func updateUIView(_ uiView: UISearchBar, context: Context) {
    uiView.text = text
    uiView.placeholder = placeholder
  }
  static func dismantleUIView(_ searchBar: UISearchBar, coordinator: SearchBarCoordinator) {
    searchBar.delegate = nil
  }

  func makeCoordinator() -> SearchBarCoordinator { SearchBarCoordinator(self) }
}

class SearchBarCoordinator: NSObject, UISearchBarDelegate {
  var parent: _SearchBar
  
  init(_ searchBar: _SearchBar) {
    self.parent = searchBar
  }
  
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    parent.text = searchText
  }
  
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    parent.onSubmit(true)
    searchBar.resignFirstResponder()
  }

}

class CircularSearchBar: UISearchBar {
  private var didObserveSubviews = false
  private let desiredCornerRadius = 22.0
  private var observedLayers = [CALayer]()
  
  override func willMove(toWindow newWindow: UIWindow?) {
    super.willMove(toWindow: newWindow)
    
    guard !didObserveSubviews else { return }
    observeSubviews(self)
    didObserveSubviews = true
  }
  
  override func removeFromSuperview() {
    removeObserveSubviews(self)
    super.removeFromSuperview()
  }
  
  override func layoutSubviews() {
    
    // Manually manage clear button since .setShowsCancelButton does not work
    for textField in findViews(subclassOf: UITextField.self) {
      textField.clearButtonMode = .never
    }
    
    super.layoutSubviews()
  }
  
  func observeSubviews(_ view: UIView) {
    for view in self.recursiveSubviews {
      view.layer.addObserver(self, forKeyPath: "cornerRadius", options: [.new], context: nil)
      observedLayers.append(view.layer)
    }
  }
  
  func removeObserveSubviews(_ view: UIView) {
    for layer in observedLayers {
      layer.removeObserver(self, forKeyPath: "cornerRadius", context: nil)
    }
  }
  
  
  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    guard keyPath == "cornerRadius" else {
      super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
      return
    }
    
    guard let layer = object as? CALayer else { return }
    guard layer.cornerRadius != desiredCornerRadius else { return }
    
    layer.cornerRadius = desiredCornerRadius
  }
}

#Preview(windowStyle: .automatic,traits:.fixedLayout(width: 320, height: 320)) {
  VStack {
    
    SearchBar(text:.constant("Text"), placeholder:.constant("Search")) { ended in
      print("Change \(ended)")
    }
  }
} cameras: {
  PreviewCamera(from: .front, zoom:2, name: "Front")
}
