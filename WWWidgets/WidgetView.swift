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
  
  @State var widgetModel: WidgetModel
  @State private var flipped: Bool = false
  
  func toggleSettings() {
    withAnimation(.spring) { flipped.toggle() }
  }
  
  var body: some View {
    
    
    ZStack(alignment: .bottomTrailing) {
      
      WebView(location: $widgetModel.location, widgetModel: $widgetModel)
        .cornerRadius(widgetModel.style == .opaque ? 40 : 0)
        .disabled(flipped)
        .glassBackgroundEffect(displayMode: (widgetModel.style == .glass || widgetModel.style  == .glass_forced) ? .always : .never)
        .opacity(flipped ? 0.0 : 1.0)
        .task {
          print(widgetModel.style)
        }
      WidgetSettingsView(widgetModel:$widgetModel, callback: toggleSettings)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .glassBackgroundEffect()
        .offset(z: 1)
        .opacity(flipped ? 1.0 : 0.0)
        .rotation3DEffect(.degrees(180), axis: (0, 1, 0), anchor: UnitPoint3D(x: 0.5, y: 0, z: 0))
        .disabled(!flipped)
      
      Button("", systemImage: "info.circle") { toggleSettings() }
        .buttonBorderShape(.circle)
        .buttonStyle(.borderless)
        .labelStyle(.iconOnly)
        .glassBackgroundEffect()
        .hoverEffect(.lift)
    }
    
      .rotation3DEffect(.degrees(flipped ? 180.0 : 0.0), axis: (0, 1, 0), anchor: UnitPoint3D(x: 0.5, y: 0, z: 0))
      
      .frame(idealWidth: 200, idealHeight: 700)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Info", systemImage: "info") { toggleSettings() }
            .buttonBorderShape(.circle)
        }
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
