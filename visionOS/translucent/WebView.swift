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
  @Environment(\.dismiss) var dismiss
  static var newWebViewOverride: WebViewSetup?
  
  @Binding var title: String?
  @Binding var location: String?
  @Binding var widget: Widget
  @Binding var phase: ScenePhase
  @Binding var attachment: URL?
  @Binding var browserState: BrowserState
  
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
  
  func closeWindow() {
    dismiss()
  }
  func makeCoordinator() -> WebViewCoordinator { WebViewCoordinator(self, widget: widget) }
  
  // MARK: makeUIView
  
  func makeUIView(context: Context) -> WKWebView {
    
    let premadeWebView = WebView.newWebViewOverride?.webView
    let isOverride = premadeWebView != nil
    WebView.newWebViewOverride = nil;
    
    let webView = premadeWebView ?? WKWebView()
    context.coordinator.webView = webView
    webView.navigationDelegate = context.coordinator
    webView.uiDelegate = context.coordinator
    
    browserState.coordinator = context.coordinator
    browserState.webView = webView
    
    webView.overrideUserInterfaceStyle = .dark
    webView.isInspectable = true
    
    UIDevice.current.isBatteryMonitoringEnabled = true
    
    if (!isOverride) {
      
      webView.isOpaque = false
      webView.backgroundColor = UIColor.clear
      webView.scrollView.backgroundColor = UIColor.clear
      webView.customUserAgent = widget.userAgentString
      
      // MARK: Configuration
      let config = webView.configuration
      
      config.preferences.isElementFullscreenEnabled = true
      config.preferences.javaScriptCanOpenWindowsAutomatically = true
      config.userContentController.addScriptMessageHandler(context.coordinator, contentWorld: .page, name: "widget")
      
      config.userContentController.addUserScript(WKUserScript(
        source:"""
      document.documentElement.classList.add("asWidget")
      window.widget = window.webkit.messageHandlers.widget
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
      js += "\nwindow.widget?.postMessage({'event':'loaded'})\n"
      
      let script = WKUserScript(source:js, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
      config.userContentController.addUserScript(script)
      
      context.coordinator.open(location: location, saveValue: true)
    }
    updateSnapshot(webView)
    return webView
  }
  
  // MARK: updateUIView
  
  func updateUIView(_ webView: WKWebView, context: Context) {
    
    if context.coordinator.lastPhase != phase {
      if phase == .background {
        context.coordinator.lastPhase = phase;
      }
    }
    
    if (context.coordinator.lastSetLocation != location) {
      context.coordinator.open(location: location, saveValue: true)
    }

    let zoom = widget.zoom
    webView.pageZoom = zoom

    //    webView.evaluateJavaScript("document.documentElement.style.zoom = \(widget.zoom)", completionHandler: nil)

    let size = CGSize(width:widget.width, height: widget.height)
    if (!CGSizeEqualToSize(size, context.coordinator.lastSize)) {
      context.coordinator.lastSize = size
    } else {
      updateWebView(webView, context: context)
    }
    
    updateSnapshot(webView)
  }
  
  func updateWebView(_ webView: WKWebView, context: Context) {
    
    if widget.isTemporaryWidget { return }
    
    webView.evaluateJavaScript(widget.jsSrc()) { object, error in
    }
    if (webView.customUserAgent != widget.userAgentString) {
      webView.customUserAgent = widget.userAgentString
    }
    
  }
  
  // MARK: dismantleUIView
  
  static func dismantleUIView(_ webView: WKWebView, coordinator: WebViewCoordinator) {
    print("Dismantling \(webView) \(coordinator)")
    webView.stopLoading()
    webView.navigationDelegate = nil
    webView.uiDelegate = nil
    webView.configuration.userContentController.removeScriptMessageHandler(forName: "widget")
    webView.removeFromSuperview()
  }
  
  
  // MARK: snapshotting
  
  func updateSnapshot(_ webView: WKWebView) {
    NSObject.cancelPreviousPerformRequests(withTarget: webView)
    if (widget.shouldCacheThumbnail) {
      webView.perform(#selector(WKWebView.saveSnapshot(_:)), with:Wrapper(widget), afterDelay: 1.0)
    }
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
//      console.debug("🖼️ Saved Snapshot, \(url.absoluteString)")
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
