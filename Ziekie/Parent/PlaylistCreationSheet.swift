import SwiftUI
import MusicKit
import ImagePlayground


struct PlaylistCreationSheet: View {
    @StateObject private var parentModeManager = ParentModeManager.shared
    @StateObject private var colorExtractor = ColorExtractionService.shared
    @StateObject private var container = PlaylistsContainer.shared
    
    
    @State private var playlistName = ""
    @State private var generatedImage: Image?
    @State private var generatedUIImage: UIImage?
    @State private var isShowingImagePlayground = false
    @State private var extractedPalette: ColorPalette?
    @State private var isExtractingColors = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("Playlist Name", text: $playlistName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                if let image = generatedImage {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 200)
                        .cornerRadius(10)
                        .overlay(alignment: .topTrailing) {
                            Button {
                                isShowingImagePlayground = true
                            } label: {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .padding(8)
                                    .background(.regularMaterial)
                                    .clipShape(Circle())
                            }
                            .padding(8)
                        }
                } else {
                    Button {
                        if !playlistName.isEmpty {
                            isShowingImagePlayground = true
                        }
                    } label: {
                        VStack {
                            Image(systemName: "photo.circle.fill")
                                .font(.system(size: 100))
                                .foregroundColor(playlistName.isEmpty ? .gray : .mint)
                            
                            Text(playlistName.isEmpty ? "Enter a name first" : "Tap to generate image")
                                .caption()
                                .foregroundColor(playlistName.isEmpty ? .gray : .mint)
                        }
                    }
                    .disabled(playlistName.isEmpty)
                }
                
                Spacer()
                
                Button("Create Playlist") {
                    Task {
                        await createPlaylist()
                    }
                }
                .font(.custom("QuicksandBook-Regular-bold", size: 18))
                .padding()
                .foregroundStyle(Color.white)
                .glassEffect(.regular.tint(.mint).interactive())
                .disabled(playlistName.isEmpty || generatedImage == nil)
            }
            .padding()
            .navigationTitle("New Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .onTapGesture {
                // Add this for any interaction
                parentModeManager.resetInactivityTimer()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .imagePlaygroundSheet(
                isPresented: $isShowingImagePlayground,
                concept: playlistName,
                sourceImage: nil
            ) { url in
                if let data = try? Data(contentsOf: url),
                   let uiImage = UIImage(data: data) {
                    generatedImage = Image(uiImage: uiImage)
                }
            }
        }
    }
    
    // MARK: - Color Extraction Section
    @ViewBuilder
    private var colorExtractionSection: some View {
        if isExtractingColors {
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.mint)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Extracting colors...")
                        .font(.caption)
                        .foregroundColor(.primary)
                    
                    Text("Creating your color theme")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(.gray.opacity(0.1))
            .cornerRadius(8)
        } else if let palette = extractedPalette {
            ColorPreviewCard(palette: palette, playlistName: playlistName)
        }
    }
    
    // CLEAN: Single async method that works with new container
    
    @ViewBuilder
    private var createPlaylistButton: some View {
        Button("Create Playlist") {
            Task {
                await createPlaylist()
            }
        }
        .font(.custom("QuicksandBook-Regular-bold", size: 18))
        .padding()
        .foregroundStyle(Color.white)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            extractedPalette?.primaryColor ?? .mint,
                            extractedPalette?.accentColor ?? .purple
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .shadow(
            color: (extractedPalette?.primaryColor ?? .mint).opacity(0.3),
            radius: 8,
            x: 0,
            y: 4
        )
        .disabled(playlistName.isEmpty || generatedImage == nil)
        .scaleEffect(playlistName.isEmpty || generatedImage == nil ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: playlistName.isEmpty)
        .animation(.easeInOut(duration: 0.2), value: generatedImage)
    }
    private func handleGeneratedImage(url: URL) async {
        do {
            print("🖼️ Processing generated image from ImagePlayground...")
            
            // Load image data
            let data = try Data(contentsOf: url)
            guard let uiImage = UIImage(data: data) else {
                print("❌ Failed to create UIImage from data")
                return
            }
            
            // Update UI immediately with the image
            await MainActor.run {
                self.generatedUIImage = uiImage
                self.generatedImage = Image(uiImage: uiImage)
                self.isExtractingColors = true
                self.extractedPalette = nil
                print("🖼️ Image loaded, starting color extraction...")
            }
            
            // Extract colors in background
            do {
                let palette = try await colorExtractor.extractColors(from: uiImage)
                
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        self.extractedPalette = palette
                        self.isExtractingColors = false
                    }
                    parentModeManager.resetInactivityTimer()
                    print("✅ Color extraction complete for playlist: \(playlistName)")
                    print("🎨 Primary: \(palette.primaryColor)")
                    print("🎨 Secondary: \(palette.secondaryColor)")
                    print("🎨 Accent: \(palette.accentColor)")
                }
            } catch {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.extractedPalette = .default
                        self.isExtractingColors = false
                    }
                    print("⚠️ Using default palette due to extraction error: \(error)")
                }
            }
            
        } catch {
            print("❌ Failed to load generated image: \(error)")
            await MainActor.run {
                self.isExtractingColors = false
            }
        }
    }
    
    // MARK: - Create Playlist with Colors
    @MainActor
    private func createPlaylist() async {
        guard !playlistName.isEmpty,
              let image = generatedImage else {
            print("❌ Cannot create playlist: missing name or image")
            return
        }
        
        let finalPalette = extractedPalette ?? .default
        
        print("📝 Creating playlist: \(playlistName) with color palette")
        print("🎨 Using colors - Primary: \(finalPalette.primaryColor), Secondary: \(finalPalette.secondaryColor)")
        
        parentModeManager.resetInactivityTimer()
        
        // Create playlist with color information using the corrected parameter name
        await container.createPlaylistAsync(
            name: playlistName,
            image: image,
            concept: playlistName,
            songs: [],
            palette: finalPalette  // Using 'palette' parameter name as corrected in Data.swift
        )
        
        print("✅ Playlist created successfully with colors")
        dismiss()
    }
    
}



// MARK: - Color Preview Card Component
struct ColorPreviewCard: View {
    let palette: ColorPalette
    let playlistName: String
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Color Theme")
                    .font(.headline)
                    .foregroundColor(palette.textColor)
                
                Spacer()
                
                ColorPalettePreview(palette: palette)
            }
            
            // Sample text with extracted colors
            VStack(alignment: .leading, spacing: 8) {
                Text(playlistName)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(palette.primaryColor)
                
                Text("This playlist will use these beautiful colors")
                    .bodyLarge()
                    .foregroundColor(palette.textColor)
                
                HStack {
                    Label("Songs", systemImage: "music.note")
                        .bodyLarge()
                        .foregroundColor(palette.secondaryColor)
                    
                    Spacer()
                    
                    Text("Colorful!")
                        .bodyLarge()
                        .fontWeight(.bold)
                        .foregroundColor(palette.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(palette.accentColor.opacity(0.2))
                        .cornerRadius(4)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [
                    palette.backgroundColor,
                    palette.backgroundColor.opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [
                            palette.primaryColor.opacity(0.6),
                            palette.accentColor.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(
            color: palette.primaryColor.opacity(0.2),
            radius: 8,
            x: 0,
            y: 4
        )
    }
}


#Preview {
    PlaylistCreationSheet()
}



