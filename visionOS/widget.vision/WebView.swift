import SwiftUI
import WebKit
import QuickLook

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
  
  func cssSrc(widget:Widget) -> String {
    
    var css: [String] = []
    
    var clearSelectors = "body"
    if let selectors = widget.clearSelectors {
      clearSelectors += ", \(selectors)"
    }
    
    // Selectors that should have transparent backgrounds
    let selectors = clearSelectors
    css.append("\(selectors) { background-color:transparent !important; background-image:none !important;}\n")
    
    // Selectors that should be hidden
    if let selectors = widget.removeSelectors {
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
    
    
    if let fontName = widget.fontName, fontName.count > 0  {
      
      css.append (":root { --font-family: '\(fontName)';} * { font-family: var(--font-family) !important; }")
      
      if let fontWeight = widget.fontWeight {
        css.append(":root { --font-weight: \(fontWeight);} * { font-weight: var(--font-weight) !important; }")
      }
    }
    
    if let injectCSS = widget.injectCSS, injectCSS.count > 0 {
      css.append("\(injectCSS)")
    }
    
    return css.joined(separator:"\n");
  }
  
  func jsSrc(widget:Widget) -> String{
    
    var source: [String] = []
    
    source.append("document.head = document.getElementsByTagName('head')[0];")
    
    var viewport = "device-width"
    if let width = widget.viewport {
      viewport = width
    }
    
    source.append(
      """
      // Viewport Tag
      var viewportTag = document.querySelector("meta[name=viewport]");
      if (!viewportTag) {
        viewportTag = document.createElement('meta');
        viewportTag.name = "viewport"
        document.head.appendChild(viewportTag);
      }
      viewportTag.setAttribute('content', "width=\(viewport)")
      """)
    
    
    
    if let fontName = widget.fontName, fontName != "" && fontName != "-apple-system" {
      var fontWeight = ""
      if let weight = widget.fontWeight, weight.count > 0 {
        fontWeight = ":\(weight)"
      }
      source.append ("""
        // Font Tag
        var fontTag = document.getElementById('widgetVisionFontTag')
        if (!fontTag) {
          fontTag = document.createElement('link');
          fontTag.id = "widgetVisionFontTag";
          fontTag.rel = 'stylesheet';
          document.head.appendChild(fontTag);
        }
        fontTag.href = 'https://fonts.googleapis.com/css?family=\(fontName.replacingOccurrences(of: " ", with: "+"))\(fontWeight)&display=swap';
        """)
    }
    
    let css = cssSrc(widget: widget)
    
    source.append("""
    
    var cssTag = document.getElementById('widgetVisionCSSTag')
    if (!cssTag) {
      cssTag = document.createElement('style');
      cssTag.id = "widgetVisionCSSTag"
      document.head.appendChild(cssTag);
    }
    
    cssTag.innerHTML = `\n\(css)\n`
    
    """)
    
    //    if let injectJS = widget.injectJS, injectJS.count > 0 {
    //      source.append("\n\(injectJS)\n")
    //    }
    
    return source.joined(separator:"\n")
  }
  
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
    
    
    
    var js =  jsSrc(widget: widget)
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
    webView.evaluateJavaScript(jsSrc(widget: widget)) { object, error in
    }
    if (webView.customUserAgent != widget.userAgentString) {
      webView.customUserAgent = widget.userAgentString
    }
    
  }
  
  func dismantleUIView(_ webView: WKWebView,coordinator: WebViewCoordinator ) {
    print("Dismantling \(webView) \(coordinator)")
    webView.stopLoading()
    webView.navigationDelegate = nil
    webView.saveSnapshot(Wrapper(widget));
    webView.removeFromSuperview()
    
  }
  
  func updateSnapshot(_ webView: WKWebView) {
    NSObject.cancelPreviousPerformRequests(withTarget: webView)
    webView.perform(#selector(WKWebView.saveSnapshot(_:)), with:Wrapper(widget), afterDelay: 1.0)
  }
  
  func sizeThatFits(
    _ proposal: ProposedViewSize,
    uiView: WebView, context: Context
  ) -> CGSize? {
    return CGSizeMake(360, 640)
  }
  
  class WebViewCoordinator: NSObject, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler, WKScriptMessageHandlerWithReply, WKDownloadDelegate, QLPreviewControllerDataSource {
    
    
    @Environment(\.openWindow) var openWindow
    
    let webView: WKWebView = WKWebView()
    let parent: WebView
    var lastSize: CGSize = .zero
    var updateWorkItem: DispatchWorkItem?
    var activeLocation: String?
    var currentDownload: URL?
    
    init(_ parent: WebView) {
      self.parent = parent
    }
    
    func loadURL(string: String?) {
      if var urlString = string,
         var url = URL(string:urlString) {
        if url.scheme == "file", let widgets = Bundle.main.url(forResource: "widgets", withExtension:nil) {
          url = URL(filePath: String(url.path(percentEncoded: false).dropFirst()), relativeTo: widgets)

        }

        
        
        activeLocation = urlString
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
        let action = body.value(forKey: "action") as? String
        let args = body.value(forKey: "args") as? NSDictionary
        
        if (action == "battery") {
          print("battery level: \(UIDevice.current.batteryLevel)")
          return (["level": String(UIDevice.current.batteryLevel),
                   "state": String(UIDevice.current.batteryState.rawValue)] as? NSDictionary, nil)
        } else if (action == "resize") {
        // https://developer.apple.com/documentation/uikit/uiwindowscene/geometrypreferences/vision?changes=latest_minor
          
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
      
      
      if navigationAction.request.url?.pathExtension == "usdz" {
//        openWindow(id: "preview", value: navigationAction.request.url!);
        return decisionHandler(.download, preferences)
      }
      if navigationAction.shouldPerformDownload {
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
  
  
}

extension WKWebView {
  @objc func saveSnapshot(_ wrapper: Wrapper) {
    if self.url?.absoluteString == "about:blank" { return }
    guard let path = wrapper.widget.thumbnailFile else { return }
    let image = self.snapshotImage
    
    if (image.isBlank()) { return }
    
    if let data = image.pngData(){
      print("🖼️ Saved Snapshot, \(String(describing: self.url)) \(wrapper.widget.thumbnailFile)")
      try? data.write(to: path)
      wrapper.widget.thumbnailChanged()
    } else {
      print("❌ Failed Snapshot, \(String(describing: self.url))")
    }
  }
  
  var snapshotImage: UIImage {
    return UIGraphicsImageRenderer(size: bounds.size).image { _ in
      drawHierarchy(in: bounds, afterScreenUpdates: true)
    }
  }
}
