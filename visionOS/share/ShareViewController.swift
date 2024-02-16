import UIKit

class ShareViewController: UIViewController {
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    if let item = extensionContext?.inputItems.first as? NSExtensionItem {
      var title: String?
      if let data = item.userInfo?[NSExtensionItemAttributedContentTextKey] as? Data {
        title = try? NSAttributedString(data: data, options: [:], documentAttributes: nil).string
      }
      
      if let attachments = item.attachments {
        for attachment: NSItemProvider in attachments {
          _ = attachment.loadObject(ofClass: URL.self) { url, arg  in
            if let url = url {
              if let application = UIApplication.value(forKeyPath: #keyPath(UIApplication.shared)) as? UIApplication {
                var urlString = "widget-\(url)"
                if let title = title, (title.count > 0) {
                  urlString += "#wv?name=\(title)"}
                application.perform(NSSelectorFromString("openURL:"),
                                    with: URL(string: urlString))
              }
            }
          }
        }
      }
    }
    
    self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
  }
}
