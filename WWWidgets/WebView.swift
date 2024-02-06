import SwiftUI
import WebKit

// https://www.swiftyplace.com/blog/loading-a-web-view-in-swiftui-with-wkwebview

struct WebView: UIViewRepresentable {
  @Binding var location: String
  @Environment(\.openWindow) var openWindow
@Binding var widgetModel: WidgetModel

  
  let contentController = ContentController()
  
  
  func makeUIView(context: Context) -> WKWebView {
    let config = WKWebViewConfiguration()
    
    let zoom = widgetModel.zoom ?? 1.0
    
    print(widgetModel.location)
    print(widgetModel.zoom)
    let source = """
document.widget = window.webkit.messageHandlers.widget
document.addEventListener('click', function(){
  window.webkit.messageHandlers.jsHandler.postMessage('click clack!');
});
var metaTag=document.createElement('meta');
metaTag.name = "viewport"
metaTag.content = "width=device-width, initial-scale=\(zoom), maximum-scale=\(zoom), user-scalable=0"
let head = document.getElementsByTagName('head')[0]
head.appendChild(metaTag);

var cssTag = document.createElement('style');
cssTag.innerHTML = 'body {background-color: transparent !important;}';
head.appendChild(cssTag);
console.log('hi')

"""
    
//    openWindow(id: "SecondWindow")
    
    let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
    config.userContentController.addUserScript(script)
    
    let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 100, height: 100), configuration: config)
    config.userContentController.add(ContentController(), name: "widget")
    webView.isOpaque = false
    webView.backgroundColor = UIColor.clear
    webView.scrollView.backgroundColor = UIColor.clear
    webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.2 Mobile/15E148 Safari/604.1"
    return webView
  }
  
  
  class ContentController: NSObject, WKScriptMessageHandler {
    @Environment(\.openWindow) var openWindow

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
      print(message.name)
      print(message.body)
      
      openWindow(id: "SecondWindow")
    }
  }
  
  func updateUIView(_ webView: WKWebView, context: Context) {
    if let url = URL(string:location) {
      let request = URLRequest(url: url)
      webView.load(request)
    }

  }
}
