//
//  HomeView.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 15/02/2023.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack {
            
            NavigationStack {
                VStack {
                    List(musicItems) { item in
                        NavigationLink(value: item) {
                            SongRow(musicItems: item)
                        }
                        .navigationTitle("Kies een liedje")
                        .navigationBarTitleDisplayMode(.automatic)
                        .navigationDestination(for: MusicItem.self) { item in
                            SongView(musicItems: item)
                        }
                        .listRowBackground(Color.accentColor.opacity(0.0))
                    }
                    .scrollContentBackground(.hidden)
                    .background(LinearGradient(colors: [Color("Background1"), Color("Background2")], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .ignoresSafeArea())
                }
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
