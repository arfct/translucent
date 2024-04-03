import SwiftUI

struct CustomColorPickerView: View {
    
    @Binding var colorValue: Color
    
    var body: some View {
        
        colorValue
            .frame(width: 56, height: 32, alignment: .center)
            .glassBackgroundEffect(in:RoundedRectangle(cornerRadius: 80).inset(by: 5))
            .background {
              RoundedRectangle(cornerRadius: 16).inset(by: 0)
              
                .fill(.shadow(.inner(color:colorValue.opacity(1.0), radius: 0.0, y: 1)))
                .fill(.shadow(.drop(color:.white.opacity(0.9), radius: 0.0, y: 1)))
                .fill(.shadow(.drop(color:.black.opacity(0.9), radius: 0.0, y: -1)))
                .foregroundStyle(.linearGradient(
                  colors: [.black.opacity(0.15),
                           .black.opacity(0.12),
                           .black.opacity(0.05)],
                  startPoint: .top, endPoint: .bottom))

            }
      
            .overlay(ColorPicker("", selection:  $colorValue).labelsHidden().opacity(0.015))
      
    }
}

#Preview {
  VStack{
    CustomColorPickerView(colorValue: .constant(.pink))
    Toggle(isOn: .constant(false)) {
       
    }.labelsHidden()

  }
  .padding(55).background(.linearGradient(colors: [.white, .black], startPoint: .center, endPoint: .center)).glassBackgroundEffect()
}
