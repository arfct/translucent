import SwiftUI
import WebKit
import QuickLook
import OSLog

// MARK: Coordinator
class WebViewCoordinator: NSObject, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler, WKScriptMessageHandlerWithReply, WKDownloadDelegate, QLPreviewControllerDataSource {
  @Environment(\.openWindow) var openWindow
  
  let container: WebView
  let webView: WKWebView = WKWebView()
  let widget: Widget
  var lastSize: CGSize = .zero
  var updateWorkItem: DispatchWorkItem?
  var lastSetLocation: String?
  var lastPhase: ScenePhase?
  var currentDownload: URL?
  
  
  init(_ container: WebView, widget: Widget) {
    self.container = container
    self.widget = widget
  }
  
  
  // MARK: Navigation
  
  func open(location: String?, saveValue: Bool = false) {
    console.log("Opening \(location ?? "")")
    if let urlString = location,
       var url = lastSetLocation == nil ? URL(string:urlString) : URL(string:urlString, relativeTo: URL(string: lastSetLocation ?? "")) {
      if url.scheme == "file", let widgets = Bundle.main.url(forResource: "widgets", withExtension:nil) {
        url = URL(filePath: String(url.path(percentEncoded: false).dropFirst()), relativeTo: widgets)
      }
      if (saveValue) { lastSetLocation = urlString }
      
      webView.load(URLRequest(url: url))
    }
    
  }
  
  func loadURL(_ url: URL) {
    webView.load(URLRequest(url: url))
  }
  
  // MARK: WKUserContentController
  
  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    //      console.log("💬 Web Message:\n\(message.body)")
  }
  
  @MainActor
  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) async -> (Any?, String?) {
    
    if let body = message.body as? NSDictionary {
      if let action = body.value(forKey: "action") as? String {
        let args = body.value(forKey: "args") as? NSDictionary
        
        console.log("Action \(action) \(String(describing:args))")
        if (action == "battery") {
          console.log("battery level: \(UIDevice.current.batteryLevel)")
          return (["level": String(UIDevice.current.batteryLevel),
                   "state": String(UIDevice.current.batteryState.rawValue)] as? NSDictionary, nil)
        } else if (action == "resize") {
          // https://developer.apple.com/documentation/uikit/uiwindowscene/geometrypreferences/vision?changes=latest_minor
          
        }
      }
    }
    return (nil, nil)
  }
  
  
  // MARK: WKUIDelegate
  
  func webView(_ webView: WKWebView,
               createWebViewWith configuration: WKWebViewConfiguration,
               for navigationAction: WKNavigationAction,
               windowFeatures: WKWindowFeatures) -> WKWebView? {
    guard let url = navigationAction.request.url else { return nil}
    console.log("Opening in browser \(url)")
    UIApplication.shared.open(url)
    return nil;
  }
  
  func webView(_ webView: WKWebView, 
               runJavaScriptAlertPanelWithMessage message: String,
               initiatedByFrame frame: WKFrameInfo) async {
    console.log("Javascript Alert: \(message)")
  }
  
  func webView(
    _ webView: WKWebView,
    requestMediaCapturePermissionFor origin: WKSecurityOrigin,
    initiatedByFrame frame: WKFrameInfo,
    type: WKMediaCaptureType,
    decisionHandler: @escaping (WKPermissionDecision) -> Void) {
    decisionHandler(.grant)
  }
  

  // MARK: WKNavigationDelegate
  
  func webView(_ webView: WKWebView,
               decidePolicyFor navigationAction: WKNavigationAction, 
               preferences: WKWebpagePreferences,
               decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
    
    console.log("Navigating to \(String(describing:navigationAction.request.url))")
    
    let url = navigationAction.request.url
    if url?.host() == "widget.vision" {
      if let url = url, let context = WidgetApp.modelContext {
        do {
          let widget = Widget(url:url)
          context.insert(widget)
          try context.save()
          openWindow(id: "widget", value: widget.persistentModelID)
        } catch {
          console.log("Error opening url \(error)")
        }
      }
      return decisionHandler(.cancel, preferences)
    } else if navigationAction.request.url?.pathExtension == "usdz" {
      // openWindow(id: "preview", value: navigationAction.request.url!);
      return decisionHandler(.download, preferences)
    } else if navigationAction.shouldPerformDownload {
      decisionHandler(.download, preferences)
    } else {
      decisionHandler(.allow, preferences)
    }
  }
  
  func webView(_ webView: WKWebView, 
               decidePolicyFor navigationResponse: WKNavigationResponse,
               decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
    if navigationResponse.canShowMIMEType {
      //        if let mime = navigationResponse.response.mimeType , mime.starts(with: "application/") {
      //          decisionHandler(.download)
      //        } else {
      decisionHandler(.allow)
      //        }
    } else {
      decisionHandler(.download)
    }
  }
  
  
  // MARK: WKDownloadDelegate
  
  func webView(_ webView: WKWebView,
               navigationAction: WKNavigationAction,
               didBecome download: WKDownload) {
    download.delegate = self
  }
  
  func download(_ download: WKDownload, decideDestinationUsing
                response: URLResponse, suggestedFilename: String,
                completionHandler: @escaping (URL?) -> Void) {
    if let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
      console.log("⬇️ Downloading \(suggestedFilename)")
      let name = "\(suggestedFilename)"
      currentDownload = path.appendingPathComponent(name, isDirectory: false)
      try? FileManager.default.removeItem(at: currentDownload!)
      completionHandler(currentDownload)
    }
  }

  func downloadDidFinish(_ download: WKDownload) {
    container.downloadCompleted?(container, currentDownload!, nil)
    // openWindow(id: "preview", value: currentDownload!);
  }
  
  public func download(_ download: WKDownload,
                       didFailWithError error: Error,
                       resumeData: Data?) {
    console.log("Download error: \(error)")
  }
  

  
  // MARK: QuickLook preview
  func numberOfPreviewItems(in controller: QLPreviewController) -> Int { return 1 }
  func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> any QLPreviewItem {
    return NSURL(string: currentDownload!.absoluteString)! as QLPreviewItem
  }
  
  // TODO: Not working yet
  func queueUpdate(callback: @escaping (() -> Void)) {
    updateWorkItem?.cancel()
    updateWorkItem = DispatchWorkItem(block: callback)
  }
  
  // MARK: State management
  func updateState(webView: WKWebView, loading: Bool) {
    if let url = webView.url  {
      container.browserState.isLoading = loading;
      container.browserState.canGoBack = webView.canGoBack
      container.browserState.canGoForward = webView.canGoForward
      container.browserState.location = url.absoluteString
      container.browserState.url = url;
    }
  }
  
  func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
    updateState(webView: webView, loading: true)
    container.loadStatusChanged?(container, true, nil)
  }
  
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    updateState(webView: webView, loading: false)
    container.loadStatusChanged?(container, false, nil)
    
    let fetchManifestJS = """
      document.querySelector('meta[name="widget"]').getAttribute('content');
      """
    
    webView.evaluateJavaScript(fetchManifestJS, completionHandler: { value, error in
      if let queryString = value as? String {  
        console.log("Found Value \(queryString)")
        self.container.widget.apply(options: queryString, fromSite:true)
      }
    })
  }
  
  func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    updateState(webView: webView, loading: false)
    container.loadStatusChanged?(container, false, nil)
  }
  
}
