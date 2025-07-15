//
//  WelcomeView.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 13/02/2023.

import SwiftUI
import MusicKit
import Vision

struct WelcomeView: View {
    @StateObject private var authManager = MusicAuthManager.shared
    @State private var appear = false
    @Environment(\.openURL) private var openURL
        
    var body: some View {
        ZStack {
            Background
            ZStack {
                TabView {
                    Accepteer
                    KiesLiedje
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
            Image("Maneschijn")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .shadow(radius: 30)
            Text("Add custom images to playlists and songs")
                .foregroundColor(.accentColor)
                .font(.title3.weight(.medium))
                .multilineTextAlignment(.center)
                .padding([.leading, .trailing], 32)
                .padding(.bottom, 16)
        }
        .padding(30)
      //  .background(.ultraThinMaterial)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke()
            .foregroundStyle(.linearGradient(colors:[.blue.opacity(0.5), .clear, .pink.opacity(0.5), .purple.opacity(0.5), .orange.opacity(0.5), .yellow.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
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
                .clipShape(Circle())
                .glassEffect()
            if let secondaryText = secondaryExplanatoryText {
                secondaryText
            }
            if !authManager.isAuthorized {
                Button(action: handleButtonPressed) {
                    buttonText
                        .padding([.leading, .trailing], 10)
                }
                .buttonStyle(.glass)
                .font(.title3)
               
               //.frame(maxWidth: .infinity)
              //.background(.white.opacity(0.8))
              //  .cornerRadius(10)
                  /*
                        .stroke(.linearGradient(colors:[.blue.opacity(0.5), .clear, .pink.opacity(0.5), .purple.opacity(0.5), .orange.opacity(0.5), .yellow.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing))
                */
                
            }
        }
        .padding(30)
        .glassEffect(.regular)
        .shadow(color: .pink.opacity(0.3), radius: 20, y: 20)
        .padding(20)
        .dynamicTypeSize(.xSmall ... .xxxLarge)
    }
    
   
    
    private var secondaryExplanatoryText: Text? {
        if !authManager.isAuthorized {
            return Text("Give SeeSong access to your ")
                + Text(Image(systemName: "applelogo"))
                + Text("\u{a0}Music library in settings.")
        }
        return nil
    }
    
    private var buttonText: Text {
        Text("Accept")
            
    }
    
    private func handleButtonPressed() {
        Task {
            await authManager.requestAuthorizationWhenNeeded()
        }
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
        .background(
            CanvasDottedBackground()
                .ignoresSafeArea(.all)
        )
       
    }
    
    
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}


