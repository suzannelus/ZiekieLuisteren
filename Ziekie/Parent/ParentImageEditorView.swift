//
//  ParentImageEditorView.swift
//

import SwiftUI
import ImagePlayground
import PhotosUI
import Photos // photo saver


struct ParentImageEditorView: View {
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
    
    // phot saver - can delete later
    @State private var showingSaveSuccess = false
    @State private var saveMessage = ""
    @State private var saveSuccessful = false

    
    init(playlist: Playlist) {
        self.playlist = playlist
        self._imageGenerationConcept = State(initialValue: playlist.imageGenerationConcept ?? playlist.name)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .colorScheme(.dark)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Current image section
                        currentImageSection
                        
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
        .navigationTitle("Edit Playlist Image")
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
        // Monitor ImagePlayground sheet state changes
                .onChange(of: isShowingImagePlayground) { _, newValue in
                    // Reset timer when sheet opens or closes
                    parentModeManager.resetInactivityTimer()
                    
                    if newValue {
                        // ImagePlayground is opening - start periodic resets
                        startImagePlaygroundTimerResets()
                        print("🎨 ImagePlayground opened - starting periodic timer resets")
                    } else {
                        // ImagePlayground is closing - stop periodic resets
                        stopImagePlaygroundTimerResets()
                        print("🎨 ImagePlayground closed - stopped periodic timer resets")
                    }
                }
                .onChange(of: selectedPhotoItem) { _, newItem in
                    loadSelectedPhoto(newItem)
                }
                .onTapGesture {
                    parentModeManager.resetInactivityTimer()
                }
                .onAppear {
                    parentModeManager.resetInactivityTimer()
                }
                // ✅ ADD THIS: Cleanup timer when view disappears
                .onDisappear {
                    stopImagePlaygroundTimerResets()
                }
            }
            
            // ✅ ADD THESE METHODS: Timer management for ImagePlayground
            private func startImagePlaygroundTimerResets() {
                // Stop any existing timer first
                stopImagePlaygroundTimerResets()
                
                // Start a timer that resets the inactivity timer every 30 seconds
                // while ImagePlayground is open
                imagePlaygroundTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
                    if parentModeManager.isParentModeActive {
                        parentModeManager.resetInactivityTimer()
                        print("🎨 ImagePlayground active - auto-resetting parent mode timer")
                    }
                }
            }
            
            private func stopImagePlaygroundTimerResets() {
                imagePlaygroundTimer?.invalidate()
                imagePlaygroundTimer = nil
            }
            
            // MARK: - Current Image Section
    private var currentImageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Image")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
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
                .frame(width: 120, height: 120)
                .cornerRadius(12)
                .shadow(radius: 4)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(playlist.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("\(playlist.songs.count) songs")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    if let concept = playlist.imageGenerationConcept {
                        Text("Theme: \(concept)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    // Show current colors if available
                    if let palette = playlist.colorPalette {
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
                    
                    TextField("e.g., Colorful cartoon animals playing music", text: $imageGenerationConcept)
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
                VStack(alignment: .leading, spacing: 8) {
                    Text("New Image Preview")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    newImage
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                    
                    HStack {
                        Button("Try Again") {
                            generateNewImageWithColors()
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.orange)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                        
                        Spacer()
                        
                        Button("Use This Image") {
                            saveImageWithColors()
                            Task { @MainActor in
                                container.playlists = container.playlists  // Force UI refresh
                            }
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.green)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                        Button("Save to Photos App") {
                            saveImageToPhotos(format: .png)
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding()
                .background(.green.opacity(0.1))
                .cornerRadius(12)
                .alert("Save Result", isPresented: $showingSaveSuccess) {
                    Button("OK") {
                        showingSaveSuccess = false
                    }
                } message: {
                    Text(saveMessage)
                }
            }
        }
        .padding()
        .background(.gray.opacity(0.2))
        .cornerRadius(12)
    }
    
    // photo saver
    private func saveImageToPhotos(format: PhotoSaver.ImageFormat = .png) {
        guard let uiImage = newUIImage else {
            saveMessage = "No image available to save"
            saveSuccessful = false
            showingSaveSuccess = true
            return
        }
        
        isExtractingColors = true
        
        PhotoSaver.shared.saveImageToPhotos(uiImage, format: format) { success, message in
            
            DispatchQueue.main.async {
                self.isExtractingColors = false
                self.saveMessage = message
                self.saveSuccessful = success
                self.showingSaveSuccess = true
                self.parentModeManager.resetInactivityTimer()
            }
        }
    }
    
    
    // MARK: - Color Results Section
    private func colorResultsSection(palette: ColorPalette) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Extracted Colors")
                .font(.headline)
                .foregroundColor(.white)
            
            ColorPreviewCard(palette: palette, playlistName: playlist.name)
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
                Text("Image and color palette will be saved")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Text("Image will be saved with default colors")
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
                    print("✅ Color extraction complete for updated playlist image")
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
        guard let playlistIndex = container.playlists.firstIndex(where: { $0.id == playlist.id }),
              let newImage = newImage else { return }
        
        let finalPalette = extractedPalette ?? .default
        
        withAnimation {
            container.playlists[playlistIndex].customImage = newImage
            container.playlists[playlistIndex].imageGenerationConcept = imageGenerationConcept
            container.playlists[playlistIndex].colorPalette = finalPalette
        }
        
        container.objectWillChange.send()
        parentModeManager.resetInactivityTimer()
        
        print("✅ Saved playlist image with color palette")
        dismiss()
    }
}



struct ColorPalettePreview: View {
    let palette: ColorPalette
    let size: CGFloat = 20
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(palette.primaryColor)
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.8), lineWidth: 1.5)
                )
                .shadow(color: palette.primaryColor.opacity(0.4), radius: 2, x: 0, y: 1)
            
            Circle()
                .fill(palette.secondaryColor)
                .frame(width: size * 0.8, height: size * 0.8)
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.8), lineWidth: 1)
                )
                .shadow(color: palette.secondaryColor.opacity(0.4), radius: 2, x: 0, y: 1)
            
            Circle()
                .fill(palette.accentColor)
                .frame(width: size * 0.6, height: size * 0.6)
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.8), lineWidth: 1)
                )
                .shadow(color: palette.accentColor.opacity(0.4), radius: 2, x: 0, y: 1)
        }
    }
}

