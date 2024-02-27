import SwiftUI
import RealityKit

struct ManipulationState {
  var transform: AffineTransform3D = .identity
  var active: Bool = false
}

struct PreviewView: View {
  @GestureState var manipulationState = ManipulationState()
  @State var url: URL? = nil;
  
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
    if let url = url {
      if url.pathExtension == "usdz" {
        ZStack(alignment: .bottom) {
          Model3D(url: url) { phase in
            switch phase {
            case .empty:
              ProgressView()
            case let .failure(error):
              Text(error.localizedDescription)
            case let .success(model):
              model
                .resizable()
                .aspectRatio(contentMode: .fit)
            default:
              Text("Status Unknown")
            }
          }
          .scaleEffect(manipulationState.transform.scale.width)
          .rotation3DEffect(manipulationState.transform.rotation ?? .identity)
          .gesture(manipulationGesture.updating($manipulationState, body: { value, state, _  in
            state.active = true
            state.transform = value
          }))
        }
        .frame(alignment: .front)

      } else {
        Text("Unsupported file type")
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
