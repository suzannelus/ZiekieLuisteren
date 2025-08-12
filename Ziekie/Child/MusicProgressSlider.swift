//
//  MusicProgressSlider.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 29/07/2025.
//


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
