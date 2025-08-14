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
    @State private var scrollPosition: Int?
    
    // Get current song with live updates
    private var currentSong: MusicItem? {
        guard let currentPlaylist = container.playlists.first(where: { $0.id == playlist.id }),
              let song = currentPlaylist.songs.first(where: { $0.songID == playerManager.currentlyPlayingSongID ?? initialSongID }) else {
            return playlist.songs.first { $0.songID == initialSongID }
        }
        return song
    }
    
    // Get current song index for carousel
    private var currentSongIndex: Int {
        if let playingID = playerManager.currentlyPlayingSongID,
           let index = playlist.songs.firstIndex(where: { $0.songID == playingID }) {
            return index
        } else if let index = playlist.songs.firstIndex(where: { $0.songID == initialSongID }) {
            return index
        } else {
            return 0
        }
    }
    
    // Use song's colors if available, otherwise playlist's colors
    private var effectiveColorPalette: ColorPalette {
        currentSong?.colorPalette ?? playlist.effectivePalette
    }
    
    // Carousel constants
    private let cardWidth: CGFloat = 280
    private let cardSpacing: CGFloat = 10
    private let sideCardScale: CGFloat = 0.65
    
    var body: some View {
        ZStack {
            // Enhanced background with color transitions (no recreation)
            FloatingClouds(colorPalette: effectiveColorPalette)
                .animation(.easeInOut(duration: 0.4), value: effectiveColorPalette.primaryColor)
            
            VStack(spacing: 40) {
                // Title
                RainbowText(text: playlist.name, font: .largeTitle)
                    .lineLimit(1)
                    .padding(.top, 20)
                
                Spacer()
                
                // Polaroid Carousel - ScrollView approach
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: cardSpacing) {
                            ForEach(Array(playlist.songs.enumerated()), id: \.element.id) { index, song in
                                SongPolaroidCard(
                                    song: song,
                                    scale: index == currentSongIndex ? 1.0 : sideCardScale,
                                    colorPalette: effectiveColorPalette
                                )
                                .frame(width: cardWidth)
                                .animation(.easeInOut(duration: 0.3), value: index == currentSongIndex)
                                .id(index)
                            }
                        }
                        .padding(.horizontal, (UIScreen.main.bounds.width - cardWidth) / 2)
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)
                    .scrollPosition(id: $scrollPosition)
                    .onChange(of: scrollPosition) { _, newPosition in
                        if let newPosition = newPosition, newPosition != currentSongIndex {
                            changeSong(to: newPosition)
                        }
                    }
                    .onChange(of: currentSongIndex) { _, newIndex in
                        if scrollPosition != newIndex {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(newIndex, anchor: .center)
                            }
                        }
                    }
                    .onAppear {
                        scrollPosition = currentSongIndex
                        proxy.scrollTo(currentSongIndex, anchor: .center)
                    }
                }
                
                Spacer()
            }
        }
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
    
    // MARK: - Song Change Handler
    private func changeSong(to newIndex: Int) {
        guard newIndex >= 0 && newIndex < playlist.songs.count else { return }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        let newSong = playlist.songs[newIndex]
        
        Task {
            await playerManager.playSong(with: newSong.songID, in: playlist)
        }
    }
}

// MARK: - Song Polaroid Card Component (renamed to avoid conflicts)
struct SongPolaroidCard: View {
    let song: MusicItem
    let scale: CGFloat
    let colorPalette: ColorPalette
    
    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.8), .white.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
                .shadow(
                    color: .black.opacity(0.18),
                    radius: 24 * scale,
                    x: 0,
                    y: 16 * scale
                )
                .aspectRatio(100/115, contentMode: .fit)
            
            VStack(spacing: 8) {
                // Image
                song.displayImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                
                // Title
                Text(song.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(colorPalette.textColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 16)
            }
        }
        .scaleEffect(scale)
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
