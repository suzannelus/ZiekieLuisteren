import SwiftUI
import MusicKit

struct NowPlayingBar: View {
    @StateObject private var playerManager = MusicPlayerManager.shared
    @ObservedObject private var queue = ApplicationMusicPlayer.shared.queue
    @State private var isShowingSongView = false
    
    var body: some View {
        // Only show the bar when there's a currently playing song
        if let currentSong = playerManager.getCurrentSong() {
            VStack(spacing: 0) {
                // Thin progress bar at the top
                ProgressView(value: playerManager.currentProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                    .scaleEffect(y: 1.5)
                
                HStack(spacing: 12) {
                    // Album artwork
                    Group {
                        if let artwork = queue.currentEntry?.artwork {
                            ArtworkImage(artwork, height: 50)
                                .cornerRadius(6)
                        } else {
                            Image("WheelsOnTheBus") // Your default image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .cornerRadius(6)
                        }
                    }
                    .onTapGesture {
                        isShowingSongView = true
                    }
                    
                    // Song info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentSong.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                        
                        Text(currentSong.artist ?? "Unknown Artist")
                            .font(.caption)
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                    }
                    .onTapGesture {
                        isShowingSongView = true
                    }
                    
                    Spacer()
                    
                    // Play/pause button
                    Button(action: {
                        Task {
                            await playerManager.togglePlayback()
                        }
                    }) {
                        Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Next button (optional)
                    Button(action: {
                        Task {
                            await playerManager.playNext()
                        }
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.title3)
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    // Blurred background effect
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea(.container, edges: .horizontal)
                )
            }
            .overlay(
                // Subtle border
                Rectangle()
                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                    .ignoresSafeArea(.container, edges: .horizontal),
                alignment: .top
            )
            .fullScreenCover(isPresented: $isShowingSongView) {
                if let playlist = playerManager.currentPlaylist,
                   let currentSongID = playerManager.currentlyPlayingSongID {
                    SongView(playlist: playlist, initialSongID: currentSongID)
                }
            }
        }
    }
}

// MARK: - Mini Player Container
struct ContentWithNowPlaying<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            content
            NowPlayingBar()
        }
    }
}