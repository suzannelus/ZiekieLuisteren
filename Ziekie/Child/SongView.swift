import SwiftUI
import MusicKit

struct SongView: View {
    let playlist: Playlist
    let initialSongID: String
    
    @StateObject private var playerManager = MusicPlayerManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var currentCardIndex: Int = 0
    @State private var dragOffset: CGSize = .zero
    @State private var isAnimating = false
    
    private var songs: [MusicItem] {
        playlist.songs
    }
    
    private var currentSongIndex: Int {
        songs.firstIndex { $0.songID == initialSongID } ?? 0
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color("Background1"), Color("Background2")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Navigation Header
                    HStack {
                        Button(action: { dismiss() }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundColor(.accentColor)
                        }
                        
                        Spacer()
                        
                        Text(playlist.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Invisible spacer to center the title
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                        }
                        .opacity(0)
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Card Stack
                    ZStack {
                        // Previous Card (-1)
                        if let previousSong = playerManager.getPreviousSong() {
                            SongCard(
                                song: previousSong,
                                size: .small,
                                position: .leading
                            )
                            .offset(x: -120 + dragOffset.width * 0.3)
                            .scaleEffect(0.8)
                            .opacity(0.6)
                        }
                        
                        // Current Card (0)
                        if let currentSong = playerManager.getCurrentSong() {
                            SongCard(
                                song: currentSong,
                                size: .large,
                                position: .center
                            )
                            .offset(x: dragOffset.width * 0.8)
                            .scaleEffect(1.0 - abs(dragOffset.width) / 1000)
                            .opacity(1.0 - abs(dragOffset.width) / 400.0)
                        }
                        
                        // Next Card (+1)
                        if let nextSong = playerManager.getNextSong() {
                            SongCard(
                                song: nextSong,
                                size: .small,
                                position: .trailing
                            )
                            .offset(x: 120 + dragOffset.width * 0.3)
                            .scaleEffect(0.8)
                            .opacity(0.6)
                        }
                    }
                    .frame(height: 400)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                guard !isAnimating else { return }
                                dragOffset = value.translation
                            }
                            .onEnded { value in
                                guard !isAnimating else { return }
                                
                                let threshold: CGFloat = 100
                                
                                if value.translation.width > threshold {
                                    // Swipe right - go to previous
                                    swipeToPrevious()
                                } else if value.translation.width < -threshold {
                                    // Swipe left - go to next
                                    swipeToNext()
                                } else {
                                    // Snap back to center
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                        dragOffset = .zero
                                    }
                                }
                            }
                    )
                    
                    Spacer()
                    
                    // Progress Bar
                    VStack(spacing: 12) {
                        HStack {
                            Text(formatTime(playerManager.currentProgress * playerManager.currentDuration))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(formatTime(playerManager.currentDuration))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        ProgressView(value: playerManager.currentProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                            .scaleEffect(y: 2.0)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Start playing the initial song
            Task {
                await playerManager.playSong(with: initialSongID, in: playlist)
            }
        }
    }
    
    private func swipeToPrevious() {
        guard playerManager.getPreviousSong() != nil else {
            // Snap back if no previous song
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                dragOffset = .zero
            }
            return
        }
        
        isAnimating = true
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            dragOffset = CGSize(width: 400, height: 0)
        }
        
        Task {
            await playerManager.playPrevious()
            
            // Reset animation after a delay
            try? await Task.sleep(nanoseconds: 300_000_000)
            await MainActor.run {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    dragOffset = .zero
                }
                isAnimating = false
            }
        }
    }
    
    private func swipeToNext() {
        guard playerManager.getNextSong() != nil else {
            // Snap back if no next song
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                dragOffset = .zero
            }
            return
        }
        
        isAnimating = true
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            dragOffset = CGSize(width: -400, height: 0)
        }
        
        Task {
            await playerManager.playNext()
            
            // Reset animation after a delay
            try? await Task.sleep(nanoseconds: 300_000_000)
            await MainActor.run {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    dragOffset = .zero
                }
                isAnimating = false
            }
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Song Card Component
struct SongCard: View {
    let song: MusicItem
    let size: CardSize
    let position: CardPosition
    
    enum CardSize {
        case small, large
    }
    
    enum CardPosition {
        case leading, center, trailing
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Song Image
            Group {
                if let customImage = song.customImage {
                    customImage
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else if let artworkURL = song.artworkURL {
                    AsyncImage(url: artworkURL) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        case .failure(_):
                            Image(systemName: "music.note.list")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)
                        @unknown default:
                            Image(systemName: "music.note.list")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: cardWidth, height: cardWidth)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            
            // Song Title (only for large card)
            if size == .large {
                Text(song.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .foregroundColor(.primary)
            }
        }
    }
    
    private var cardWidth: CGFloat {
        switch size {
        case .small: return 120
        case .large: return 280
        }
    }
}

#Preview {
    SongView(
        playlist: Playlist(name: "Test Playlist", songs: []),
        initialSongID: "test"
    )
}
