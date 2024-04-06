import SwiftUI

struct WindowControls: View {
    var body: some View {
      HStack(spacing:24) {
        Circle()
          .frame(width:14, height:14)
          .opacity(0.333)
        RoundedRectangle(cornerRadius:.infinity)
          .frame(maxWidth:136, maxHeight:10)
          .opacity(0.333)
          .hoverEffect()
        Circle()
          .frame(width:14, height:14)
          .opacity(0)
      }.padding(.top, 22).border(.red)
    }
}

#Preview(traits: .fixedLayout(width: 320, height: 180)) {
  WindowControls()
}
