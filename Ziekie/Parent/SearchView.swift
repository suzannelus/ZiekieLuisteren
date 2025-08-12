//
//  ContentView.swift
//  ziekie
//
//  Created by Suzanne Lustenhouwer on 13/02/2023.
//
// done with IOS Academy youtube https://www.youtube.com/watch?v=-t9Arg7LP1Q


import MusicKit
import SwiftUI

struct Item: Identifiable {
    let id: MusicItemID
    let name: String
    let artist: String
    let imageURL: URL?
}

struct SearchView: View {
    @State private var songs = [Item]()
    @State private var searchText = ""
    @Binding var selectedSongs: [MusicItem]
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchTask: Task<Void, Never>?
    @State private var showingImagePlayground = false
    @State private var currentSong: Item?
    @State private var generatedImage: Image?
    @State private var isSearching = false
    
    var body: some View {
        List {
            TextField("Search for songs", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .onChange(of: searchText) { _, newValue in
                    // CRITICAL: Throttle search requests
                    searchTask?.cancel()
                    
                    guard !newValue.isEmpty else {
                        songs = []
                        return
                    }
                    
                    searchTask = Task {
                        // Wait for user to stop typing
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                        
                        guard !Task.isCancelled else { return }
                        
                        await performSearch(query: newValue)
                    }
                }
            
            if isSearching {
                HStack {
                    ProgressView()
                    Text("Searching...")
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            ForEach(songs) { song in
                SongSearchRow(song: song) { selectedSong in
                    selectedSongs.append(selectedSong)
                    dismiss()
                }
            }
        }
        .navigationTitle("Add Songs")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            print("SearchView appeared with current playlist songs count: \(selectedSongs.count)")
        }
        .onChange(of: selectedSongs) { _, newValue in
            print("selectedSongs changed. New count: \(newValue.count)")
        }
    }
    
    private func performSearch(query: String) async {
        await MainActor.run {
            isSearching = true
        }
        
        defer {
            Task { @MainActor in
                isSearching = false
            }
        }
        
        do {
            let status = await MusicAuthorization.request()
            guard status == .authorized else {
                print("❌ Not authorized for search")
                return
            }
            
            var request = MusicCatalogSearchRequest(term: query, types: [Song.self])
            request.limit = 10 // REDUCED from 25 to reduce network load
            
            let result = try await request.response()
            
            let newSongs = result.songs.map { song in
                Item(
                    id: song.id,
                    name: song.title,
                    artist: song.artistName ?? "Unknown Artist",
                    imageURL: song.artwork?.url(width: 100, height: 100) // REDUCED image size
                )
            }
            
            await MainActor.run {
                self.songs = newSongs
            }
            
            print("✅ Search complete: \(newSongs.count) results")
            
        } catch {
            print("❌ Search failed: \(error)")
            await MainActor.run {
                self.songs = []
            }
        }
    }
    
    struct Search_Previews: PreviewProvider {
        static var previews: some View {
            NavigationStack {
                SearchView(selectedSongs: .constant([]))
            }
        }
    }
    
    
    struct SongSearchRow: View {
        let song: Item
        let onSelect: (MusicItem) -> Void
        
        @State private var showingImagePlayground = false
        @State private var generatedImage: Image?
        
        @State private var extractedPalette: ColorPalette?
        @State private var isExtractingColors = false
        @StateObject private var colorExtractor = ColorExtractionService.shared
        
        var body: some View {
            HStack {
                // OPTIMIZED: Smaller artwork, lazy loading
                AsyncImage(url: song.imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(.gray.opacity(0.3))
                }
                .frame(width: 40, height: 40) // REDUCED from 50x50
                .cornerRadius(6)
                
                VStack(alignment: .leading) {
                    Text(song.name)
                        .font(.subheadline) // REDUCED font size
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text(song.artist)
                        .font(.caption) // REDUCED font size
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if isExtractingColors {
                                HStack(spacing: 4) {
                                    ProgressView()
                                        .scaleEffect(0.6)
                                        .tint(.mint)
                                    Text("Colors...")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            } else if let palette = extractedPalette {
                                ColorPalettePreview(palette: palette)
                            }
                        
                
                Button {
                    showingImagePlayground = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.mint)
                        .font(.title3) // REDUCED from title2
                }
            }
            .padding(.vertical, 2) // REDUCED padding
            .imagePlaygroundSheet(
                isPresented: $showingImagePlayground,
                concept: song.name,
                sourceImage: nil
            ) { url in
                if let data = try? Data(contentsOf: url),
                   let uiImage = UIImage(data: data) {
                    generatedImage = Image(uiImage: uiImage)
                    
                    let musicItem = MusicItem(
                        songID: song.id.rawValue,
                        title: song.name,
                        artworkURL: song.imageURL,
                        customImage: generatedImage,
                        imageGenerationConcepts: song.name
                    )
                    
                    onSelect(musicItem)
                }
            }
        }
    }
}
