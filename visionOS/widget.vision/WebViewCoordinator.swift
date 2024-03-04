import SwiftUI
import WebKit
import QuickLook
import OSLog

// MARK: Coordinator
class WebViewCoordinator: NSObject, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler, WKScriptMessageHandlerWithReply, WKDownloadDelegate, QLPreviewControllerDataSource {
  
  @Environment(\.openWindow) var openWindow
  
  
  let webView: WKWebView = WKWebView()
  let parent: WebView
  var lastSize: CGSize = .zero
  var updateWorkItem: DispatchWorkItem?
  var lastSetLocation: String?
  var lastPhase: ScenePhase?
  var currentDownload: URL?
  
  init(_ parent: WebView) {
    self.parent = parent
  }
  
  func open(location: String?, saveValue: Bool = false) {
    print("Opening \(location) \(lastSetLocation) \(saveValue)")
    if let urlString = location,
       var url = lastSetLocation == nil ? URL(string:urlString) : URL(string:urlString, relativeTo: URL(string: lastSetLocation ?? "")) {
      print("Open \(url.absoluteString)")
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
  
  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    //      print("💬 Web Message:\n\(message.body)")
  }
  
  @MainActor
  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) async -> (Any?, String?) {
    
    if let body = message.body as? NSDictionary {
      if let action = body.value(forKey: "action") as? String {
        let args = body.value(forKey: "args") as? NSDictionary
        
        print("Action \(action) \(String(describing:args))")
        if (action == "battery") {
          print("battery level: \(UIDevice.current.batteryLevel)")
          return (["level": String(UIDevice.current.batteryLevel),
                   "state": String(UIDevice.current.batteryState.rawValue)] as? NSDictionary, nil)
        } else if (action == "resize") {
          // https://developer.apple.com/documentation/uikit/uiwindowscene/geometrypreferences/vision?changes=latest_minor
          
        }
      }
    }
    return (nil, nil)
  }
  
  func webView(
    _ webView: WKWebView,
    requestMediaCapturePermissionFor origin: WKSecurityOrigin,
    initiatedByFrame frame: WKFrameInfo,
    type: WKMediaCaptureType,
    decisionHandler: @escaping (WKPermissionDecision) -> Void
  ) {
    
    decisionHandler(.grant)
  }
  
  
  func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
    
    console.log("Navigating to \(String(describing:navigationAction.request.url))")
    
    let url = navigationAction.request.url
    if url?.host() == "widget.vision" {
      if let url = url, let context = parent.widget.modelContext {
        do {
          let widget = Widget(url:url)
          context.insert(widget)
          try context.save()
          openWindow(id: "widget", value: widget.persistentModelID)
        } catch {
          print("Error opening url \(error)")
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
  
  func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
    if navigationResponse.canShowMIMEType {
      //        if let mime = navigationResponse.response.mimeType , mime.starts(with: "application/") {
      //          print("Mime \(mime )")
      //          decisionHandler(.download)
      //        } else {
      decisionHandler(.allow)
      //        }
    } else {
      decisionHandler(.download)
    }
  }
  
  func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo) async {
    console.log("Javascript Alert: \(message)")
  }
  func download(_ download: WKDownload, decideDestinationUsing
                response: URLResponse, suggestedFilename: String,
                completionHandler: @escaping (URL?) -> Void) {
    if let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
      print("⬇️ Downloading \(suggestedFilename)")
      let name = "\(suggestedFilename)"
      currentDownload = path.appendingPathComponent(name, isDirectory: false)
      try? FileManager.default.removeItem(at: currentDownload!)
      completionHandler(currentDownload)
    }
  }
  
  func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
    download.delegate = self
  }
  
  func downloadDidFinish(_ download: WKDownload) {
    parent.downloadCompleted?(parent, currentDownload!, nil)
    // openWindow(id: "preview", value: currentDownload!);
  }
  
  public func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
    print("Download error: \(error)")
  }
  
  func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
    guard let url = navigationAction.request.url else { return nil}
    print("Opening in browser \(url)")
    UIApplication.shared.open(url)
    return nil;
  }
  func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
    return 1
  }
  
  func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> any QLPreviewItem {
    return NSURL(string: currentDownload!.absoluteString)! as QLPreviewItem
  }
  // TODO: Not working yet
  func queueUpdate(callback: @escaping (() -> Void)) {
    updateWorkItem?.cancel()
    updateWorkItem = DispatchWorkItem(block: callback)
  }
  
  func updateState(webView: WKWebView, loading: Bool) {
    if let url = webView.url  {
      parent.browserState.isLoading = loading;
      parent.browserState.canGoBack = webView.canGoBack
      parent.browserState.canGoForward = webView.canGoForward
      parent.browserState.location = url.absoluteString
      parent.browserState.url = url;
    }
  }
  
  func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
    updateState(webView: webView, loading: true)
    parent.loadStatusChanged?(parent, true, nil)
  }
  
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    updateState(webView: webView, loading: false)
    parent.loadStatusChanged?(parent, false, nil)

  }
  
  func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    updateState(webView: webView, loading: false)
    parent.loadStatusChanged?(parent, false, nil)
  }
  
}
