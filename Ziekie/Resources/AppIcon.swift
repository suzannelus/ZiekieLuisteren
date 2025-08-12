//
//  AppIcon.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 01/08/2025.
//

import SwiftUI

struct AppIcon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(LinearGradient(colors: [.blue, .purple, .pink], startPoint: .top, endPoint: .bottom))
            RainbowText(text: "🎧", font: .system(size: 100, weight: .bold, design: .default))
                .font(.system(size: 150, weight: .bold, design: .rounded))
            
        }
        .frame(width: 1200, height: 1200)
        
    }
}

#Preview {
    AppIcon()
}
