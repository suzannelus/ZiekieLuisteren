//
//  ParentPlaylistRow.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 15/07/2025.
//


import SwiftUI
import ImagePlayground

struct ParentPlaylistRow: View {
    let playlist: Playlist
    let isSelected: Bool
    let showingBatchActions: Bool
    let onSelectionChanged: (Bool) -> Void
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingImageEditor = false
    @StateObject private var container = PlaylistsContainer.shared
    @StateObject private var parentModeManager = ParentModeManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Selection checkbox (batch mode)
            if showingBatchActions {
                Button(action: {
                    onSelectionChanged(!isSelected)
                }) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? .blue : .gray)
                }
            }
            
            // Playlist image
            playlistImageView
            
            // Playlist info
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack {
                    Text("\(playlist.songs.count) songs")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("♪ \(totalPlayCount) plays")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                if let lastPlayed = mostRecentPlay {
                    Text("Last played: \(formatRelativeDate(lastPlayed))")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Action buttons (non-batch mode)
            if !showingBatchActions {
                VStack(spacing: 8) {
                    // Edit image button
                    Button(action: {
                        showingImageEditor = true
                        parentModeManager.resetInactivityTimer()
                    }) {
                        Image(systemName: "photo.circle.fill")
                            .font(.title2)
                            .foregroundColor(.purple)
                    }
                    
                    // Edit playlist button
                    Button(action: {
                        showingEditSheet = true
                        parentModeManager.resetInactivityTimer()
                    }) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                    
                    // Delete button
                    Button(action: {
                        showingDeleteAlert = true
                        parentModeManager.resetInactivityTimer()
                    }) {
                        Image(systemName: "trash.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding()
        .background(.gray.opacity(isSelected ? 0.3 : 0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? .blue : .clear, lineWidth: 2)
        )
        .sheet(isPresented: $showingEditSheet) {
            ParentPlaylistEditView(playlist: playlist)
                .colorScheme(.dark)
        }
        .sheet(isPresented: $showingImageEditor) {
            ParentImageEditorView(playlist: playlist)
                .colorScheme(.dark)
        }
        .alert("Delete Playlist", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                deletePlaylist()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete '\(playlist.name)'? This action cannot be undone.")
        }
    }
    
    // MARK: - Playlist Image View
    private var playlistImageView: some View {
        Group {
            if let image = playlist.customImage {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image("WheelsOnTheBus")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }
        .frame(width: 80, height: 80)
        .cornerRadius(8)
        .shadow(radius: 4)
        .overlay(
            // Image edit indicator
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "camera.circle.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .background(.black.opacity(0.6))
                        .clipShape(Circle())
                        .padding(4)
                }
            }
        )
    }
    
    // MARK: - Computed Properties
    private var totalPlayCount: Int {
        playlist.songs.reduce(0) { $0 + $1.playCount }
    }
    
    private var mostRecentPlay: Date? {
        playlist.songs.compactMap { $0.lastPlayedDate }.max()
    }
    
    // MARK: - Helper Methods
    private func deletePlaylist() {
        withAnimation {
            container.playlists.removeAll { $0.id == playlist.id }
        }
        container.objectWillChange.send()
        parentModeManager.resetInactivityTimer()
    }
    
    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Parent Playlist Edit View
struct ParentPlaylistEditView: View {
    let playlist: Playlist
    @Environment(\.dismiss) private var dismiss
    @StateObject private var container = PlaylistsContainer.shared
    @StateObject private var parentModeManager = ParentModeManager.shared
    @State private var showingAddSongs = false
    
    private var playlistIndex: Int? {
        container.playlists.firstIndex { $0.id == playlist.id }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .colorScheme(.dark)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Playlist header
                        playlistHeader
                        
                        // Song management
                        songManagementSection
                        
                        // Add songs section
                        addSongsSection
                    }
                    .padding()
                }
            }
        }
        .colorScheme(.dark)
        .navigationTitle("Edit \(playlist.name)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .foregroundColor(.blue)
            }
        }
        .sheet(isPresented: $showingAddSongs) {
            NavigationStack {
                SearchView(selectedSongs: Binding(
                    get: { playlist.songs },
                    set: { newSongs in
                        updatePlaylistSongs(newSongs)
                    }
                ))
            }
            .colorScheme(.dark)
        }
        .onTapGesture {
            parentModeManager.resetInactivityTimer()
        }
    }
    
    // MARK: - Playlist Header
    private var playlistHeader: some View {
        HStack(spacing: 16) {
            if let image = playlist.customImage {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .cornerRadius(12)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(playlist.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("\(playlist.songs.count) songs")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                if let concept = playlist.imageGenerationConcept {
                    Text("Theme: \(concept)")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .lineLimit(2)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(.gray.opacity(0.2))
        .cornerRadius(12)
    }
    
    // MARK: - Song Management
    private var songManagementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Songs")
                .font(.headline)
                .foregroundColor(.white)
            
            if playlist.songs.isEmpty {
                EmptySongsView()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(playlist.songs, id: \.id) { song in
                        ParentSongRow(
                            song: song,
                            playlist: playlist
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Add Songs Section
    private var addSongsSection: some View {
        Button(action: {
            showingAddSongs = true
            parentModeManager.resetInactivityTimer()
        }) {
            Label("Add More Songs", systemImage: "plus.circle.fill")
                .font(.headline)
                .foregroundColor(.green)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.green.opacity(0.2))
                .cornerRadius(12)
        }
    }
    
    // MARK: - Helper Methods
    private func updatePlaylistSongs(_ newSongs: [MusicItem]) {
        guard let index = playlistIndex else { return }
        
        withAnimation {
            container.playlists[index].songs = newSongs
        }
        container.objectWillChange.send()
        parentModeManager.resetInactivityTimer()
    }
}

struct ParentSongRow: View {
    let song: MusicItem
    let playlist: Playlist
    @StateObject private var container = PlaylistsContainer.shared
    @StateObject private var parentModeManager = ParentModeManager.shared
    @State private var showingImageEditor = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Song artwork
            Group {
                if let customImage = song.customImage {
                    customImage
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if let artworkURL = song.artworkURL {
                    AsyncImage(url: artworkURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                    }
                } else {
                    Image(systemName: "music.note")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 50, height: 50)
            .cornerRadius(6)
            
            // Song info
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("♪ \(song.playCount) plays")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 12) {
                // Edit image button
                
                Button(action: {
                    showingImageEditor = true
                    parentModeManager.resetInactivityTimer()
                }) {
                    Image(systemName: "photo.circle")
                        .font(.title3)
                        .foregroundColor(.purple)
                }
                
                // Remove song button
                Button(action: {
                    showingDeleteAlert = true
                    parentModeManager.resetInactivityTimer()
                }) {
                    Image(systemName: "minus.circle")
                        .font(.title3)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.black.opacity(0.2))
        .cornerRadius(8)
        
        .alert("Remove Song", isPresented: $showingDeleteAlert) {
            Button("Remove", role: .destructive) {
                removeSongFromPlaylist()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Remove '\(song.title)' from this playlist?")
        }
    }
    
    private func removeSongFromPlaylist() {
        guard let playlistIndex = container.playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        
        withAnimation {
            container.playlists[playlistIndex].songs.removeAll { $0.id == song.id }
        }
        container.objectWillChange.send()
        parentModeManager.resetInactivityTimer()
    }
}




// MARK: - Supporting Views
struct EmptySongsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("No songs in this playlist")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text("Tap 'Add More Songs' to get started")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .background(.gray.opacity(0.1))
        .cornerRadius(12)
    }
}



#Preview {
    ParentPlaylistRow(
        playlist: Playlist(name: "Test Playlist", songs: []),
        isSelected: false,
        showingBatchActions: false,
        onSelectionChanged: { _ in }
    )
    .colorScheme(.dark)
}
