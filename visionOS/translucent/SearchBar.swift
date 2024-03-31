import SwiftUI

struct SearchBar: UIViewRepresentable {
  @Binding var text: String
  @Binding var placeholder: String
  var onSearchButtonClicked: () -> Void
  
  func makeUIView(context: Context) -> UISearchBar {
    let searchBar = CircularSearchBar()
    searchBar.delegate = context.coordinator
    searchBar.searchBarStyle = .minimal
    searchBar.setShowsCancelButton(false, animated: true)
    return searchBar
  }
  
  func updateUIView(_ uiView: UISearchBar, context: Context) {
    uiView.text = text
    uiView.placeholder = placeholder
  }
  
  func makeCoordinator() -> SearchBarCoordinator { SearchBarCoordinator(self) }
}

class SearchBarCoordinator: NSObject, UISearchBarDelegate {
  var parent: SearchBar
  
  init(_ searchBar: SearchBar) {
    self.parent = searchBar
  }
  
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    parent.text = searchText
  }
  
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    parent.onSearchButtonClicked()
    searchBar.resignFirstResponder()
  }
}

#Preview {
  SearchBar(text:.constant(""), placeholder:.constant("search"), onSearchButtonClicked: {
    print("User hit return")
  })
}

class CircularSearchBar: UISearchBar {
  private var didObserveSubviews = false
  private let desiredCornerRadius = 22.0
  
  override func willMove(toWindow newWindow: UIWindow?) {
    super.willMove(toWindow: newWindow)
    
    guard !didObserveSubviews else { return }
    observeSubviews(self)
    didObserveSubviews = true
  }
  
  func observeSubviews(_ view: UIView) {
    view.layer.addObserver(self, forKeyPath: "cornerRadius", options: [.new], context: nil)
    view.subviews.forEach { observeSubviews($0) }
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
