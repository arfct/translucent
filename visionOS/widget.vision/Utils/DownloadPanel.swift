//
//  DownloadPanel.swift
//  widget.vision
//
//  Created by Nicholas Jitkoff on 3/1/24.
//

import SwiftUI
import RealityKit

struct DownloadPanel: View {
  
  @Environment(\.modelContext) private var modelContext
  @Binding var downloadAttachment: URL?
  
    var body: some View {

            if let url = downloadAttachment {
                Model3D(url: url) { model in
                  VStack(alignment: .center) {
                    HStack() {
                      Text("Drag me.").font(.extraLargeTitle2)
                      Spacer()
                      Button {
                        let widget = Widget(url: url)
                        modelContext.insert(widget)
                        
                      } label: {
                        Label("Add Favorite", systemImage: "star")
                          .labelStyle(.iconOnly)
      
                      }.disabled(true)
                    }.padding()
      
                    Spacer()
                    model
                      .resizable()
                      .aspectRatio(contentMode: .fit)
                      .frame(maxDepth:300)
                      .frame(maxWidth:300, maxHeight: 300)
                      .padding(80)
                  }.padding(20)
                    .onDrag {
                      if let provider = NSItemProvider(contentsOf:url) {
                        provider.suggestedName = url.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "_", with: " ")
      
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                          downloadAttachment = nil
                        }
                        return provider
                      }
                      return NSItemProvider()
                    }
      
                } placeholder: {
                  ProgressView()
                }
                .onTapGesture {
                  downloadAttachment = nil
                }
            }
          
    }
}

//#Preview {
//  DownloadPanel(url:)
//}
