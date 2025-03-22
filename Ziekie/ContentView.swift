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
    
    var Bal1: some View {
        Circle()
            .fill(LinearGradient(colors: [Color.accentColor, Color("Background1")], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(Circle()
                .stroke()
                .foregroundStyle(.linearGradient(colors:[.accentColor.opacity(0.5), .clear, .accentColor.opacity(0.5), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .shadow(color: .accentColor.opacity(0.3), radius: 20, y: 20)
            .offset(x:appear ? -20 : 50, y: appear ? 200 : 250)
            .frame(maxWidth: 200)
            .blur(radius: 10)

    }
    
    var Bal2: some View {
        Circle()
            .fill(LinearGradient(colors: [Color.accentColor, Color("TitleTextColor1")], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(Circle()
                .stroke()
                .foregroundStyle(.linearGradient(colors:[.accentColor.opacity(0.5), .clear, .accentColor.opacity(0.5), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .shadow(color: .accentColor.opacity(0.3), radius: 20, y: 20)
            .offset(x:appear ? -60 : -200, y: appear ? -100 : 15)
            .frame(maxWidth: 200)
            .blur(radius: 10)
    }
    var Bal3: some View {
        Circle()
            .fill(LinearGradient(colors: [Color.accentColor, Color("TitleTextColor1")], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(Circle()
                .stroke()
                .foregroundStyle(.linearGradient(colors:[.accentColor.opacity(0.5), .clear, .accentColor.opacity(0.5), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .shadow(color: .accentColor.opacity(0.3), radius: 20, y: 20)
            .offset(x:appear ? 60 : 200, y: appear ? -50 : 15)
            .opacity(appear ? 0.8 : 0.2 )
            .frame(maxWidth: 600)
            .blur(radius: 30)

    }
    
    var Background: some View {
        ZStack {
            LinearGradient(colors: [Color("Background1"), Color("Background2")], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            Bal3
            Bal1
            Bal2
        }
    }
    
    var AppTitel: some View {
        LinearGradient(colors: [Color("TitleTextColor1"), Color("TitleTextColor1")], startPoint: .topLeading, endPoint: .bottomTrailing)
            .frame(width: 300, height: 100)
            .mask(Text("Ziekie Luisteren".uppercased())
                .font(.largeTitle.width(.condensed))
                .fontWeight(.bold))
    }
    
    var KiesLiedje: some View {
        VStack {
            AppTitel
            Image("Maneschijn")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .shadow(radius: 30)
            Text("Laat je kinderen zelf kiezen welk liedje ze willen horen door op de beschrijvende afbeeldingen te tikken")
                .foregroundColor(.accentColor)
                .font(.title3.weight(.medium))
                .multilineTextAlignment(.center)
                .padding([.leading, .trailing], 32)
                .padding(.bottom, 16)
        }
        .padding(30)
        .background(.ultraThinMaterial)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke()
            .foregroundStyle(.linearGradient(colors:[.accentColor.opacity(0.5), .clear, .accentColor.opacity(0.5), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .shadow(color: .accentColor.opacity(0.3), radius: 20, y: 20)
        .frame(maxWidth: 500)
        .padding(20)
        .dynamicTypeSize(.xSmall ... .xxxLarge)
    }
    
    var Accepteer: some View {
        VStack {
            AppTitel
            Image("DikkertjeDap")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .shadow(radius: 30)
            explanatoryText
            if let secondaryText = secondaryExplanatoryText {
                secondaryText
            }
            if !authManager.isAuthorized {
                Button(action: handleButtonPressed) {
                    buttonText
                        .padding([.leading, .trailing], 10)
                }
                .font(.title3)
                .padding(.all)
                .frame(maxWidth: .infinity)
                .background(.white.opacity(0.2).gradient)
                .cornerRadius(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke()
                        .foregroundStyle(.linearGradient(colors:[.accentColor.opacity(0.5), .clear, .accentColor.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing))
                )
            }
        }
        .padding(30)
        .background(.ultraThinMaterial)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke()
            .foregroundStyle(.linearGradient(colors:[.accentColor.opacity(0.5), .clear, .accentColor.opacity(0.5), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .shadow(color: .accentColor.opacity(0.3), radius: 20, y: 20)
        .frame(maxWidth: 500)
        .padding(20)
        .dynamicTypeSize(.xSmall ... .xxxLarge)
    }
    
    private var explanatoryText: some View {
        Text("Ziekie Luisteren maakt gebruik van ")
            + Text(Image(systemName: "applelogo"))
            + Text("\u{a0}Music zodat het niet met jouw Spotify algoritme in de war raakt.")
    }
    
    private var secondaryExplanatoryText: Text? {
        if !authManager.isAuthorized {
            return Text("Geef Ziekie Luisteren toestemming om")
                + Text(Image(systemName: "applelogo"))
                + Text("\u{a0}Music in Instellingen.")
        }
        return nil
    }
    
    private var buttonText: Text {
        Text("Accepteer")
    }
    
    private func handleButtonPressed() {
        Task {
            await authManager.checkAuthorizationStatus()
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
