import SwiftUI
import WebKit

// https://www.swiftyplace.com/blog/loading-a-web-view-in-swiftui-with-wkwebview

struct WebView: UIViewRepresentable {
  @Environment(\.openWindow) var openWindow
  @Binding var title: String?
  @Binding var location: String?
  @Binding var widget: Widget
  
  var webView: WKWebView = WKWebView()
  var loadStatusChanged: ((WebView, Bool, Error?) -> Void)? = nil
  
  func onLoadStatusChanged(perform: ((WebView, Bool, Error?) -> Void)?) -> some View {
    var copy = self
    copy.loadStatusChanged = perform
    return copy
  }
  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  let contentController = ContentController()
  
  func overrideJS(widget:Widget) -> String{
    let zoom = widget.zoom
    var viewport = "device-width"
    if let width = widget.viewportWidth {
      viewport = String(width)
    }
    
    
    var source: [String] = []
    
    // Post messages with widget.postMessage('Clicked Page!');
    source.append("window.widget = window.webkit.messageHandlers.widget;")
    
    source.append("let head = document.getElementsByTagName('head')[0];")
    
    source.append(
      """
      // Viewport Tag
      var viewportTag = document.createElement('meta');
      viewportTag.name = "viewport"
      viewportTag.content = "width=\(viewport), initial-scale=\(zoom), maximum-scale=\(zoom), user-scalable=0"
      head.appendChild(viewportTag);
      """)
    
    
    var css: [String] = []
    
    let clearSelectors = widget.clearClasses ?? "body"
    
    // Selectors that should have transparent backgrounds
    let selectors = clearSelectors
    css.append("\(selectors) { background-color:transparent !important; background-image:none !important;}\n")
    
    // Selectors that should be hidden
    if let selectors = widget.removeClasses {
      css.append("\(selectors) { display:none !important; }")
    }
    
    css.append(":root {")
    if let hex = widget.backColor?.description {
      css.append("--back-color: \(hex);")
    }
    if let hex = widget.foreColor?.description {
      css.append("--fore-color: \(hex);")
    }
    if let hex = widget.tintColor?.description {
      css.append("--tint-color: \(hex);")
    }
    css.append("}")
    //    css.append("""
//      :root {
//        --fore-color: \(widget.foreColor.description);
//        --back-color: \(widget.backColor.description);
//        --tint-color: \(widget.tintColor.description);
//      }
//      """
//    )
    
    if (widget.fontName != "" && widget.fontName != "-apple-system") {
      source.append ("""
        // Font Tag
        var fontTag = document.createElement('link');
        fontTag.rel = 'stylesheet';
        fontTag.href = 'https://fonts.googleapis.com/css?family=\(widget.fontName.replacingOccurrences(of: " ", with: "+"))&display=swap';
        head.appendChild(fontTag);
        """)
    }
    
    if (widget.fontName.count > 0 ) {
      css.append ("""
        :root { --font-family: '\(widget.fontName)';}
        body { font-family: var(--font-family) !important; }
        """)
    }
 
    
    
    
    if let injectCSS = widget.injectCSS, injectCSS.count > 0 {
      css.append("\(injectCSS)")
    }
    
    source.append("""
    var cssTag = document.createElement('style');
    cssTag.innerHTML = `\n\(css.joined(separator:"\n"))\n`
    head.appendChild(cssTag);
    
    """)
    
    //    if let injectJS = widget.injectJS, injectJS.count > 0 {
    //      source.append("\n\(injectJS)\n")
    //    }
    
    print("💉 Injecting Source:\n\n\(source.joined(separator:"\n"))")
    return source.joined(separator:"\n")
  }
  
  func makeUIView(context: Context) -> WKWebView {
    let config = webView.configuration
    let script = WKUserScript(source: overrideJS(widget: widget), injectionTime: .atDocumentEnd, forMainFrameOnly: false)
    config.userContentController.addUserScript(script)
    config.userContentController.add(ContentController(), name: "widget")
    
    webView.isOpaque = false
    webView.navigationDelegate = context.coordinator
    
    webView.backgroundColor = UIColor.clear
    webView.scrollView.backgroundColor = UIColor.clear
    
    var userAgent: String?
    switch (widget.userAgent) {
    case "desktop":
      userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.2 Safari/605.1.15"
    case "mobile":
      userAgent = nil
    default:
      userAgent = widget.userAgent
    }
    webView.overrideUserInterfaceStyle = .dark
    
    webView.customUserAgent = userAgent ?? "Mozilla/5.0 (iPhone; CPU iPhone OS 14_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.2 Mobile/15E148 Safari/604.1"
    
    if let url = URL(string:location!) {
      let request = URLRequest(url: url)
      webView.load(request)
    }

    updateSnapshot(webView)
    return webView
  }
  
  
  func updateUIView(_ webView: WKWebView, context: Context) {
    updateSnapshot(webView)
  }
  
  func updateSnapshot(_ webView: WKWebView) {
    NSObject.cancelPreviousPerformRequests(withTarget: webView)
    webView.perform(#selector(WKWebView.saveSnapshot(path:)), with:widget.thumbnailFile, afterDelay: 1.0)
  
  }

  func sizeThatFits(
    _ proposal: ProposedViewSize,
    uiView: WebView, context: Context
  ) -> CGSize? {
    return CGSizeMake(360, 640)
  }
  
  
  func saveSnapshot(_ view: WKWebView?) {
    let image = (view ?? webView).snapshot
    if let path = widget.thumbnailFile {
      if let data = image.pngData(){
        print("🖼️ Saved Snapshot, \(webView.url)")
        try? data.write(to: path)
      } else {
        print("❌ Failed Snapshot, \(webView)")
      }
    }
  }




class Coordinator: NSObject, WKNavigationDelegate {
  let parent: WebView
  
  init(_ parent: WebView) {
    self.parent = parent
  }
  
  func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
    parent.loadStatusChanged?(parent, true, nil)
  }
  
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    parent.title = webView.title ?? ""
    parent.loadStatusChanged?(parent, false, nil)
  }
  
  func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    parent.loadStatusChanged?(parent, false, error)
  }
}


class ContentController: NSObject, WKScriptMessageHandler {
  @Environment(\.openWindow) var openWindow
  
  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    print("💬 Web Message:\n\(message.body)")
  }
}

}


extension WKWebView {
  @objc func saveSnapshot(path: URL) {
    let image = self.snapshot

      if let data = image.pngData(){
        print("🖼️ Saved Snapshot, \(self.url)")
        try? data.write(to: path)
      } else {
        print("❌ Failed Snapshot, \(self.url)")
      }
    }
    
  var snapshot: UIImage {
    return UIGraphicsImageRenderer(size: bounds.size).image { _ in
      drawHierarchy(in: bounds, afterScreenUpdates: true)
    }
  }
  
}
