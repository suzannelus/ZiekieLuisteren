import SwiftUI
import ImagePlayground
import PhotosUI

struct ParentSongImageEditorView: View {
    let song: MusicItem
    let playlist: Playlist
    @Environment(\.dismiss) private var dismiss
    @StateObject private var container = PlaylistsContainer.shared
    @StateObject private var parentModeManager = ParentModeManager.shared
    @StateObject private var colorExtractor = ColorExtractionService.shared
    
    @State private var newImage: Image?
    @State private var newUIImage: UIImage? // For color extraction
    @State private var extractedPalette: ColorPalette?
    @State private var isExtractingColors = false
    @State private var imageGenerationConcept: String
    @State private var isShowingImagePlayground = false
    @State private var isGeneratingImage = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    @State private var imagePlaygroundTimer: Timer?
    
    init(song: MusicItem, playlist: Playlist) {
        self.song = song
        self.playlist = playlist
        // Use song's existing concept or generate one from the song title
        let defaultConcept = song.imageGenerationConcept ?? "Album artwork for the song '\(song.title)' with colorful musical elements"
        self._imageGenerationConcept = State(initialValue: defaultConcept)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .colorScheme(.dark)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Current song image section
                        currentSongImageSection
                        
                        // Image generation section
                        enhancedImageGenerationSection
                        
                        // Color extraction results
                        if let palette = extractedPalette {
                            colorResultsSection(palette: palette)
                        }
                        
                        // Alternative image options
                        alternativeOptionsSection
                        
                        // Save section
                        if newImage != nil {
                            enhancedSaveSection
                        }
                    }
                    .padding()
                }
            }
        }
        .colorScheme(.dark)
        .navigationTitle("Edit Song Image")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.red)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                if newImage != nil {
                    Button("Save") {
                        saveImageWithColors()
                    }
                    .foregroundColor(.green)
                    .fontWeight(.semibold)
                }
            }
        }
        .imagePlaygroundSheet(
            isPresented: $isShowingImagePlayground,
            concept: imageGenerationConcept,
            sourceImage: nil
        ) { url in
            Task {
                await handleGeneratedImageWithColors(url: url)
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            loadSelectedPhoto(newItem)
        }
        .onDisappear {
            imagePlaygroundTimer?.invalidate()
            imagePlaygroundTimer = nil
        }
    }
    
    // MARK: - Current Song Image Section
    private var currentSongImageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Song Image")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
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
                                .tint(.mint)
                        }
                    } else {
                        Image("WheelsOnTheBus")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                }
                .frame(width: 120, height: 120)
                .cornerRadius(12)
                .shadow(radius: 4)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(song.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("From '\(playlist.name)'")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text("♪ \(song.playCount) plays")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    if let concept = song.imageGenerationConcept {
                        Text("Theme: \(concept)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                    
                    // Show current colors if available
                    if let palette = song.colorPalette {
                        HStack {
                            Text("Colors:")
                                .font(.caption)
                                .foregroundColor(.gray)
                            ColorPalettePreview(palette: palette)
                        }
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(.gray.opacity(0.2))
        .cornerRadius(12)
    }
    
    // MARK: - Enhanced Image Generation Section
    private var enhancedImageGenerationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create New Image")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                // Concept input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Describe your image")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    TextField("e.g., Colorful album artwork with musical notes", text: $imageGenerationConcept)
                        .textFieldStyle(.roundedBorder)
                        .background(.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .onChange(of: imageGenerationConcept) { _, _ in
                            parentModeManager.resetInactivityTimer()
                        }
                }
                
                // Generate button with color extraction status
                Button(action: generateNewImageWithColors) {
                    HStack {
                        if isGeneratingImage {
                            ProgressView().scaleEffect(0.8)
                        } else if isExtractingColors {
                            ProgressView().scaleEffect(0.8)
                            Text("Extracting colors...")
                        } else {
                            Image(systemName: "sparkles")
                            Text("Generate with AI")
                        }
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isGeneratingImage || isExtractingColors || imageGenerationConcept.isEmpty)
            }
            
            // Preview new image with colors
            if let newImage = newImage {
                VStack(spacing: 8) {
                    newImage
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 150)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                    
                    Text("New song image preview")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(.purple.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Color Results Section
    private func colorResultsSection(palette: ColorPalette) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Extracted Colors")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Color Palette:")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    ColorPalettePreview(palette: palette, size: 24)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    colorRow("Primary", color: palette.primaryColor)
                    colorRow("Secondary", color: palette.secondaryColor)
                    colorRow("Accent", color: palette.accentColor)
                    colorRow("Background", color: palette.backgroundColor)
                    colorRow("Text", color: palette.textColor)
                }
            }
        }
        .padding()
        .background(.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func colorRow(_ name: String, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 16, height: 16)
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.8), lineWidth: 1)
                )
            
            Text(name)
                .font(.caption)
                .foregroundColor(.gray)
            
            Spacer()
        }
    }
    
    // MARK: - Alternative Options Section
    private var alternativeOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Other Options")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                // Photo library option
                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images
                ) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("Choose from Photos")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .padding()
                    .background(.blue.opacity(0.2))
                    .cornerRadius(8)
                }
                .foregroundColor(.blue)
                
                // Reset to default
                Button(action: {
                    resetToDefault()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Reset to Default")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .padding()
                    .background(.orange.opacity(0.2))
                    .cornerRadius(8)
                }
                .foregroundColor(.orange)
            }
        }
        .padding()
        .background(.gray.opacity(0.2))
        .cornerRadius(12)
    }
    
    // MARK: - Enhanced Save Section
    private var enhancedSaveSection: some View {
        VStack(spacing: 12) {
            Text("Ready to Save")
                .font(.headline)
                .foregroundColor(.white)
            
            if extractedPalette != nil {
                Text("Song image and color palette will be saved")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Text("Song image will be saved with default colors")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            Button("Save Image & Colors") {
                saveImageWithColors()
            }
            .font(.headline)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(.green)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding()
        .background(.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Enhanced Methods
    private func generateNewImageWithColors() {
        guard !imageGenerationConcept.isEmpty else { return }
        
        parentModeManager.resetInactivityTimer()
        isGeneratingImage = true
        isShowingImagePlayground = true
        parentModeManager.resetInactivityTimer()
    }
    
    private func handleGeneratedImageWithColors(url: URL) async {
        isGeneratingImage = false
        
        do {
            let data = try Data(contentsOf: url)
            guard let uiImage = UIImage(data: data) else { return }
            
            await MainActor.run {
                self.newUIImage = uiImage
                self.newImage = Image(uiImage: uiImage)
                self.isExtractingColors = true
                self.extractedPalette = nil
            }
            
            // Extract colors
            do {
                let palette = try await colorExtractor.extractColors(from: uiImage)
                await MainActor.run {
                    self.extractedPalette = palette
                    self.isExtractingColors = false
                    parentModeManager.resetInactivityTimer()
                    print("✅ Color extraction complete for song image")
                }
            } catch {
                await MainActor.run {
                    self.extractedPalette = .default
                    self.isExtractingColors = false
                    print("⚠️ Using default colors: \(error)")
                }
            }
        } catch {
            print("❌ Failed to process generated image: \(error)")
        }
    }
    
    private func loadSelectedPhoto(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        item.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                if let data = data, let uiImage = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.newUIImage = uiImage
                        self.newImage = Image(uiImage: uiImage)
                        self.parentModeManager.resetInactivityTimer()
                        
                        // Extract colors from selected photo
                        Task {
                            do {
                                let palette = try await self.colorExtractor.extractColors(from: uiImage)
                                await MainActor.run {
                                    self.extractedPalette = palette
                                    print("✅ Color extraction complete for selected photo")
                                }
                            } catch {
                                await MainActor.run {
                                    self.extractedPalette = .default
                                    print("⚠️ Using default colors for selected photo: \(error)")
                                }
                            }
                        }
                    }
                }
            case .failure(let error):
                print("Failed to load photo: \(error)")
            }
        }
    }
    
    private func resetToDefault() {
        newImage = Image("WheelsOnTheBus")
        newUIImage = UIImage(named: "WheelsOnTheBus")
        extractedPalette = .default
        parentModeManager.resetInactivityTimer()
    }
    
    private func saveImageWithColors() {
        // Find the playlist and song to update
        guard let playlistIndex = container.playlists.firstIndex(where: { $0.id == playlist.id }),
              let songIndex = container.playlists[playlistIndex].songs.firstIndex(where: { $0.songID == song.songID }),
              let newImage = newImage else { 
            print("❌ Could not find playlist or song to update")
            return 
        }
        
        let finalPalette = extractedPalette ?? .default
        
        withAnimation {
            // Update the song with new image, concept, and colors
            container.playlists[playlistIndex].songs[songIndex].customImage = newImage
            container.playlists[playlistIndex].songs[songIndex].imageGenerationConcept = imageGenerationConcept
            container.playlists[playlistIndex].songs[songIndex].colorPalette = finalPalette
        }
        
        container.objectWillChange.send()
        parentModeManager.resetInactivityTimer()
        
        print("✅ Saved song image with color palette for '\(song.title)'")
        dismiss()
    }
}