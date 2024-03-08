//
//  ChromaView.swift
//  widget.vision
//
//  Created by Nicholas Jitkoff on 3/6/24.
//

import SwiftUI

struct ChromaView: View {
  
  @State private var hue: CGFloat = 0.6
  func updateHue() {
    hue = fmod(floor(Date().timeIntervalSince1970), 360) / 360.0
  }
  
  
    var body: some View {
      Rectangle()
      
        .fill(RadialGradient(gradient: Gradient(
          colors: [
            Color(hue:hue, saturation: 0.6, brightness: 1.0).opacity(0.1),
            Color(hue:hue, saturation: 0.9, brightness: 0.2).opacity(0.57),
          ]),
                             center: .topLeading, startRadius:0, endRadius: 1000))
        .onAppear() {
          updateHue()
          Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            updateHue()
          }
        }
    }
  
}

#Preview {
    ChromaView()
}
