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
                    
                    Text("\(totalPlayCount) plays")
                        .font(.caption)
                        .foregroundColor(.purple)
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
        .background(.purple.opacity(isSelected ? 0.3 : 0.1))
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
                .font(.caption)
                .foregroundColor(.white)
               .glassEffect(.regular.tint( .pink).interactive())
                
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
                
            }
            
            Spacer()
        }
        .padding()
        .background(.purple.opacity(0.2))
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
                .foregroundColor(.purple)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.purple.opacity(0.2))
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
                
                Text("\(song.playCount) plays")
                    .font(.caption)
                    .foregroundColor(.gray)
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
                        .foregroundColor(.teal)
                }
                
                // Remove song button
                Button(action: {
                    showingDeleteAlert = true
                    parentModeManager.resetInactivityTimer()
                }) {
                    Image(systemName: "minus.circle")
                        .font(.title3)
                        .foregroundColor(.pink)
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
        .sheet(isPresented: $showingImageEditor) {
                    ParentSongImageEditorView(song: song, playlist: playlist)
                        .colorScheme(.dark)
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
                .foregroundColor(.purple)
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .background(.purple.opacity(0.2))
        .cornerRadius(12)
    }
}



// MARK: - Preview Macros

#Preview("ParentPlaylistEditView - With Songs") {
    NavigationStack {
        ParentPlaylistEditView(playlist: .mockPlaylistWithSongs)
    }
    .preferredColorScheme(.dark)
}

#Preview("ParentPlaylistEditView - Empty Playlist") {
    NavigationStack {
        ParentPlaylistEditView(playlist: .mockEmptyPlaylist)
    }
    .preferredColorScheme(.dark)
}

#Preview("ParentPlaylistEditView - Large Playlist") {
    NavigationStack {
        ParentPlaylistEditView(playlist: .mockLargePlaylist)
    }
    .preferredColorScheme(.dark)
}

#Preview("ParentPlaylistRow - Selected") {
    ParentPlaylistRow(
        playlist: .mockPlaylistWithSongs,
        isSelected: true,
        showingBatchActions: true,
        onSelectionChanged: { _ in }
    )
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("ParentPlaylistRow - Normal") {
    ParentPlaylistRow(
        playlist: .mockPlaylistWithSongs,
        isSelected: false,
        showingBatchActions: false,
        onSelectionChanged: { _ in }
    )
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("ParentSongRow") {
    VStack(spacing: 8) {
        ParentSongRow(
            song: .mockSong1,
            playlist: .mockPlaylistWithSongs
        )
        
        ParentSongRow(
            song: .mockSong2,
            playlist: .mockPlaylistWithSongs
        )
        
        ParentSongRow(
            song: .mockSongWithLongTitle,
            playlist: .mockPlaylistWithSongs
        )
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("EmptySongsView") {
    EmptySongsView()
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
}

// MARK: - Mock Data Extensions

extension Playlist {
    static let mockEmptyPlaylist = Playlist(
   //     id: "empty_playlist",
        name: "Empty Playlist",
        customImage: Image("Row, Row, Row, Your Boat"),
        songs: [],
         // Replace with your actual image
     //   effectivePalette: .mockPalette1
    )
    
    static let mockPlaylistWithSongs = Playlist(
  //      id: "playlist_with_songs",
        name: "Kids Favorites",
        customImage: Image("WheelsOnTheBus"),
        songs: [
            .mockSong1,
            .mockSong2,
            .mockSong3
        ]
       , // Replace with your actual image
    //    effectivePalette: .mockPalette1
    )
    
    static let mockLargePlaylist = Playlist(
   //     id: "large_playlist",
        name: "Big Collection of Songs",
        customImage: Image("WheelsOnTheBus"),
        songs: [
            .mockSong1,
            .mockSong2,
            .mockSong3,
            .mockSongWithLongTitle,
            .mockSong1, // Duplicate for demonstration
            .mockSong2,
            .mockSong3,
            .mockSongWithLongTitle
        ],
      // Replace with your actual image
    //    effectivePalette: .mockPalette2
    )
}

extension MusicItem {
    static let mockSong1 = MusicItem(
    //    id: "song_1",
        songID: "song_1",
        title: "Wheels on the Bus",
        artworkURL: nil,
        playCount: 15,
        lastPlayedDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
        customImage: Image("WheelsOnTheBus"), // Replace with your actual image
        
    )
    
    static let mockSong2 = MusicItem(
   //     id: "song_2",
        songID: "song_2",
        title: "Twinkle Twinkle Little Star",
        artworkURL: URL(string: "https://example.com/artwork.jpg"),
        playCount: 8,
        lastPlayedDate: Calendar.current.date(byAdding: .day, value: -3, to: Date()),
        customImage: nil,
     
    )
    
    static let mockSong3 = MusicItem(
   //     id: "song_3",
        songID: "song_3",
        title: "Old MacDonald",
        artworkURL: nil,
        playCount: 22,
        lastPlayedDate: Calendar.current.date(byAdding: .hour, value: -2, to: Date()),
        customImage: nil,
      
    )
    
    static let mockSongWithLongTitle = MusicItem(
 //       id: "song_4",
        songID: "song_4",
        title: "This is a Very Long Song Title That Should Test Text Truncation in the UI",
        artworkURL: nil,
        playCount: 3,
        lastPlayedDate: Calendar.current.date(byAdding: .day, value: -7, to: Date()),
        customImage: nil,
       
    )
}

// MARK: - Mock Managers (if needed for dependency injection)

class MockPlaylistsContainer: ObservableObject {
    static let shared = MockPlaylistsContainer()
    
    @Published var playlists: [Playlist] = [
        .mockEmptyPlaylist,
        .mockPlaylistWithSongs,
        .mockLargePlaylist
    ]
    
    private init() {}
}

class MockParentModeManager: ObservableObject {
    static let shared = MockParentModeManager()
    
    private init() {}
    
    func resetInactivityTimer() {
        print("Inactivity timer reset")
    }
}

// MARK: - Mock Views (for dependencies)

struct MockSearchView: View {
    @Binding var selectedSongs: [MusicItem]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Mock Search View")
                    .font(.title)
                    .foregroundColor(.white)
                
                Text("This would be your SearchView")
                    .foregroundColor(.gray)
                
                Button("Add Mock Song") {
                    selectedSongs.append(.mockSong1)
                }
                .padding()
                .background(.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Search Songs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct MockParentImageEditorView: View {
    let playlist: Playlist
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Mock Image Editor")
                    .font(.title)
                    .foregroundColor(.white)
                
                Text("Editing image for: \(playlist.name)")
                    .foregroundColor(.gray)
                
                if let image = playlist.customImage {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct MockParentSongImageEditorView: View {
    let song: MusicItem
    let playlist: Playlist
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Mock Song Image Editor")
                    .font(.title)
                    .foregroundColor(.white)
                
                Text("Editing image for: \(song.title)")
                    .foregroundColor(.gray)
                
                if let image = song.customImage {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 150)
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Song Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Alternative Preview Provider Style

struct ParentPlaylistEditView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // With songs
            NavigationStack {
                ParentPlaylistEditView(playlist: .mockPlaylistWithSongs)
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("With Songs")
            
            // Empty playlist
            NavigationStack {
                ParentPlaylistEditView(playlist: .mockEmptyPlaylist)
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("Empty Playlist")
            
            // Large playlist on smaller device
            NavigationStack {
                ParentPlaylistEditView(playlist: .mockLargePlaylist)
            }
            .preferredColorScheme(.dark)
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("Large Playlist - Small Device")
        }
    }
}

// MARK: - Integration Notes and Recommendations

/*
 INTEGRATION NOTES:
 
 1. Replace Mock Views:
    - Replace MockSearchView with your actual SearchView
    - Replace MockParentImageEditorView with your actual ParentImageEditorView
    - Replace MockParentSongImageEditorView with your actual ParentSongImageEditorView
 
 2. Update Image References:
    - Replace "WheelsOnTheBus" with actual image names from your asset catalog
    - Update artworkURL with real URLs if testing network images
 
 3. Model Structure:
    - Adjust MusicItem and Playlist initializers to match your actual model
    - Ensure all required properties are included
 
 4. Manager Dependencies:
    - If your managers need to be injected, consider using environmentObject
    - You might want to create protocols for easier testing
 
 5. ImagePlayground Integration:
    - The code assumes ImagePlayground is available
    - Adjust imports and dependencies as needed
 
 DEPENDENCY INJECTION EXAMPLE:
 
 If you want to make managers injectable for better testing:
 
 // In your main app:
 .environmentObject(PlaylistsContainer.shared)
 .environmentObject(ParentModeManager.shared)
 
 // In your view:
 @EnvironmentObject private var container: PlaylistsContainer
 @EnvironmentObject private var parentModeManager: ParentModeManager
 
 // In previews:
 .environmentObject(MockPlaylistsContainer.shared)
 .environmentObject(MockParentModeManager.shared)
 */
