//
//  Widget+WebContent.swift
//  widget.vision
//
//  Created by Nicholas Jitkoff on 3/1/24.
//

import Foundation

extension Widget {

  func cssSrc() -> String {
    
    var css: [String] = []
    
    var clearSelectors = "html, body"
    if let selectors = self.clearSelectors {
      clearSelectors += ", \(selectors)"
    }
    
    // Selectors that should have transparent backgrounds
    let selectors = clearSelectors
    css.append("\(selectors) { background-color:transparent !important; background-image:none !important;}\n")
    
    // Selectors that should be hidden
    if let selectors = self.removeSelectors {
      css.append("\(selectors) { display:none !important; }")
    }
    
    css.append(":root {")
    if let hex = self.backColor?.description {
      css.append("--back-color: \(hex);")
    }
    if let hex = self.foreColor?.description {
      css.append("--fore-color: \(hex);")
    }
    if let hex = self.tintColor?.description {
      css.append("--tint-color: \(hex);")
    }
    css.append("}")
    
    
    if let fontName = self.fontName, fontName.count > 0  {
      
      css.append (":root { --font-family: '\(fontName)';} * { font-family: var(--font-family) !important; }")
      
      if let fontWeight = self.fontWeight {
        css.append(":root { --font-weight: \(fontWeight);} * { font-weight: var(--font-weight) !important; }")
      }
    }
    
    if let injectCSS = self.injectCSS, injectCSS.count > 0 {
      css.append("\(injectCSS)")
    }
    
    return css.joined(separator:"\n");
  }
  
  func jsSrc() -> String{
    
    var source: [String] = []
    
    source.append("document.head = document.getElementsByTagName('head')[0];")
    
    var viewport = "device-width"
    if let width = self.viewport {
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
    
    
    
    if let fontName = self.fontName, fontName != "" && fontName != "-apple-system" {
      var fontWeight = ""
      if let weight = self.fontWeight, weight.count > 0 {
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
    
    let css = cssSrc()
    
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
}
