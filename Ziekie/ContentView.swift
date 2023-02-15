//
//  ContentView.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 13/02/2023.

import SwiftUI

struct ContentView: View {
    
    @State var showMenu = false
    @AppStorage("selectedMenu") var selectedMenu: Menu = .compass
    @GestureState var press = false
    
    
    var longPress: some Gesture {
        LongPressGesture(minimumDuration: 1)
            .updating($press) { currentState, GestureState, transaction in
                GestureState = currentState
            }
            .onEnded { value in
                showMenu = true
            }
    }
    
    var body: some View {
        
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            switch selectedMenu {
            case .compass:
                MessageView()
            case .card:
                CardReflectionView()
            case .charts:
                DetailView()
            case .radial:
                RadialLayoutView()
            case .halfsheet:
                MenuView()
            case .gooey:
                Text("gooey")
            case .actionbutton:
                Text("action")
            }
        }
        .onTapGesture { }
        .gesture(longPress)
        .sheet(isPresented: $showMenu) {
            MenuView()
                .presentationDetents([.medium, .large])
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
