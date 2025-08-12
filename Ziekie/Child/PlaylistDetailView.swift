import SwiftUI
import MusicKit
import Foundation

struct PlaylistDetailView: View {
    let playlistId: UUID
    @StateObject private var playerManager = MusicPlayerManager.shared
    @StateObject private var container = PlaylistsContainer.shared
    @State private var showingError = false
    
   
    
    // Computed property to get the current playlist
    private var playlist: Playlist? {
        container.playlists.first(where: { $0.id == playlistId })
    }
    
    private let adaptiveColumn = [
            GridItem(.adaptive(minimum: 150))
        ]
    
    var body: some View {
        NavigationView {
            
            ScrollView {
                
                //   .offset(y: getOffsetForHeader())
                VStack(spacing: 0) {
                    if let playlist = playlist {
                        VStack(alignment: .leading, spacing: 20) {
                            // Header with playlist image and info
                            playlistHeader(playlist)
                            
                            
                            ScrollView {
                                // Songs list
                                
                                LazyVGrid(columns: adaptiveColumn, spacing: 8) {
                                    ForEach(playlist.songs, id: \.id) { song in
                                        // UPDATED: Pass playlist context to SongRow
                                        SongRow(musicItems: song, playlist: playlist)
                                            .id("\(song.id)-\(song.customImage != nil)-\(playlist.id)")
                                    }
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
            }
        }
        .navigationBarTitleDisplayMode(.inline)
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
                RainbowText(text: playlist.name, font: .merriweatherResponsive(.largeTitle))
                    .lineLimit(2)

                
                Text("\(playlist.songs.count) songs")
                    .bodyLarge()
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            Spacer()
        }
        .padding()
    }
    
   
    
}



#Preview {
    let mockPlaylist = Playlist(
        name: "Kids Songs",
        songs: [
            MusicItem(songID: "1", title: "Wheels on the Bus"),
            MusicItem(songID: "2", title: "Twinkle Twinkle")
        ]
    )
    
    // Add the playlist to the container so the view can find it
    let _ = {
        PlaylistsContainer.shared.playlists = [mockPlaylist]
    }()
    
    return PlaylistDetailView(playlistId: mockPlaylist.id)
}


