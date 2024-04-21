import SwiftUI
import SwiftData
import RealityKit
import RealityKitContent

struct AnchoredWidget: Identifiable {
  var widget: Widget
  var anchor: AnchoringComponent.Target
  var transform: Transform
  var id: String
}

struct ImmersiveWidgetView: View {
  @Query(
    sort: \Widget.title
//    filter: #Predicate<Widget> { true }
  )
  var anchoredWidgets: [Widget]

  var body: some View {
    RealityView { content, attachments in
  let _ = print("render", anchoredWidgets)
      
      for anchoredWidget in anchoredWidgets {
        if (!anchoredWidget.isSpatial) {  continue }
        let anchor = AnchorEntity(anchoredWidget.anchor)
        anchor.anchoring.trackingMode = .continuous
        
        if let attachment = attachments.entity(for: anchoredWidget.wid) {
          attachment.transform = anchoredWidget.transform
          
          attachment.setParent(anchor)
        }
        let entity = ModelEntity(mesh: MeshResource.generatePlane(width: 0.02, height:0.02))
        entity.setParent(anchor)
        content.add(anchor)
      }

    } update: { content, attachments in
      
    } attachments: {
      ForEach(anchoredWidgets) { anchoredWidget in
        let _ = print(anchoredWidget.displayName)
        Attachment(id: anchoredWidget.wid) {
          VStack {
            WidgetView(widget: anchoredWidget)
            WindowControls()
          }
        }
      }
    }
  }
}

//#Preview(immersionStyle: .mixed) {
//  let widget = Widget(name: "Test",
//                      location: "https://widget.vision/widgets/orrery.html",
//                      options: "size=360x360")
//  WidgetView(widget: .preview)
//    .frame(maxWidth:360, maxHeight:360)
//  let transform = Transform.init(translation:.init(x: 0, y: 1, z: -3.3))
//  ImmersiveWidgetView(anchoredWidgets: [
//    AnchoredWidget(widget: widget, anchor: .head, transform: transform, id: "test")
//  ])
//}
