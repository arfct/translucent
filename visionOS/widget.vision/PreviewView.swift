import SwiftUI
import RealityKit

struct ManipulationState {
  var transform: AffineTransform3D = .identity
  var active: Bool = false
}

struct PreviewView: View {
  @GestureState var manipulationState = ManipulationState()
  @State var url: URL? = nil;
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.openWindow) private var openWindow
  @Environment(\.dismiss) private var dismiss
  @State var currentPhase: ScenePhase = .active
  @State var wasBackgrounded = false
  
  var manipulationGesture: some Gesture<AffineTransform3D> {
    DragGesture()
      .simultaneously(with: MagnifyGesture())
      .simultaneously(with: RotateGesture3D())
      .map { gesture in
        let (translation, scale, rotation) = gesture.components()
        return AffineTransform3D(
          scale: scale,
          rotation: rotation,
          translation: translation
        )
      }
  }
  
  var body: some View {
    GeometryReader3D { volume in
      if let url = url {
        if url.pathExtension == "usdz" {
          ZStack {
            VStack {} // Ground plane
              .frame(maxWidth:.infinity, maxHeight: .infinity)
              .glassBackgroundEffect().cornerRadius(1000)
              .rotation3DEffect(.degrees(90), axis: (1, 0, 0), anchor: .init(x: 0.5, y: 0, z: 0))
              .offset(y:volume.size.height)
            
            RealityView { content in
              var volumeSize = volume.size
              volumeSize.width /= 1280.0
              volumeSize.height /= 1280.0
              volumeSize.depth /= 1280.0
              
              if let entity = try? await ModelEntity(contentsOf: url) {
                entity.enumerateHierarchy { entity, stop in
                  if entity is ModelEntity { entity.components.set(GroundingShadowComponent(castsShadow: true)) }
                }
                if let model = entity.model {
                  let mesh = model.mesh
                  let size = entity.size()
                  let maxDim = max(size.x, size.y, size.z)
                  
                  if (maxDim > 1.0) {
                    
                    entity.scale /= maxDim
                  }
                  console.log("offset \(-0.5 - model.mesh.bounds.min.y)")
                  entity.position.y -= 0.5
                  entity.position.y -= mesh.bounds.min.y * entity.scale.y
                  
                  
                  //                entity.position.z += 0.4
                  //                entity.position.z -= mesh.bounds.min.z * entity.scale.z
                  
                  content.add(entity)
                }
              }
              
              let ground = ModelEntity(mesh: MeshResource.generatePlane(width: 0.2, depth: 0.2, cornerRadius: 0.1), materials: [SimpleMaterial(color: .blue, roughness: 0.0, isMetallic: true)])
              
              ground.position = .init(x: 0, y: 0, z: 0)
              content.add(ground)
              
              
            }
          } // ZStack
          
          //            .scaleEffect(manipulationState.transform.scale.width)
          //            .rotation3DEffect(manipulationState.transform.rotation ?? .identity)
          //            .gesture(manipulationGesture.updating($manipulationState, body: { value, state, _  in
          //              state.active = true
          //              state.transform = value
          //            }))
          //
          //            .opacity(wasBackgrounded ? 0.0 : 1.0)
          //            .persistentSystemOverlays(!wasBackgrounded ? .automatic : .hidden)
          
          .onDisappear {
            console.log("Dissapear: \(url)")
          }
          .onChange(of: scenePhase) {
            console.log("Preview scenePhase \(scenePhase)")
            if (scenePhase == .active) {
              if (wasBackgrounded) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                  dismiss()
                }
                openWindow(id:WindowID.main)
              }
            }
            if (scenePhase == .background) {
              wasBackgrounded = true
            }
            currentPhase = scenePhase
          }
        } else {
          Text("Unsupported file type")
        }
      }
    }
  }
}

extension SimultaneousGesture<
  SimultaneousGesture<DragGesture, MagnifyGesture>,
  RotateGesture3D>.Value {
    func components() -> (Vector3D, Size3D, Rotation3D) {
      let translation = self.first?.first?.translation3D ?? .zero
      let magnification = self.first?.second?.magnification ?? 1
      let size = Size3D(width: magnification, height: magnification, depth: magnification)
      let rotation = self.second?.rotation ?? .identity
      return (translation, size, rotation)
    }
  }
