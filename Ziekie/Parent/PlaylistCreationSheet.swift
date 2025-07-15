import SwiftUI
import MusicKit
import ImagePlayground


struct PlaylistCreationSheet: View {
    @StateObject private var parentModeManager = ParentModeManager.shared

    @State private var playlistName = ""
    @State private var generatedImage: Image?
    @State private var isShowingImagePlayground = false
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
    
    // CLEAN: Single async method that works with new container
    @MainActor
    private func createPlaylist() async {
        guard !playlistName.isEmpty,
              let image = generatedImage else {
            print("❌ Cannot create playlist: missing name or image")
            return
        }
        
        print("📝 Creating playlist: \(playlistName)")
        parentModeManager.resetInactivityTimer()
         
        await PlaylistsContainer.shared.createPlaylistAsync(
            name: playlistName,
            image: image,
            concept: playlistName,
            songs: []
        )
        parentModeManager.resetInactivityTimer()

        print("✅ Playlist created successfully")
        dismiss()
    }
}

#Preview {
    PlaylistCreationSheet()
}



