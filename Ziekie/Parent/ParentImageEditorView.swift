//
//  ParentImageEditorView.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 15/07/2025.
//


import SwiftUI
import ImagePlayground
import PhotosUI

struct ParentImageEditorView: View {
    let playlist: Playlist
    @Environment(\.dismiss) private var dismiss
    @StateObject private var container = PlaylistsContainer.shared
    @StateObject private var parentModeManager = ParentModeManager.shared
    
    @State private var newImage: Image?
    @State private var imageGenerationConcept: String
    @State private var isShowingImagePlayground = false
    @State private var isGeneratingImage = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    
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
                        imageGenerationSection
                        
                        // Alternative image options
                        alternativeOptionsSection
                        
                        // Save section
                        if newImage != nil {
                            saveSection
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
                        saveNewImage()
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
            handleGeneratedImage(url: url)
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            loadSelectedPhoto(newItem)
        }
        .onTapGesture {
            parentModeManager.resetInactivityTimer()
        }
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
                    
                    if let concept = playlist.imageGenerationConcept {
                        Text("Theme: \(concept)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Text("Tap 'Generate New' to create a fresh image")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(.gray.opacity(0.2))
        .cornerRadius(12)
    }
    
    // MARK: - Image Generation Section
    private var imageGenerationSection: some View {
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
                
                // Generate button
                Button(action: {
                    generateNewImage()
                }) {
                    HStack {
                        if isGeneratingImage {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        
                        Text(isGeneratingImage ? "Generating..." : "Generate with AI")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isGeneratingImage || imageGenerationConcept.isEmpty)
            }
            
            // Preview new image
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
                            generateNewImage()
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.orange)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                        
                        Spacer()
                        
                        Button("Use This Image") {
                            saveNewImage()
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.green)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    }
                }
                .padding()
                .background(.green.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(.gray.opacity(0.2))
        .cornerRadius(12)
    }
    
    // MARK: - Alternative Options
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
    
    // MARK: - Save Section
    private var saveSection: some View {
        VStack(spacing: 12) {
            Text("Ready to Save")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("This will replace the current playlist image")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button("Save New Image") {
                saveNewImage()
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
    
    // MARK: - Helper Methods
    private func generateNewImage() {
        guard !imageGenerationConcept.isEmpty else { return }
        
        isGeneratingImage = true
        isShowingImagePlayground = true
        parentModeManager.resetInactivityTimer()
    }
    
    private func handleGeneratedImage(url: URL) {
        isGeneratingImage = false
        
        do {
            let data = try Data(contentsOf: url)
            if let uiImage = UIImage(data: data) {
                newImage = Image(uiImage: uiImage)
                parentModeManager.resetInactivityTimer()
            }
        } catch {
            print("Failed to load generated image: \(error)")
        }
    }
    
    private func loadSelectedPhoto(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        item.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                if let data = data, let uiImage = UIImage(data: data) {
                    DispatchQueue.main.async {
                        // Process through Image Playground for consistency
                        self.newImage = Image(uiImage: uiImage)
                        self.parentModeManager.resetInactivityTimer()
                    }
                }
            case .failure(let error):
                print("Failed to load photo: \(error)")
            }
        }
    }
    
    private func resetToDefault() {
        newImage = Image("WheelsOnTheBus")
        parentModeManager.resetInactivityTimer()
    }
    
    private func saveNewImage() {
        guard let playlistIndex = container.playlists.firstIndex(where: { $0.id == playlist.id }),
              let newImage = newImage else { return }
        
        withAnimation {
            container.playlists[playlistIndex].customImage = newImage
            container.playlists[playlistIndex].imageGenerationConcept = imageGenerationConcept
        }
        
        container.objectWillChange.send()
        parentModeManager.resetInactivityTimer()
        
        dismiss()
    }
}

#Preview {
    ParentImageEditorView(playlist: Playlist(name: "Test Playlist", songs: []))
        .colorScheme(.dark)
}