import SwiftUI
import MusicKit

struct MusicProgressSlider: View {
    @StateObject private var playerManager = MusicPlayerManager.shared
    @State private var isSeekingActive = false
    @State private var seekPosition: Double = 0.0
    
    var body: some View {
        VStack(spacing: 12) {
            // Time labels
            HStack {
                Text(formatTime(currentDisplayTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit() // Prevents jumping when numbers change
                
                Spacer()
                
                Text(formatTime(playerManager.currentDuration))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            
            // Progress slider
            Slider(
                value: Binding(
                    get: {
                        if isSeekingActive {
                            return seekPosition
                        } else {
                            return playerManager.currentProgress
                        }
                    },
                    set: { newValue in
                        seekPosition = newValue
                    }
                ),
                in: 0...1,
                onEditingChanged: { editing in
                    if editing {
                        // User started dragging
                        isSeekingActive = true
                        // Pause timer updates to prevent conflicts
                        playerManager.pauseProgressUpdates()
                        
                        // Optional: Pause playback while seeking for better UX
                        if playerManager.isPlaying {
                            Task {
                                await playerManager.pauseForSeeking()
                            }
                        }
                    } else {
                        // User finished dragging - seek to new position
                        let targetTime = seekPosition * playerManager.currentDuration
                        Task {
                            await playerManager.seekTo(time: targetTime)
                            isSeekingActive = false
                        }
                    }
                }
            )
            .tint(.accentColor)
        }
    }
    
    private var currentDisplayTime: TimeInterval {
        if isSeekingActive {
            return seekPosition * playerManager.currentDuration
        } else {
            return playerManager.currentProgress * playerManager.currentDuration
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(max(0, timeInterval))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - MusicPlayerManager Extensions for Seeking

extension MusicPlayerManager {
    
    /// Seeks to a specific time in the current song
    func seekTo(time: TimeInterval) async {
        guard let player = player,
              currentDuration > 0,
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
        guard let player = player else { return }
        
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