import SwiftUI


private struct DotView: View {
  @Binding var scale: CGFloat
  
  var body: some View {
    Circle()
      .offset(y:scale * 5)
      .frame(width: 10, height: 10, alignment: .center)
  }
}

struct AnimatedEllipsisView: View {
  @Binding var loading: Bool
  
  @State var animate = false
  
  struct DelayData {
    var delay: TimeInterval
  }
  
  static let DATA = [ DelayData(delay: 0.0), DelayData(delay: 0.2), DelayData(delay: 0.4)]
  
  @State var scales: [CGFloat] = DATA.map { _ in return 0 }
  
  var animation = Animation.easeInOut.speed(0.5)
  
  var body: some View {
    HStack {
      DotView(scale: .constant(scales[0]))
      DotView(scale: .constant(scales[1]))
      DotView(scale: .constant(scales[2]))
    }
    .onAppear {
      animateDots(true)
    }
    .onChange(of: loading) {
      animateDots(loading)
    }
  }
  
  func animateDots(_ animate: Bool) {
    for (index, data) in Self.DATA.enumerated() {
      DispatchQueue.main.asyncAfter(deadline: .now() + data.delay) {
        animateDot(binding: $scales[index], animationData: data, animate: animate)
      }
    }
    
    //Repeat
    if (loading) {
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        animateDots(loading)
      }
    } else {
      
    }
  }
  
  func animateDot(binding: Binding<CGFloat>, animationData: DelayData, animate: Bool) {
    withAnimation(animation) {
      binding.wrappedValue = animate ? -1 : 0
    }
    
    if (!animate) { return }
        
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
      withAnimation(animation) {
        binding.wrappedValue = 1
      }
    }
  }
}

#Preview(windowStyle: .plain) {
  AnimatedEllipsisView(loading: .constant(true))
}
