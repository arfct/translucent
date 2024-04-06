import SwiftUI
import RealityKit
import RealityKitContent

struct AnchoredWidget: Identifiable {
  var widget: Widget
  var anchor: AnchoringComponent.Target
  var transform: Transform
  var id: String
}

struct ImmersiveWidgetView: View {
  @State var anchoredWidgets = [AnchoredWidget]()
  
  var body: some View {
    RealityView { content, attachments in
      
      for anchoredWidget in anchoredWidgets {
        let anchor = AnchorEntity(anchoredWidget.anchor)
        anchor.anchoring.trackingMode = .continuous
        
        if let attachment = attachments.entity(for: anchoredWidget.id) {
          attachment.transform = anchoredWidget.transform
          
          attachment.setParent(anchor)
        }
        let entity = ModelEntity(mesh: MeshResource.generatePlane(width: 0.1, height:0.1))
        entity.setParent(anchor)
        content.add(anchor)
      }

    } update: { content, attachments in
      
    } attachments: {
      ForEach(anchoredWidgets) { anchoredWidget in
        Attachment(id: "id") {
          VStack {
            WidgetView(widget: anchoredWidget.widget)
              .cornerRadius(180)
              .frame(maxWidth:360, maxHeight:360)
            WindowControls()
          }
        }
      }
    }
  }
}

#Preview(immersionStyle: .mixed) {
  let widget = Widget(name: "Test",
         location: "https://widget.vision/widgets/orrery.html",
         options: "size=360x360")
  WidgetView(widget: .preview)
    .cornerRadius(180)
    .frame(maxWidth:360, maxHeight:360)
  let transform = Transform.init(translation:.init(x: 0, y: 1, z: -3.3))
  ImmersiveWidgetView(anchoredWidgets: [
    AnchoredWidget(widget: widget, anchor: .head, transform: transform, id: "test")
  ])
}
