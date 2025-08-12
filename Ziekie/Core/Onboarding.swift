//
//  WelcomeView.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 13/02/2023.

import SwiftUI
import MusicKit

struct WelcomeView: View {
    @StateObject private var authManager = MusicAuthManager.shared
    @State private var appear = false
    @Environment(\.openURL) private var openURL
        
    var body: some View {
        ZStack {
            Background
            ZStack {
                TabView {
                    KiesLiedje
                    Accepteer
                }
                .tabViewStyle(PageTabViewStyle())
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 10)) {
                appear = true
            }
        }
    }
        
    var AppTitel: some View {
        Text("Tune Gallery")
            .appTitle()
            .fontWeight(.bold)
            .foregroundStyle(Color.accentColor)
    }
    
    var KiesLiedje: some View {
        VStack {
            AppTitel
            ZStack(alignment: .top) {
                Image("If You're Happy and You Know it")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(10)
                    .shadow(radius: 30)
                    .glassEffect()
                Text("If you're happy and you know it")
                    .bodyLarge()
                    .italic()
                    .padding(6)
                    .cornerRadius(10)
                    .background(Color.white.opacity(0.6))
            }
            Text("Add custom images to playlists and songs")
                .foregroundColor(.accentColor)
                .bodyLarge()
                .multilineTextAlignment(.center)
                .padding([.leading, .trailing], 32)
                .padding(.bottom, 16)
        }
        .padding(30)
        .glassEffect(.regular)
        .padding(20)
      //  .background(.ultraThinMaterial)
        .cornerRadius(10)
        .buttonStyle(.glass)
        .shadow(color: .pink.opacity(0.3), radius: 20, y: 20)
        .frame(maxWidth: 500)
        .padding(20)
        .dynamicTypeSize(.xSmall ... .xxxLarge)
        
    }
    
    var Accepteer: some View {
        VStack {
            AppTitel
            
            Image("TimothySong")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .cornerRadius(10)
                .shadow(radius: 30)
                .glassEffect()
           
           
               //.frame(maxWidth: .infinity)
              //.background(.white.opacity(0.8))
              //  .cornerRadius(10)
                  /*
                        .stroke(.linearGradient(colors:[.blue.opacity(0.5), .clear, .pink.opacity(0.5), .purple.opacity(0.5), .orange.opacity(0.5), .yellow.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing))
                */
                
            }
        
        .padding(30)
        .glassEffect(.regular)
        .shadow(color: .pink.opacity(0.3), radius: 20, y: 20)
        .padding(20)
        .dynamicTypeSize(.xSmall ... .xxxLarge)
    }
    
   
  
    var Bal1: some View {
        Circle()
            .fill(LinearGradient(colors: [Color.teal, Color.mint], startPoint: .topLeading, endPoint: .bottomTrailing))
            .shadow(color: .teal.opacity(0.3), radius: 20, y: 20)
            .offset(x:appear ? -20 : 50, y: appear ? 500 : 250)
            .blur(radius: 5)

    }
    
    var Bal2: some View {
        Circle()
            .fill(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
            .shadow(color: .accentColor.opacity(0.3), radius: 20, y: 20)
            .offset(x:appear ? -60 : -200, y: appear ? -100 : 15)
            .blur(radius: 10)
    }
    var Bal3: some View {
        Circle()
            .fill(LinearGradient(colors: [Color.orange, Color.pink], startPoint: .topLeading, endPoint: .bottomTrailing))
            .shadow(color: .accentColor.opacity(0.3), radius: 20, y: 20)
            .offset(x:appear ? 60 : 200, y: appear ? -50 : 150)
            .opacity(appear ? 0.8 : 0.2 )
            .blur(radius: 30)

    }
    
    var Background: some View {
        ZStack {
            Bal3
            Bal1
            Bal2
            
        }
        
    }
    
    
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}



//
//  GradientOrb.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 11/08/2025.
//


import SwiftUI

// MARK: - Signature Colors
extension LinearGradient {
    static let tealMint = LinearGradient(
        colors: [Color(#colorLiteral(red: 0.0, green: 0.754, blue: 0.694, alpha: 1)),
                 Color(#colorLiteral(red: 0.675, green: 0.949, blue: 0.855, alpha: 1))],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let bluePurple = LinearGradient(
        colors: [Color(#colorLiteral(red: 0.223, green: 0.54, blue: 0.996, alpha: 1)),
                 Color(#colorLiteral(red: 0.53, green: 0.33, blue: 0.96, alpha: 1))],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let orangePink = LinearGradient(
        colors: [Color(#colorLiteral(red: 1.0, green: 0.58, blue: 0.33, alpha: 1)),
                 Color(#colorLiteral(red: 1.0, green: 0.42, blue: 0.63, alpha: 1))],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}


// MARK: - Gradient Orb
struct GradientOrb: View {
    var gradient: LinearGradient
    var size: CGFloat
    var blur: CGFloat = 22
    var body: some View {
        Circle()
            .fill(gradient)
            .frame(width: size, height: size)
            .blur(radius: blur)
            .overlay(
                Circle().stroke(.white.opacity(0.05), lineWidth: 1)
                    .blur(radius: 2)
            )
            .opacity(0.85)
    }
}

// MARK: - Glass Music Note (SF Symbol stylized)
struct GlassMusicNote: View {
    var symbol: String = "music.note"
    var size: CGFloat = 64
    var rotation: Angle = .degrees(0)
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size/3)
                .fill(.clear)
                .frame(width: size, height: size) // invisible alignment helper
                .opacity(0)
            Image(systemName: symbol)
                .font(.system(size: size, weight: .regular))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.white.opacity(0.65))
              
                .rotationEffect(rotation)
        }

    }
}

// MARK: - "In de maneschijn" image holder
struct ManeschijnImage: View {
    var body: some View {
        Image("In de Manenschijn")
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.white.opacity(0.25), lineWidth: 1)
            )
    }
}




// MARK: - Polaroid Card
struct PolaroidCard: View {
    var body: some View {
        ZStack(alignment: .top) {
           
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(
                            LinearGradient(colors: [.white.opacity(0.8), .white.opacity(0.2)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1.2
                        )
                )
                .shadow(color: .black.opacity(0.18), radius: 24, x: 0, y: 16)
                .aspectRatio(100/115, contentMode: .fit)
            ManeschijnImage()
                   .padding(18)
                
        }
        .rotationEffect(.degrees(-10))
        .padding()
        
    }
}

// MARK: - Main View
struct OnboardingPolaroidIconView: View {
    @State private var floatPhase: CGFloat = 0
    
    var body: some View {
        ZStack {
            
            // Gradient orbs (teal/mint, blue/purple, orange/pink)
            ZStack {
                GradientOrb(gradient: .tealMint, size: 220, blur: 28)
                    .offset(x: -120, y: -190)
                    .opacity(0.85)
                GradientOrb(gradient: .bluePurple, size: 260, blur: 30)
                    .offset(x: 120, y: -40)
                    .opacity(0.9)
                GradientOrb(gradient: .orangePink, size: 230, blur: 30)
                    .offset(x: 40, y: 200)
                    .opacity(0.9)
            }
          
            
            // Content
            ZStack {
                PolaroidCard()
                    .padding()
                
                // Floating glass music notes
                GlassMusicNote(symbol: "music.note", size: 64, rotation: .degrees(0))
                    .offset(x: -120, y: -80)
                    .opacity(0.95)
                    .scaleEffect(1.0 + 0.02 * sin(floatPhase))
                
                GlassMusicNote(symbol: "music.note", size: 70, rotation: .degrees(14))
                    .offset(x: 140, y: -30)
                    .opacity(0.95)
                    .scaleEffect(1.0 + 0.02 * cos(floatPhase * 1.3))
                
                GlassMusicNote(symbol: "music.note", size: 54, rotation: .degrees(-8))
                    .offset(x: -40, y: 160)
                    .opacity(0.9)
                    .scaleEffect(1.0 + 0.02 * sin(floatPhase * 0.9))
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                floatPhase = .pi * 2
            }
        }
    }
}

// MARK: - Preview
#Preview {
    OnboardingPolaroidIconView()
}
