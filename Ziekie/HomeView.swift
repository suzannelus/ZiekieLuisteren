//
//  HomeView.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 15/02/2023.
//

import SwiftUI

struct HomeView: View {
    @State private var showingPlaylistCreation = false
    @StateObject private var container = PlaylistsContainer.shared
    
    private static let initialColumns = 2
    
    @State private var gridColumns = Array(repeating: GridItem(.flexible()), count: initialColumns)
    
    var body: some View {
        NavigationStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
                .overlay {
                    if container.playlists.isEmpty {
                        EmptyPlaylistView(showCreation: $showingPlaylistCreation)
                    } else {
                        ScrollView {
                            LazyVGrid(columns: gridColumns) {
                                ForEach(container.playlists) { playlist in
                                    NavigationLink(value: playlist) {
                                        PlaylistGridView(playlist: playlist)
                                    }
                                    .listRowBackground(Color.clear)
                                    .listRowBackground(Color.blue)
                                    //   .background(in: Shape(Circle()).fill(Color.blue))
                                    
                                }
                            }
                        }
                        .padding()
                    }
                }
                .navigationTitle("Playlists")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { showingPlaylistCreation = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
                .navigationDestination(for: Playlist.self) { playlist in
                    Text(playlist.name)
                }
                .sheet(isPresented: $showingPlaylistCreation) {
                    PlaylistCreationSheet()
                }
        }
    }
}

struct EmptyPlaylistView: View {
    @Binding var showCreation: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("No playlists yet")
                .font(.title)
                .foregroundColor(.secondary)
            
            Button(action: { showCreation = true }) {
                Label("Create Playlist", systemImage: "plus")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}



struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
