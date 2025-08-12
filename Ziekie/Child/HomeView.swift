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
            ZStack {
                LinearGradient(colors: [.teal.opacity(0.4), .clear], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea(.all)
                VStack {
                    if container.playlists.isEmpty {
                        EmptyPlaylistView()
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: gridColumns) {
                                ForEach(container.playlists) { playlist in
                                    PlaylistGridView(playlist: playlist)
                                }
                            }
                            .padding()
                        }
                        Spacer()
                        
                    }
                    }
                .safeAreaInset(edge: .bottom) {
                    NowPlayingBar()
                }
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
}

struct EmptyPlaylistView: View {
    @StateObject private var parentModeManager = ParentModeManager.shared
    @State private var showingParentView = false
    @State private var showingParentAuth = false

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                
                RainbowText(text: "Tune Gallery", font: .merriweatherResponsive(.largeTitle))
                
                Spacer()
                Text("No playlists yet")
                    .font(.title)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    if parentModeManager.isParentModeActive {
                        parentModeManager.exitParentMode()
                    } else {
                        showingParentAuth = true
                    }
                }) {
                    Label("Create Playlist", systemImage: "plus")
                        .font(.headline)
                }
                .padding()
                .glassEffect(.regular.tint(.pink).interactive())
                Spacer()
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



struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
                        .environment(\.locale, Locale(identifier: "en-US"))
                        .previewDisplayName("English US")
                    
                    HomeView()
                        .environment(\.locale, Locale(identifier: "nl-NL"))
                        .previewDisplayName("Dutch NL")
    }
}
