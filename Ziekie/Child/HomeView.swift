//
//  HomeView.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 15/02/2023.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var parentModeManager = ParentModeManager.shared

    @State private var showingParentView = false
    @State private var showingsSubscriptionStatusView = false
    @StateObject private var container = PlaylistsContainer.shared
    @State private var showingParentAuth = false
    
    private static let initialColumns = 2
    @State private var gridColumns = Array(repeating: GridItem(.flexible()), count: initialColumns)
    
    
    
    var body: some View {
        NavigationStack {
            Color.white
                .overlay {
                    if container.playlists.isEmpty {
                        EmptyPlaylistView(showCreation: $showingParentView)
                    } else {
                        ScrollView {
                                LazyVGrid(columns: gridColumns) {
                                    ForEach(container.playlists) { playlist in
                                        PlaylistGridView(playlist: playlist)
                                    }
                                }
                                .padding()
                        }
                        VStack {
                            VStack {
                                Text("Recently played")
                                Divider()
                                Text("Recently added")
                            }
                        }
                    }
                }
                .navigationTitle("Tune Gallery")
                .appTitle()
                .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button(action: {
                                    if parentModeManager.isParentModeActive {
                                        parentModeManager.exitParentMode()
                                    } else {
                                        showingParentAuth = true
                                    }
                                }) {
                                    Image(systemName: parentModeManager.isParentModeActive ? "lock.fill" : "info")
                                        .foregroundColor(parentModeManager.isParentModeActive ? .orange : .primary)
                                }
                            }
                        }
                        .sheet(isPresented: $showingParentAuth) {
                            ParentAuthenticationView {
                                showingParentAuth = false
                                parentModeManager.enterParentMode()
                            }
                        }
                        .fullScreenCover(isPresented: $parentModeManager.isParentModeActive) {
                            ParentPlaylistManagerView()
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
