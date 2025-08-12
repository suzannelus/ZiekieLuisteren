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
    @StateObject private var container = PlaylistsContainer.shared
    
    // Computed properties for cleaner state management
    private var isThisSongSelected: Bool {
        playerManager.currentlyPlayingSongID == musicItems.songID
    }
    
    private var isThisSongPlaying: Bool {
        isThisSongSelected && playerManager.isPlaying
    }
    
    // Use song's colors if available, otherwise playlist's colors
    private var effectiveColorPalette: ColorPalette {
        currentSong.colorPalette ?? playlist.effectivePalette  // CHANGED
    }
    
    private var currentSong: MusicItem {
        guard let currentPlaylist = container.playlists.first(where: { $0.id == playlist.id }),
              let song = currentPlaylist.songs.first(where: { $0.id == musicItems.id }) else {
            return musicItems
        }
        return song
    }
    
    var body: some View {
        NavigationLink(destination: SongView(playlist: playlist, initialSongID: musicItems.songID)) {
            ZStack {
                VStack(spacing: 8) {
                    // Song Artwork
                    currentSong.displayImage
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .cornerRadius(12)
                        .shadow(
                            color: effectiveColorPalette.primaryColor.opacity(0.8),
                            radius: 2,
                            x: 0,
                            y: 1
                        )
                    // Song Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(musicItems.title)
                            .bodyLarge()
                            .lineLimit(2)
                            .foregroundColor(effectiveColorPalette.textColor)
                    }
                    
                }
                    // Playing indicator
                    if isThisSongSelected {
                        PlayingIndicator(
                            isPlaying: isThisSongPlaying,
                            palette: effectiveColorPalette
                        )
                    }
                
            }
            .padding(.vertical, 4)
            .background(
                // Subtle background highlight when song is selected
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        
                        isThisSongSelected ?
                        LinearGradient(colors: [effectiveColorPalette.primaryColor.opacity(0.4), .clear], startPoint: .top, endPoint: .bottom):
                            LinearGradient(colors: [.clear, .clear], startPoint: .top, endPoint: .bottom)
                    )
            )
            .overlay(
                // Accent border when playing
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isThisSongPlaying ?
                        effectiveColorPalette.accentColor.opacity(0.8) :
                            Color.clear,
                        lineWidth: 1
                    )
            )
        }
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
        }
        .scaleEffect(isPlaying ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isPlaying)
    }
}

#Preview {
    let sampleSong = MusicItem(
        songID: "test123",
        title: "Row, Row, Row, Your Boat",
       // artworkURL: nil,
        customImage: Image("Row, Row, Row Your Boat"),
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
