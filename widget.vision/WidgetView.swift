//
//  ContentView.swift
//  ittybittywidgets
//
//  Created by Nicholas Jitkoff on 1/28/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

extension Animation {
  static func ripple() -> Animation {
    Animation.spring(dampingFraction: 0.5)
      .speed(2)
  }
}

struct WidgetView: View {
  @Environment(\.openWindow) var openWindow
  
  @Environment(\.isFocused) var isFocused
  @State var widgetModel: WidgetModel
  @State private var flipped: Bool = false
  
  func toggleSettings() {
    withAnimation(.spring) { flipped.toggle() }
  }
  
  var body: some View {
    GeometryReader { geometry in
      VStack(alignment: .center) {
        if true {
          
          
        }
        ZStack(alignment: .bottomTrailing) {
          WebView(location: $widgetModel.location, widgetModel: $widgetModel)
            .cornerRadius(widgetModel.style != .glass ? 20 : 10)
            .disabled(flipped)
            .glassBackgroundEffect(in:RoundedRectangle(cornerRadius: widgetModel.radius), displayMode: (widgetModel.style == .glass /*|| widgetModel.style  == .glass_forced*/) ? .always : .never)
            .opacity(flipped ? 0.0 : 1.0)
          
          WidgetSettingsView(widgetModel:$widgetModel, callback: toggleSettings)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .glassBackgroundEffect(in:RoundedRectangle(cornerRadius: widgetModel.radius))
            .offset(z: 1)
            .opacity(flipped ? 1.0 : 0.0)
            .rotation3DEffect(.degrees(180), axis: (0, 1, 0), anchor: UnitPoint3D(x: 0.5, y: 0, z: 0))
            .disabled(!flipped)
          
        }
        .ornament(attachmentAnchor: .scene(.top)) {
          Button("•", systemImage: "circle.fill") { toggleSettings() }
            .buttonBorderShape(.circle)
            .tint(.primary)
            .buttonStyle(.borderless)
            .transition(.move(edge: .top))
            .buttonStyle(.automatic)
            .labelStyle(.titleOnly)
            .hoverEffect()
            .opacity(1.0)
        }
      }
      
      .rotation3DEffect(.degrees(flipped ? 180.0 : 0.0), axis: (0, 1, 0), anchor: UnitPoint3D(x: 0.5, y: 0, z: 0))
    }
  }
}

#Preview(windowStyle: .plain) {
  let viewModel = WidgetViewModel()
  var widgetId: UUID = viewModel.widgetModels[0].id
  if let widgetModel = viewModel[widgetId: widgetId] {
    WidgetView(widgetModel:widgetModel)
  }
}
