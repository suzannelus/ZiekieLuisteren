//
//  CanvasDottedBackground.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 11/07/2025.
//
import SwiftUI

struct CanvasDottedBackground: View {
    let dotSize: CGFloat = 8
    let spacing: CGFloat = 20
    let dotColor: Color = Color.gray.opacity(0.9)
    
    var body: some View {
        // Random gekleurde dots
        Canvas { context, size in
            let colors: [Color] = [.pink, .blue, .green, .yellow, .purple]
            let spacing: CGFloat = 25
            
            for row in 0..<Int(size.height / spacing) {
                for col in 0..<Int(size.width / spacing) {
                    let randomColor = colors.randomElement() ?? .gray
                    let x = CGFloat(col) * spacing
                    let y = CGFloat(row) * spacing
                    
                    context.fill(
                        Circle().path(in: CGRect(x: x-1, y: y-1, width: 2, height: 2)),
                        with: .color(randomColor.opacity(0.8))
                    )
                }
            }
        }
    }
}


#Preview {
    FloatingClouds()
}




struct Cloud: View {
    @StateObject var provider = CloudProvider()
    @State var move = false
    
    let proxy: GeometryProxy
    let color: Color
    let rotationStart: Double
    let duration: Double
    let alignment: Alignment
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(height: proxy.size.height / provider.frameHeightRatio)
            .offset(provider.offset)
            .rotationEffect(.init(degrees: move ? rotationStart : rotationStart + 360))
            .animation(Animation.linear(duration: duration).repeatForever(autoreverses: false), value: move)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
            .opacity(0.8)
            .onAppear {
                move.toggle()
            }
    }
}

class CloudProvider: ObservableObject {
    let offset: CGSize
    let frameHeightRatio: CGFloat
    
    init() {
        frameHeightRatio = CGFloat.random(in: 0.7 ..< 1.4)
        offset = CGSize(width: CGFloat.random(in: -150 ..< 150),
                        height: CGFloat.random(in: -150 ..< 150))
    }
}

struct FloatingClouds: View {
    let blur: CGFloat = 60
    let colorPalette: ColorPalette
    
    // Default initializer for backward compatibility
    init(colorPalette: ColorPalette = .default) {
        self.colorPalette = colorPalette
    }
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ZStack {
                    Cloud(
                        proxy: proxy,
                        color: colorPalette.primaryColor,
                        rotationStart: 0,
                        duration: 60,
                        alignment: .bottomTrailing
                    )
                    
                    Cloud(
                        proxy: proxy,
                        color: colorPalette.secondaryColor,
                        rotationStart: 240,
                        duration: 50,
                        alignment: .topTrailing
                    )
                    
                    Cloud(
                        proxy: proxy,
                        color: colorPalette.accentColor,
                        rotationStart: 120,
                        duration: 80,
                        alignment: .bottomLeading
                    )
                    
                    Cloud(
                        proxy: proxy,
                        color: colorPalette.primaryColor.opacity(0.6),
                        rotationStart: 180,
                        duration: 70,
                        alignment: .topLeading
                    )
                }
                .blur(radius: blur)
            }
            .ignoresSafeArea()
        }
    }
}




#Preview {
    ZStack {
        // Default colors
        FloatingClouds()
        
        VStack {
            Text("Default Colors")
                .font(.largeTitle)
                .foregroundColor(.primary)
            
            Text("Teal, Mint, Purple, White")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview("Custom Colors") {
    let customPalette = ColorPalette(
        primary: .teal,
        secondary: .mint,
        accent: .pink,
        background: .white,
        text: .black
    )
    
    ZStack {
        FloatingClouds(colorPalette: customPalette)
        
        VStack {
            Text("Custom Colors")
                .font(.largeTitle)
                .foregroundColor(.primary)
            
            Text("Blue, Green, Orange")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}
