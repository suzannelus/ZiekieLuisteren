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
    
    // ENHANCED: Play song with comprehensive subscription checking
    func playSong(with id: String, in playlist: Playlist) async {
        debugPlaybackAttempt(songID: id)
        
        currentPlayTask?.cancel()
        
        currentPlayTask = Task { @MainActor in
            guard currentlyPlayingSongID != id else {
                print("🎵 Song \(id) is already playing")
                return
            }
            
            print("🎵 Starting playbook for song: \(id)")
            
            // CRITICAL: Check authorization first
            let authManager = MusicAuthManager.shared
            guard authManager.isAuthorized else {
                await showError("Please allow access to Apple Music in Settings")
                return
            }
            
            // CRITICAL: Ensure subscription is loaded
            if authManager.musicSubscription == nil {
                print("🎵 No subscription loaded, requesting authorization...")
                await authManager.requestAuthorizationWhenNeeded()
                
                // Wait a moment for subscription to load
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            }
            
            // ENHANCED: Check if user can play music
            guard authManager.canPlayMusic else {
                if authManager.shouldOfferSubscription {
                    await showError("Apple Music subscription required to play songs")
                    // Automatically show subscription offer
                    authManager.showSubscriptionOffer()
                } else {
                    await showError("Unable to play Apple Music content. Please check your subscription.")
                }
                return
            }
            
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
                // ENHANCED: Song lookup with better error handling
                let songRequest = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: MusicItemID(rawValue: id))
                let response = try await songRequest.response()
                
                guard let song = response.items.first else {
                    await showError("Song not found or no longer available in Apple Music")
                    return
                }
                
                // ENHANCED: Basic playability check using available Song properties
                if song.playParameters == nil {
                    print("⚠️ Song \(id) has no playParameters - may not be playable")
                    // Continue anyway - let MusicKit handle the actual playback attempt
                }
                
                if song.duration == nil || song.duration == 0 {
                    print("⚠️ Song \(id) has no duration - may be unavailable")
                    // Continue anyway - some songs may still be playable
                }
                
                // Stop any current playback
                try? await player.stop()
                
                guard !Task.isCancelled else { return }
                
                // Set up new queue and play
                try await player.queue = [song]
                try await player.play()
                
                guard !Task.isCancelled else { return }
                
                // Success - update state
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
                
                // ENHANCED: Better error handling using available error types
                if let subscriptionError = error as? MusicSubscription.Error {
                    switch subscriptionError {
                    case .permissionDenied:
                        await showError("Please allow access to Apple Music in Settings")
                    case .privacyAcknowledgementRequired:
                        await showError("Please accept Apple Music privacy policy")
                    case .unknown:
                        await showError("Apple Music subscription required")
                        authManager.showSubscriptionOffer()
                    @unknown default:
                        await showError("Unable to play song: \(subscriptionError.localizedDescription)")
                    }
                } else if (error as NSError).domain == "ICError" {
                    // Handle iTunes/iCloud errors
                    await showError("Apple Music subscription required to play songs")
                    authManager.showSubscriptionOffer()
                } else {
                    await showError("Unable to play song: \(error.localizedDescription)")
                }
                
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
        // 🔧 FIX: Always clean up existing timer first
        progressTimer?.invalidate()
        progressTimer = nil
        currentProgress = 0.0
        
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                
                // 🔧 FIX: More robust state checking
                guard self.isPlaying,
                      let startTime = self.playStartTime,
                      self.currentDuration > 0,
                      self.progressTimer != nil else {
                    // Clean up if conditions aren't met
                    self.progressTimer?.invalidate()
                    self.progressTimer = nil
                    return
                }
                
                let elapsed = Date().timeIntervalSince(startTime)
                let newProgress = min(elapsed / self.currentDuration, 1.0)
                
                // 🔧 FIX: Only update if progress actually changed
                if abs(newProgress - self.currentProgress) > 0.01 {
                    self.currentProgress = newProgress
                }
                
                // Auto-advance when song ends
                if self.currentProgress >= 1.0 {
                    self.progressTimer?.invalidate()
                    self.progressTimer = nil
                    
                    // 🔧 FIX: Double-check we're still supposed to be playing
                    guard self.isPlaying else { return }
                    
                    await self.playNext()
                }
            }
        }
    }
    
    func togglePlayback() async {
        guard let currentSongID = currentlyPlayingSongID else { return }
        
        // Check subscription before toggling
        guard MusicAuthManager.shared.canPlayMusic else {
            await showError("Apple Music subscription required")
            return
        }
        
        do {
            if isPlaying {
                // 🔧 FIX 1: Invalidate timer FIRST to prevent race conditions
                progressTimer?.invalidate()
                progressTimer = nil
                
                // 🔧 FIX 2: Reset playStartTime to prevent incorrect calculations
                playStartTime = nil
                
                // 🔧 FIX 3: Set isPlaying = false AFTER timer cleanup
                isPlaying = false
                
                try await player.pause()
                recordPlayPause()
                print("⏸️ Paused song: \(currentSongID)")
                
            } else {
                try await player.play()
                
                // 🔧 FIX 4: Set playStartTime when actually resuming
                playStartTime = Date()
                isPlaying = true
                startProgressTracking()
                print("▶️ Resumed song: \(currentSongID)")
            }
        } catch {
            await showError("Unable to toggle playback: \(error.localizedDescription)")
        }
    }
    
    // 🔧 BONUS: Add this helper method for complete cleanup
    func forceStopTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
        playStartTime = nil
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
    
    
    
    /// Seeks to a specific time in the current song
    func seekTo(time: TimeInterval) async {
        guard currentDuration > 0,
              time >= 0,
              time <= currentDuration else {
            print("⚠️ Invalid seek time or no active player")
            resumeProgressUpdates()
            return
        }
        
        do {
            // More reliable seeking approach for MusicKit
            let wasPlaying = isPlaying
            
            // Stop current playback
            try await player.pause()
            
            // Set the playback time
            player.playbackTime = time
            
            // Update our internal tracking
            playStartTime = Date().addingTimeInterval(-time)
            currentProgress = time / currentDuration
            
            // Resume playback if it was playing before
            if wasPlaying {
                try await player.play()
                isPlaying = true
            }
            
            // Resume progress tracking
            resumeProgressUpdates()
            
            print("✅ Successfully seeked to \(formatTime(time))")
            
        } catch {
            print("❌ Failed to seek: \(error)")
            resumeProgressUpdates()
        }
    }
    
    /// Temporarily pauses for seeking (different from regular pause)
    func pauseForSeeking() async {
        do {
            try await player.pause()
            // Don't change isPlaying state - this is just for seeking
        } catch {
            print("❌ Failed to pause for seeking: \(error)")
        }
    }
    
    /// Pauses progress updates during seeking
    func pauseProgressUpdates() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    /// Resumes progress updates after seeking
    func resumeProgressUpdates() {
        guard isPlaying, progressTimer == nil else { return }
        startProgressTracking()
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(max(0, timeInterval))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// ENHANCED: Debug function with subscription details


extension MusicPlayerManager {
    func debugPlaybackAttempt(songID: String) {
        print("🎵 === Enhanced Playback Debug ===")
        print("🎵 Attempting to play song: \(songID)")
        
        let authManager = MusicAuthManager.shared
        
        // INLINE: Debug auth state without external method dependency
        print("🎵 === MusicKit Debug State ===")
        print("🎵 isAuthorized: \(authManager.isAuthorized)")
        print("🎵 hasInitialized: \(authManager.hasInitialized)")
        
        if let subscription = authManager.musicSubscription {
            print("🎵 musicSubscription: EXISTS")
            print("🎵   - canPlayCatalogContent: \(subscription.canPlayCatalogContent)")
            print("🎵   - canBecomeSubscriber: \(subscription.canBecomeSubscriber)")
            print("🎵   - hasCloudLibraryEnabled: \(subscription.hasCloudLibraryEnabled)")
        } else {
            print("🎵 musicSubscription: NIL")
        }
        
        print("🎵 canPlayMusic: \(authManager.canPlayMusic)")
        print("🎵 shouldOfferSubscription: \(authManager.shouldOfferSubscription)")
        print("🎵 authorizationError: \(authManager.authorizationError ?? "none")")
        
        #if targetEnvironment(simulator)
        print("🎵 Running in SIMULATOR")
        #else
        print("🎵 Running on REAL DEVICE")
        #endif
        print("🎵 === End MusicKit Debug ===")
        
        print("🎵 Final canPlayMusic result: \(authManager.canPlayMusic)")
        
        if !authManager.canPlayMusic {
            print("🎵 ❌ CANNOT PLAY MUSIC")
            if !authManager.isAuthorized {
                print("🎵   Reason: Not authorized")
            } else if authManager.musicSubscription == nil {
                print("🎵   Reason: No subscription object")
            } else if !(authManager.musicSubscription?.canPlayCatalogContent ?? false) {
                print("🎵   Reason: Subscription doesn't allow catalog playback")
                if authManager.musicSubscription?.canBecomeSubscriber ?? false {
                    print("🎵   Note: User can subscribe")
                }
            }
        } else {
            print("🎵 ✅ CAN PLAY MUSIC")
        }
        
        print("🎵 === End Enhanced Playback Debug ===")
    }
}
