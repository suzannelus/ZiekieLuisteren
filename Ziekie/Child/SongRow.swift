//
//  SongRow.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 17/02/2023.
//

import SwiftUI
import MusicKit

struct SongRow: View {
    let musicItems: MusicItem
    let playlist: Playlist
    @StateObject private var playerManager = MusicPlayerManager.shared
    
    // Computed properties for cleaner state management
    private var isThisSongSelected: Bool {
        playerManager.currentlyPlayingSongID == musicItems.songID
    }
    
    private var isThisSongPlaying: Bool {
        isThisSongSelected && playerManager.isPlaying
    }
    
    // Use song's colors if available, otherwise playlist's colors
    private var effectiveColorPalette: ColorPalette {
        musicItems.colorPalette ?? playlist.effectivePalette
    }
    
    var body: some View {
        NavigationLink(destination: SongView(playlist: playlist, initialSongID: musicItems.songID)) {
            VStack(spacing: 8) {
                // Song Artwork
                Group {
                    if let customImage = musicItems.customImage {
                        customImage
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else if let artworkURL = musicItems.artworkURL {
                        AsyncImage(url: artworkURL) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .tint(effectiveColorPalette.primaryColor)
                                
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure(_):
                                Image("WheelsOnTheBus")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                
                            @unknown default:
                                Image("WheelsOnTheBus")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            }
                        }
                    } else {
                        Image("WheelsOnTheBus")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                        
                    }
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)
                .background(effectiveColorPalette.backgroundColor.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            effectiveColorPalette.primaryColor.opacity(0.2),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: effectiveColorPalette.primaryColor.opacity(0.1),
                    radius: 2,
                    x: 0,
                    y: 1
                )
                
                // Song Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(musicItems.title)
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundColor(effectiveColorPalette.textColor)
                    
                    // Play count or additional info
                    if musicItems.playCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "play.circle.fill")
                                .font(.caption)
                                .foregroundColor(effectiveColorPalette.accentColor)
                            
                            Text("Played \(musicItems.playCount) times")
                                .font(.caption)
                                .foregroundColor(effectiveColorPalette.secondaryColor)
                        }
                    } else {
                        Text("Tap to play")
                            .font(.caption)
                            .foregroundColor(effectiveColorPalette.secondaryColor.opacity(0.8))
                    }
                }
                
                Spacer()
                
                // Playing indicator
                if isThisSongSelected {
                    PlayingIndicator(
                        isPlaying: isThisSongPlaying,
                        palette: effectiveColorPalette
                    )
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(effectiveColorPalette.secondaryColor.opacity(0.6))
            }
            .padding(.vertical, 4)
            .background(
                // Subtle background highlight when song is selected
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isThisSongSelected ?
                        effectiveColorPalette.primaryColor.opacity(0.05) :
                            Color.clear
                    )
            )
            .overlay(
                // Accent border when playing
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isThisSongPlaying ?
                        effectiveColorPalette.accentColor.opacity(0.3) :
                            Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isThisSongSelected)
        .animation(.easeInOut(duration: 0.2), value: isThisSongPlaying)
    }
}


struct PlayingIndicator: View {
    let isPlaying: Bool
    let palette: ColorPalette
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Background circle
                Circle()
                    .fill(palette.accentColor.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                // Icon with subtle animation
                Image(systemName: isPlaying ? "speaker.wave.2.fill" : "pause.fill")
                    .font(.caption)
                    .foregroundColor(palette.accentColor)
                    .scaleEffect(isPlaying ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isPlaying)
            }
            
            Text(isPlaying ? "Playing" : "Paused")
                .font(.caption2)
                .foregroundColor(palette.accentColor)
                .fontWeight(.medium)
        }
        .scaleEffect(isPlaying ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isPlaying)
    }
}

#Preview {
    let sampleSong = MusicItem(
        songID: "test123",
        title: "Test Song",
        artworkURL: nil,
        palette: ColorPalette(
            primary: UIColor.systemOrange,
            secondary: UIColor.systemYellow,
            accent: UIColor.systemRed,
            background: UIColor.systemBackground,
            text: UIColor.label
        )
    )
    
    let samplePlaylist = Playlist(
        name: "Test Playlist",
        songs: [sampleSong]
    )
    
    SongRow(musicItems: sampleSong, playlist: samplePlaylist)
        .padding()
}


/*
 #Preview {
 SongRow(
 musicItems: MusicItem(
 songID: "test",
 title: "Test Song",
 artworkURL: nil
 ),
 playlist: Playlist(name: "Test Playlist", songs: [])
 )
 }
 */
