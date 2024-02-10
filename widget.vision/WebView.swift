import SwiftUI
import WebKit

// https://www.swiftyplace.com/blog/loading-a-web-view-in-swiftui-with-wkwebview

struct WebView: UIViewRepresentable {
  @Binding var title: String?
  @Binding var location: String?
  @Environment(\.openWindow) var openWindow
  @Binding var widgetModel: Widget
  var loadStatusChanged: ((Bool, Error?) -> Void)? = nil

  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  func onLoadStatusChanged(perform: ((Bool, Error?) -> Void)?) -> some View {
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
          parent.loadStatusChanged?(true, nil)
      }

      func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
          parent.title = webView.title ?? ""
          parent.loadStatusChanged?(false, nil)
      }

      func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
          parent.loadStatusChanged?(false, error)
      }
  }
  
  let contentController = ContentController()
  
  func overrideJS(widget:Widget) -> String{
    let viewport = widget.viewportWidth
    let zoom = widget.zoom ?? 1.0
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
    if (widgetModel.style != .opaque) {
      source += """
      var cssTag = document.createElement('style');
      cssTag.innerHTML = 'body, [class*="prototype--background-"] {background-color:\(widgetModel.color) !important; background-image:none !important}  [class*="frontend_sha_override_indicator"] {display:none}';
      head.appendChild(cssTag);
      """
     
    }
    return source
  }
  
  func makeUIView(context: Context) -> WKWebView {
    let config = WKWebViewConfiguration()
    let zoom = widgetModel.zoom ?? 1.0
    
    let viewport = self.widgetModel.viewportWidth
    let script = WKUserScript(source: overrideJS(widget: widgetModel), injectionTime: .atDocumentEnd, forMainFrameOnly: false)
    config.userContentController.addUserScript(script)
    
    let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 100, height: 100), configuration: config)
    config.userContentController.add(ContentController(), name: "widget")
    webView.isOpaque = false
    
    if (widgetModel.style != .opaque) {
      webView.backgroundColor = UIColor.clear
      webView.scrollView.backgroundColor = UIColor.clear
    }
    
    webView.navigationDelegate = context.coordinator
    
    webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.2 Mobile/15E148 Safari/604.1"
    return webView
  }
  
  
  class ContentController: NSObject, WKScriptMessageHandler {
    @Environment(\.openWindow) var openWindow
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
      print(message.name)
      print(message.body)
//      openWindow(id: "SecondWindow")
    }
  }
  
  func updateUIView(_ webView: WKWebView, context: Context) {
    print("Updating web view \(webView.url)")
    
    if let url = URL(string:location!) {
      if (webView.url == nil) {
        let request = URLRequest(url: url)
        webView.load(request)
      }
    }
    
  }
}
