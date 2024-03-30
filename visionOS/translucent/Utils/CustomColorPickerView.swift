import SwiftUI

struct CustomColorPickerView: View {
    
    @Binding var colorValue: Color
    
    var body: some View {
        
        colorValue
            .frame(width: 48, height: 32, alignment: .center)
            
            
  
                        
            .shadow(radius: 5.0)
            .glassBackgroundEffect(in:RoundedRectangle(cornerRadius: 8).inset(by: 4))
            .background(RoundedRectangle(cornerRadius: 8.0).fill(.regularMaterial).stroke(.tertiary, style: StrokeStyle(lineWidth: 1)))
            .overlay(ColorPicker("", selection:  $colorValue).labelsHidden().opacity(0.015))
 
    }
}

#Preview {
  CustomColorPickerView(colorValue: .constant(.pink))
}
