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
    
    var body: some View {
        NavigationStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
                .overlay {
                    if container.playlists.isEmpty {
                        EmptyPlaylistView(showCreation: $showingPlaylistCreation)
                    } else {
                        List {
                            ForEach(container.playlists) { playlist in
                                NavigationLink(value: playlist) {
                                    PlaylistRowView(playlist: playlist)
                                }
                                .listRowBackground(Color.clear)
                            }
                        }
                        .listStyle(.plain)
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

struct PlaylistRowView: View {
    let playlist: Playlist
    
    var body: some View {
        HStack {
            Group {
                if let image = playlist.customImage {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                } else {
                    Image(systemName: "music.note.list")
                        .font(.title)
                        .frame(width: 50, height: 50)
                }
            }
            .cornerRadius(8)
            
            VStack(alignment: .leading) {
                Text(playlist.name)
                    .font(.headline)
                Text("\(playlist.songs.count) songs")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
