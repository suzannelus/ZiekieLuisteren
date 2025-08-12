import SwiftUI
import MusicKit

struct SongView: View {
    let playlist: Playlist
    let initialSongID: String
    
    @StateObject private var playerManager = MusicPlayerManager.shared
    @StateObject private var container = PlaylistsContainer.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isAnimating = false
    @State private var showPlayButton = true
    
    // Get current song with live updates
    private var currentSong: MusicItem? {
        guard let currentPlaylist = container.playlists.first(where: { $0.id == playlist.id }),
              let song = currentPlaylist.songs.first(where: { $0.songID == playerManager.currentlyPlayingSongID ?? initialSongID }) else {
            return playlist.songs.first { $0.songID == initialSongID }
        }
        return song
    }
    
    // Use song's colors if available, otherwise playlist's colors
    private var effectiveColorPalette: ColorPalette {
        currentSong?.colorPalette ?? playlist.effectivePalette
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            VStack {
                RainbowText(text: playlist.name, font: .largeTitle)
                    .lineLimit(1)
                
                
                
                Spacer()
                ZStack {
                    
                    Group {
                        if let song = currentSong {
                            song.displayImage
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } else {
                            Image("Row, Row, Row, Your Boat")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                            
                        }
                    }
                    .padding(80)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(
                        color: effectiveColorPalette.primaryColor.opacity(0.9),
                        radius: 20,
                        x: 0,
                        y: 8
                    )
                    
                    
                    
                }
                
                
                Spacer()
                // Song Title
                Text(currentSong?.title ?? "No Song")
                    .bodyLarge()
                    .padding()
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black)
                    .lineLimit(2)
                
                // Control Buttons - Large and Child-Friendly
                HStack(spacing: 60) {
                    // Previous Button
                    Button(action: previousSong) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(effectiveColorPalette.textColor)
                            .frame(width: 70, height: 70)
                            .background(
                                Circle()
                                    .fill(effectiveColorPalette.backgroundColor.opacity(0.8))
                                    .overlay(
                                        Circle()
                                            .stroke(effectiveColorPalette.primaryColor, lineWidth: 2)
                                    )
                            )
                            .shadow(
                                color: effectiveColorPalette.primaryColor.opacity(0.3),
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                    }
                    .scaleEffect(isAnimating ? 0.95 : 1.0)
                    
                    // Main Play/Pause Button - Extra Large
                    Button(action: playPauseAction) {
                        Image(systemName: playerManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 80, weight: .medium))
                            .foregroundColor(effectiveColorPalette.accentColor)
                            .background(
                                Circle()
                                    .fill(effectiveColorPalette.backgroundColor)
                                    .frame(width: 90, height: 90)
                            )
                            .shadow(
                                color: effectiveColorPalette.accentColor.opacity(0.4),
                                radius: 12,
                                x: 0,
                                y: 6
                            )
                    }
                    .scaleEffect(playerManager.isPlaying ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: playerManager.isPlaying)
                    
                    // Next Button
                    Button(action: nextSong) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(effectiveColorPalette.textColor)
                            .frame(width: 70, height: 70)
                            .background(
                                Circle()
                                    .fill(effectiveColorPalette.backgroundColor.opacity(0.8))
                                    .overlay(
                                        Circle()
                                            .stroke(effectiveColorPalette.primaryColor, lineWidth: 3)
                                    )
                            )
                            .shadow(
                                color: effectiveColorPalette.primaryColor.opacity(0.3),
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                    }
                    .scaleEffect(isAnimating ? 0.95 : 1.0)
                }
                .padding(.horizontal, 40)
                
            }
            .padding(.horizontal, 20)
            
            
            
            
            
            .navigationBarHidden(false)
            .onAppear {
                // Start the background animation
                withAnimation {
                    isAnimating = true
                }
                
                // Start playing the initial song
                Task {
                    await playerManager.playSong(with: initialSongID, in: playlist)
                }
                
                // Hide play button overlay after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        showPlayButton = false
                    }
                }
            }
            .onChange(of: playerManager.currentlyPlayingSongID) { _, _ in
                // Animate color changes when song changes
                withAnimation(.easeInOut(duration: 0.8)) {
                    // Colors will update through effectiveColorPalette
                }
            }
        }
    }
    
    
    // MARK: - Actions
    
    private func playPauseAction() {
        Task {
            await playerManager.togglePlayback()
        }
        
        // Button feedback animation
        withAnimation(.easeInOut(duration: 0.15)) {
            isAnimating.toggle()
        }
    }
    
    private func previousSong() {
        Task {
            await playerManager.playPrevious()
        }
        
        // Button feedback
        withAnimation(.easeInOut(duration: 0.15)) {
            isAnimating.toggle()
        }
    }
    
    private func nextSong() {
        Task {
            await playerManager.playNext()
        }
        
        // Button feedback
        withAnimation(.easeInOut(duration: 0.15)) {
            isAnimating.toggle()
        }
    }
    
}

#Preview {
    let sampleSong = MusicItem(
        songID: "1537827841&l",
        title: "Row Row Row your boat",
        artworkURL: nil,
        customImage: Image("Row, Row, Row Your Boat"),
        imageGenerationConcepts: "Colorful stars in the night sky"
    )
    
    let samplePlaylist = Playlist(
        name: "Nursery Rhymes",
        songs: [sampleSong]
    )
    
    SongView(playlist: samplePlaylist, initialSongID: "test123")
}



