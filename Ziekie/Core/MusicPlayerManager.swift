import SwiftUI
import MusicKit

@MainActor
class MusicPlayerManager: ObservableObject {
    static let shared = MusicPlayerManager()
    private let player = SystemMusicPlayer.shared
    
    @Published var currentlyPlayingSongID: String?
    @Published var isPlaying = false
    @Published var errorMessage: String?
    @Published var currentPlaylist: Playlist?
    @Published var playHistory: [String] = [] // Track play history for "previous" logic
    @Published var currentProgress: Double = 0.0 // 0.0 to 1.0
    @Published var currentDuration: TimeInterval = 0.0
    
    private var playStartTime: Date?
    private var currentPlaySession: PlaySession?
    private var currentPlayTask: Task<Void, Never>?
    private var isShowingError = false
    private var progressTimer: Timer?
    
    private init() {}
    
    // ENHANCED: Play song with playlist context
    func playSong(with id: String, in playlist: Playlist) async {
        currentPlayTask?.cancel()
        
        currentPlayTask = Task { @MainActor in
            guard currentlyPlayingSongID != id else {
                print("🎵 Song \(id) is already playing")
                return
            }
            
            print("🎵 Starting playback for song: \(id)")
            
            // Update playlist context
            currentPlaylist = playlist
            
            // Add to history (remove if already exists to avoid duplicates)
            if let currentID = currentlyPlayingSongID {
                playHistory.removeAll { $0 == currentID }
                playHistory.append(currentID)
                // Keep only last 10 for memory efficiency
                if playHistory.count > 10 {
                    playHistory.removeFirst()
                }
            }
            
            let previousSongID = currentlyPlayingSongID
            currentlyPlayingSongID = nil
            isPlaying = false
            
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            guard !Task.isCancelled else { return }
            
            do {
                guard MusicAuthManager.shared.canPlayMusic else {
                    await showError("Apple Music subscription required to play songs")
                    currentlyPlayingSongID = previousSongID
                    return
                }
                
                let songRequest = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: MusicItemID(rawValue: id))
                let response = try await songRequest.response()
                
                guard let song = response.items.first else {
                    await showError("Song not found or no longer available")
                    return
                }
                
                try? await player.stop()
                
                guard !Task.isCancelled else { return }
                
                try await player.queue = [song]
                try await player.play()
                
                guard !Task.isCancelled else { return }
                
                playStartTime = Date()
                currentPlaySession = PlaySession()
                recordPlay(songID: id)
                
                currentlyPlayingSongID = id
                isPlaying = true
                errorMessage = nil
                
                // Get song duration and start progress tracking
                currentDuration = song.duration ?? 0.0
                startProgressTracking()
                
                print("✅ Successfully started playing song: \(id)")
                
            } catch {
                print("❌ Failed to play song \(id): \(error)")
                await showError("Unable to play song: \(error.localizedDescription)")
                currentlyPlayingSongID = nil
                isPlaying = false
            }
        }
    }
    
    // ENHANCED: Get previous song from history
    func getPreviousSong() -> MusicItem? {
        guard let playlist = currentPlaylist,
              let lastPlayedID = playHistory.last else { return nil }
        
        return playlist.songs.first { $0.songID == lastPlayedID }
    }
    
    // ENHANCED: Get next song from playlist order
    func getNextSong() -> MusicItem? {
        guard let playlist = currentPlaylist,
              let currentID = currentlyPlayingSongID,
              let currentIndex = playlist.songs.firstIndex(where: { $0.songID == currentID }) else { return nil }
        
        let nextIndex = (currentIndex + 1) % playlist.songs.count // Loop to first
        return playlist.songs[nextIndex]
    }
    
    // ENHANCED: Get current song
    func getCurrentSong() -> MusicItem? {
        guard let playlist = currentPlaylist,
              let currentID = currentlyPlayingSongID else { return nil }
        
        return playlist.songs.first { $0.songID == currentID }
    }
    
    // NEW: Play previous song
    func playPrevious() async {
        guard let playlist = currentPlaylist,
              let previousSong = getPreviousSong() else { return }
        
        await playSong(with: previousSong.songID, in: playlist)
    }
    
    // NEW: Play next song
    func playNext() async {
        guard let playlist = currentPlaylist,
              let nextSong = getNextSong() else { return }
        
        await playSong(with: nextSong.songID, in: playlist)
    }
    
    // ENHANCED: Progress tracking
    private func startProgressTracking() {
        progressTimer?.invalidate()
        currentProgress = 0.0
        
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self,
                      self.isPlaying,
                      let startTime = self.playStartTime,
                      self.currentDuration > 0 else { return }
                
                let elapsed = Date().timeIntervalSince(startTime)
                self.currentProgress = min(elapsed / self.currentDuration, 1.0)
                
                // Auto-advance when song ends
                if self.currentProgress >= 1.0 {
                    self.progressTimer?.invalidate()
                    await self.playNext()
                }
            }
        }
    }
    
    func togglePlayback() async {
        guard let currentSongID = currentlyPlayingSongID else { return }
        
        do {
            if isPlaying {
                try await player.pause()
                recordPlayPause()
                isPlaying = false
                progressTimer?.invalidate()
                print("⏸️ Paused song: \(currentSongID)")
            } else {
                try await player.play()
                if playStartTime == nil {
                    playStartTime = Date()
                }
                isPlaying = true
                startProgressTracking()
                print("▶️ Resumed song: \(currentSongID)")
            }
        } catch {
            await showError("Unable to toggle playback: \(error.localizedDescription)")
        }
    }
    
    func stopPlayback() async {
        currentPlayTask?.cancel()
        progressTimer?.invalidate()
        
        do {
            try await player.stop()
            currentlyPlayingSongID = nil
            isPlaying = false
            currentProgress = 0.0
            recordPlayPause()
            print("⏹️ Stopped playback")
        } catch {
            print("⚠️ Error stopping playback: \(error)")
        }
    }
    
    private func showError(_ message: String) async {
        guard !isShowingError else { return }
        
        isShowingError = true
        errorMessage = message
        
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run {
                if self.errorMessage == message {
                    self.errorMessage = nil
                }
                self.isShowingError = false
            }
        }
    }
    
    private func recordPlay(songID: String) {
        let container = PlaylistsContainer.shared
        
        for (playlistIndex, playlist) in container.playlists.enumerated() {
            for (songIndex, song) in playlist.songs.enumerated() {
                if song.songID == songID {
                    container.playlists[playlistIndex].songs[songIndex].playCount += 1
                    container.playlists[playlistIndex].songs[songIndex].lastPlayedDate = Date()
                    
                    let newSession = PlaySession()
                    container.playlists[playlistIndex].songs[songIndex].playHistory.append(newSession)
                    
                    saveAnalyticsData()
                    return
                }
            }
        }
    }
    
    private func recordPlayPause() {
        guard let startTime = playStartTime else { return }
        let duration = Int(Date().timeIntervalSince(startTime))
        playStartTime = nil
    }
    
    private func saveAnalyticsData() {
        do {
            let encoded = try JSONEncoder().encode(PlaylistsContainer.shared.playlists)
            UserDefaults.standard.set(encoded, forKey: "LocalPlaylistAnalytics")
        } catch {
            print("Failed to save analytics: \(error.localizedDescription)")
        }
    }
}
