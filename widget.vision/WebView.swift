import SwiftUI
import WebKit

// https://www.swiftyplace.com/blog/loading-a-web-view-in-swiftui-with-wkwebview

struct WebView: UIViewRepresentable {
  @Binding var title: String?
  @Binding var location: String?
  @Environment(\.openWindow) var openWindow
  @Binding var widget: Widget
  var webView: WKWebView = WKWebView()
  var loadStatusChanged: ((WebView, Bool, Error?) -> Void)? = nil

  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  func onLoadStatusChanged(perform: ((WebView, Bool, Error?) -> Void)?) -> some View {
      var copy = self
      copy.loadStatusChanged = perform
      return copy
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
  
  let contentController = ContentController()
  
  func overrideJS(widget:Widget) -> String{
    let viewport = widget.viewportWidth
    let zoom = widget.zoom
    var source =
    """
      document.widget = window.webkit.messageHandlers.widget
      document.addEventListener('click', function(){
        window.webkit.messageHandlers.jsHandler.postMessage('click clack!');
      });
      var metaTag=document.createElement('meta');
      metaTag.name = "viewport"
      metaTag.content = "width=\(viewport), initial-scale=\(zoom), maximum-scale=\(zoom), user-scalable=0"
      let head = document.getElementsByTagName('head')[0]
      head.appendChild(metaTag);
      """
    if (widget.style != .opaque) {
      source += """
      var cssTag = document.createElement('style');
      cssTag.innerHTML = 'body, [class*="prototype--background-"] {background-color:transparent !important; background-image:none !important}  [class*="frontend_sha_override_indicator"] {display:none}';
      head.appendChild(cssTag);
      """
     
    }
    return source
  }
  
  func makeUIView(context: Context) -> WKWebView {
    
    let config = webView.configuration
    let script = WKUserScript(source: overrideJS(widget: widget), injectionTime: .atDocumentEnd, forMainFrameOnly: false)
    config.userContentController.addUserScript(script)
    config.userContentController.add(ContentController(), name: "widget")
    webView.isOpaque = false
    
    webView.navigationDelegate = context.coordinator
    
    updateUIView(webView, context: context)
    
    return webView
  }
  
  
  func updateUIView(_ webView: WKWebView, context: Context) {
   
    var userAgent: String?
    switch (widget.userAgent) {
    case "desktop":
      userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.2 Safari/605.1.15"
    case "mobile":
      userAgent = nil
    default:
      userAgent = widget.userAgent
    }
      
    webView.customUserAgent = userAgent ?? "Mozilla/5.0 (iPhone; CPU iPhone OS 14_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.2 Mobile/15E148 Safari/604.1"
    
    
    if (widget.style != .opaque) {
      webView.backgroundColor = UIColor.clear
      webView.scrollView.backgroundColor = UIColor.clear
    }
    
    if let url = URL(string:location!) {
      if (webView.url == nil) {
        let request = URLRequest(url: url)
        webView.load(request)
      } else {
        saveSnapshot(webView)
      }
    }
    
    
    
  }
  
  class ContentController: NSObject, WKScriptMessageHandler {
    @Environment(\.openWindow) var openWindow
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
      print(message.name)
      print(message.body)
//      openWindow(id: "SecondWindow")
    }
  }
  

  func saveSnapshot(_ webView: WKWebView) {
    
    let image = webView.snapshot
    if var path = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
      path.append(path: "thumbnails")
      
      try? FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
      
      if let data = image.pngData(){
        let filename = path.appendingPathComponent(widget.id.uuidString + ".png")
//        print("data \(data) \(filename)")
        try? data.write(to: filename)
      }
    }
  }

  
  
  
}


extension UIView {

    var snapshot: UIImage {
        return UIGraphicsImageRenderer(size: bounds.size).image { _ in
            drawHierarchy(in: bounds, afterScreenUpdates: true)
        }
    }

}
