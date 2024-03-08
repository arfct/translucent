import SwiftUI

struct LaunchView: View {
  @Binding var completed: Bool
  var body: some View {
    ZStack {
      Text(" ")
        .font(.system(size: 200))
        .transition(.opacity)
    }
    .onAppear {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0) {
          completed = true
      }
    }
  }
}


