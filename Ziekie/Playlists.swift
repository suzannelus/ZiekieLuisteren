//
//  Playlists.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 02/02/2025.
//

import SwiftUI
import MusicKit

class PlaylistViewModel: ObservableObject {
    @Published var playlistName = ""
    @Published var searchText = ""
    @Published var searchResults: [Song] = []
    @Published var selectedSongs: Set<Song> = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    @Published var selectedSongForImage: Song?
    @Published var isShowingImagePlayground = false
    @Published var generatedImages: [Song: Image] = [:]
    @Published var customConcepts: [Song: String] = [:]
    
    private let container = PlaylistsContainer.shared
    @ObservedObject private var authManager = MusicAuthManager.shared
    
    func generateImageForSong(_ song: Song) {
        selectedSongForImage = song
        // Initialize with song title as default concept
        if customConcepts[song] == nil {
            customConcepts[song] = song.title
        }
        isShowingImagePlayground = true
    }
    
    func createPlaylist() async -> Bool {
        // Validate playlist name
        guard !playlistName.isEmpty else {
            await MainActor.run {
                errorMessage = "Please enter a playlist name"
            }
            return false
        }
        
        guard authManager.isAuthorized else {
            await MainActor.run {
                errorMessage = "Please authorize access to Apple Music in Settings."
            }
            return false
        }
        
        await MainActor.run { isLoading = true }
        
        do {
            // Create new MusicItems for each selected song
            var musicItems: [MusicItem] = []
            
            for song in selectedSongs {
                let newMusicItem = MusicItem(
                    songID: song.id.rawValue,
                    title: song.title,
                    url: try? URL(string: "https://music.apple.com/nl/album/\(song.id)"),
                    image: nil,
                    playCount: 0,
                    customImage: generatedImages[song],
                    imageGenerationConcepts: customConcepts[song]
                )
                musicItems.append(newMusicItem)
            }
            
            // Create playlist with first song's image
            if let firstSongImage = generatedImages.values.first {
                container.createPlaylist(
                    name: playlistName,
                    image: firstSongImage,
                    concept: customConcepts.values.first ?? playlistName
                )
                
                if let createdPlaylist = container.playlists.last {
                    container.addSongs(musicItems, to: createdPlaylist)
                }
            }
            
            await MainActor.run {
                isLoading = false
                // Reset the form
                playlistName = ""
                selectedSongs.removeAll()
                searchResults.removeAll()
                searchText = ""
                generatedImages.removeAll()
                customConcepts.removeAll()
            }
            
            return true
        } catch {
            await MainActor.run {
                errorMessage = "Failed to create playlist: \(error.localizedDescription)"
                isLoading = false
            }
            return false
        }
    }
    
    /* old image playground features
     func setImageGenerationConcept(for song: Song, concept: String) {
     imageGenerationConcepts[song] = concept
     }
     
     func setSongImage(for song: Song, imageURL: URL) {
     songImages[song] = imageURL
     }
     */
    
    @MainActor
    func searchSongs() async {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        
        guard authManager.isAuthorized else {
            errorMessage = "Please authorize access to Apple Music in Settings."
            isLoading = false
            return
        }
        
        do {
            // Create and configure the search request
            var request = MusicCatalogSearchRequest(term: searchText, types: [Song.self])
            request.limit = 25 // Limit results to 25 songs
            
            // Perform the search request
            let response = try await request.response()
            
            // Convert MusicItemCollection to array
            searchResults = response.songs.map { $0 }
            isLoading = false
            
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            searchResults = []
        }
    }
}

struct PlaylistCreationView: View {
    @StateObject private var viewModel = PlaylistViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.supportsImagePlayground) var supportsImagePlayground
    @State private var showError = false
    
    
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                TextField("Playlist Name", text: $viewModel.playlistName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                Image(systemName: "photo.circle.fill")
                    .font(.largeTitle)
                    .padding(40)
                    .background(.quaternary)
                    .cornerRadius(8)
                SearchBar(text: $viewModel.searchText) {  // Add closure here
                    Task {
                        await viewModel.searchSongs()
                    }
                }
                .padding(.horizontal)
                
                
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(viewModel.searchResults, id: \.id) { song in
                        SongRowTwo(song: song, isSelected: viewModel.selectedSongs.contains(song))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if viewModel.selectedSongs.contains(song) {
                                    viewModel.selectedSongs.remove(song)
                                } else {
                                    viewModel.selectedSongs.insert(song)
                                    // Set default concept as song title
                                    viewModel.customConcepts[song] = song.title
                                    viewModel.selectedSongForImage = song
                                    viewModel.isShowingImagePlayground = true
                                }
                            }
                        if viewModel.selectedSongs.contains(song) {
                            if let image = viewModel.generatedImages[song] {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 100)
                                    .cornerRadius(8)
                            }
                            
                            
                            VStack(spacing: 8) {
                                TextField("Describe the image you want",
                                          text: Binding(
                                            get: { viewModel.customConcepts[song] ?? song.title },
                                            set: { viewModel.customConcepts[song] = $0 }
                                          ))
                                .textFieldStyle(.roundedBorder)
                                .padding(.horizontal)
                                
                                Button(action: {
                                    viewModel.generateImageForSong(song)
                                }) {
                                    Label("Regenerate Image", systemImage: "sparkles")
                                        .font(.headline)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.mint)
                            }
                            .padding(.vertical, 4)
                            
                        }
                    }
                }
                
                
                CreatePlaylistButton(viewModel: viewModel) {
                    dismiss()
                }
            }
            .navigationTitle("Create Playlist")
            .imagePlaygroundSheet(
                isPresented: $viewModel.isShowingImagePlayground,
                concept: viewModel.selectedSongForImage.flatMap {
                    viewModel.customConcepts[$0] ?? $0.title
                } ?? "",
                sourceImage: nil
            ) { url in
                if let song = viewModel.selectedSongForImage,
                   let data = try? Data(contentsOf: url),
                   let uiImage = UIImage(data: data) {
                    let generatedImage = Image(uiImage: uiImage)
                    viewModel.generatedImages[song] = generatedImage
                }
            }
            
            
            // Update alert modifier
            .alert("Error", isPresented: $showError) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .onChange(of: viewModel.errorMessage) { _, newValue in
                showError = newValue != nil
            }
        }
        .handleMusicAuth()
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var onSearchChanged: () -> Void
    
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search for songs", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .onChange(of: text) { _, _ in
                    onSearchChanged()
                }
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                    onSearchChanged()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct SongRowTwo: View {
    let song: Song
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.headline)
                Text(song.artistName ?? "Unknown Artist")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical, 8)
    }
}

struct CreatePlaylistButton: View {
    @ObservedObject var viewModel: PlaylistViewModel
    var onSuccess: () -> Void
    
    var body: some View {
        Button {
            Task {
                if await viewModel.createPlaylist() {
                    onSuccess()
                }
            }
        } label: {
            Text("Create Playlist")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.playlistName.isEmpty || viewModel.selectedSongs.isEmpty ? Color.gray : Color.accentColor)
                .cornerRadius(10)
        }
        .disabled(viewModel.playlistName.isEmpty || viewModel.selectedSongs.isEmpty)
        .padding(.horizontal)
    }
}

#Preview {
    PlaylistCreationView()
}

