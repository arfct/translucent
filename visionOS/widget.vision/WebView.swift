import SwiftUI
import WebKit
import OSLog

@objc class Wrapper: NSObject {
  var widget: Widget
  init(_ widget: Widget) {
    self.widget = widget
  }
}

struct WebView: UIViewRepresentable {
  @Environment(\.openWindow) var openWindow
  
  @Binding var title: String?
  @Binding var location: String?
  @Binding var widget: Widget
  @Binding var phase: ScenePhase
  @Binding var attachment: URL?
  
  
  // MARK: Modifiers
  var loadStatusChanged: ((WebView, Bool, Error?) -> Void)? = nil
  func onLoadStatusChanged(perform: ((WebView, Bool, Error?) -> Void)?) -> WebView {
    var copy = self
    copy.loadStatusChanged = perform
    return copy
  }
  
  var downloadCompleted: ((WebView, URL, Error?) -> Void)? = nil
  func onDownloadCompleted(perform: ((WebView, URL, Error?) -> Void)?) -> some View {
    var copy = self
    copy.downloadCompleted = perform
    return copy
  }
  
  
  
  func makeCoordinator() -> WebViewCoordinator { WebViewCoordinator(self) }
 
  // MARK: makeUIView
  func makeUIView(context: Context) -> WKWebView {
    let webView = context.coordinator.webView
    webView.navigationDelegate = context.coordinator
    webView.uiDelegate = context.coordinator
    webView.isOpaque = false
    webView.backgroundColor = UIColor.clear
    webView.scrollView.backgroundColor = UIColor.clear
    webView.overrideUserInterfaceStyle = .dark
    
    print("User Agent \(widget.userAgent)")
    webView.customUserAgent = widget.userAgentString
    
    UIDevice.current.isBatteryMonitoringEnabled = true
    
    let config = webView.configuration
    
    // Post messages with widget.postMessage('Clicked Page!');
    //        config.userContentController.add(context.coordinator, name: "widget")
    config.userContentController.addScriptMessageHandler(context.coordinator, contentWorld: .page, name: "widget")
    
    config.userContentController.addUserScript(WKUserScript(
      source:"""
      window.widget = window.webkit.messageHandlers.widget
      console.log("window.widget", window.widget)
      window.widgetproxy = new Proxy(window.widget, {
        get(target, prop, receiver) {
          return Reflect.get(...arguments);
        }
      })
            console.log("window.widget", window.widget)
      
      """,
      injectionTime: .atDocumentStart,
      forMainFrameOnly: false))
    
    
    
    var js =  widget.jsSrc()
    js += """
      window.widget?.postMessage({"event":"loaded"})
      """
    
    print("💉 Injecting Source:\n\n\(js)")
    
    let script = WKUserScript(source:js, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
    config.userContentController.addUserScript(script)
    
    context.coordinator.loadURL(string: location)
    
    updateSnapshot(webView)
    return webView
  }
  
  // MARK: updateUIView
  func updateUIView(_ webView: WKWebView, context: Context) {
    
    if (phase == .background) {
      context.coordinator.loadURL(string: "about:blank")
    }
    
    if (context.coordinator.activeLocation != location) {
      context.coordinator.loadURL(string: location)
    }
    
    
    let size = CGSize(width:widget.width, height: widget.height)
    
    if (!CGSizeEqualToSize(size, context.coordinator.lastSize)) {
      context.coordinator.lastSize = size
      context.coordinator.queueUpdate() {
        print("Callback after queue")
      }
    } else {
      updateWebView(webView, context: context)
    }
    
    updateSnapshot(webView)
  }
  
  func updateWebView(_ webView: WKWebView, context: Context) {
    webView.pageZoom = widget.zoom
    webView.evaluateJavaScript(widget.jsSrc()) { object, error in
    }
    if (webView.customUserAgent != widget.userAgentString) {
      webView.customUserAgent = widget.userAgentString
    }
    
  }
  
  // MARK: dismantleUIView
  func dismantleUIView(_ webView: WKWebView,coordinator: WebViewCoordinator ) {
    print("Dismantling \(webView) \(coordinator)")
    webView.stopLoading()
    webView.navigationDelegate = nil
    webView.saveSnapshot(Wrapper(widget));
    webView.removeFromSuperview()
    
  }

  func sizeThatFits(
    _ proposal: ProposedViewSize,
    uiView: WebView, context: Context
  ) -> CGSize? {
    return CGSizeMake(360, 640)
  }
  
  func updateSnapshot(_ webView: WKWebView) {
    NSObject.cancelPreviousPerformRequests(withTarget: webView)
    webView.perform(#selector(WKWebView.saveSnapshot(_:)), with:Wrapper(widget), afterDelay: 1.0)
  }
}

extension WKWebView {
  @objc func saveSnapshot(_ wrapper: Wrapper) {
    guard let url = self.url else { return }
    guard let path = wrapper.widget.thumbnailFile else { return }
    if url.absoluteString == "about:blank" { return }
    let image = self.snapshotImage
    
    if (image.isBlank()) { return }
    
    if let data = image.pngData(){
      console.debug("🖼️ Saved Snapshot, \(url.absoluteString)")
      try? data.write(to: path)
      wrapper.widget.thumbnailChanged()
    } else {
      console.error("❌ Failed Snapshot, \(url.absoluteString)")
    }
  }
  
  var snapshotImage: UIImage {
    return UIGraphicsImageRenderer(size: bounds.size).image { _ in
      drawHierarchy(in: bounds, afterScreenUpdates: true)
    }
  }
}
