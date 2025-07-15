import SwiftUI
import MusicKit

struct PlaylistDetailView: View {
    let playlistId: UUID
    @StateObject private var playerManager = MusicPlayerManager.shared
    @StateObject private var container = PlaylistsContainer.shared
    @State private var showingError = false
    
    // Computed property to get the current playlist
    private var playlist: Playlist? {
        container.playlists.first(where: { $0.id == playlistId })
    }
    
    var body: some View {
        ScrollView {
            if let playlist = playlist {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with playlist image and info
                    playlistHeader(playlist)
                    
                    // Songs list
                    LazyVStack(spacing: 8) {
                        ForEach(playlist.songs, id: \.id) { song in
                            // UPDATED: Pass playlist context to SongRow
                            SongRow(musicItems: song, playlist: playlist)
                                .padding(.horizontal)
                        }
                    }
                    
                    
                }
            } else {
                ContentUnavailableView(
                    "Playlist Not Found",
                    systemImage: "music.note.list",
                    description: Text("The playlist you're looking for doesn't exist.")
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(playlist?.name ?? "Playlist")
        .task {
            // Small delay to ensure navigation is stable
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        
        .alert("Playback Error", isPresented: .constant(playerManager.errorMessage != nil)) {
            Button("OK") {
                playerManager.errorMessage = nil
            }
        } message: {
            if let errorMessage = playerManager.errorMessage {
                Text(errorMessage)
            }
        }
        .onAppear {
            print("PlaylistDetailView appeared with \(playlist?.songs.count ?? 0) songs")
        }
    }
    
    @ViewBuilder
    private func playlistHeader(_ playlist: Playlist) -> some View {
        HStack(spacing: 20) {
            Group {
                if let image = playlist.customImage {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Image("WheelsOnTheBus")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
            .frame(width: 120, height: 120)
            .cornerRadius(12)
            .shadow(radius: 5)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(playlist.name)
                    .screenTitle()
                    .lineLimit(2)
                
                Text("\(playlist.songs.count) songs")
                    .caption()
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
    }
    
   
    
}

