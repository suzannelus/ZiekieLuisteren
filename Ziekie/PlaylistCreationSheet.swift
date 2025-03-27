import SwiftUI
import ImagePlayground

class PlaylistCreationViewModel: ObservableObject {
    @Published var playlistName = ""
    @Published var playlistImage: Image?
    @Published var isShowingImagePlayground = false
    @Published var isGeneratingImage = false
    
    private var imageGenerationTask: Task<Void, Never>?
    private var debounceTimer: Timer?
    
    deinit {
        imageGenerationTask?.cancel()
        debounceTimer?.invalidate()
    }
    
    func generatePlaylistImage() {
        guard !playlistName.isEmpty else { return }
        
        // Cancel any existing tasks
        imageGenerationTask?.cancel()
        debounceTimer?.invalidate()
        
        // Debounce the image generation
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.isShowingImagePlayground = true
        }
    }

    func createPlaylist() -> Bool {
        guard !playlistName.isEmpty else { return false }
        guard let image = playlistImage else { return false }
        
        PlaylistsContainer.shared.createPlaylist(
            name: playlistName,
            image: image,
            concept: playlistName
        )
        
        return true
    }
}

struct PlaylistCreationSheet: View {
    @StateObject private var viewModel = PlaylistCreationViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView { 
                VStack(spacing: 20) {
                    TextField("Playlist Name", text: $viewModel.playlistName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .onSubmit {
                            if !viewModel.playlistName.isEmpty {
                                viewModel.generatePlaylistImage()
                            }
                        }
                    
                    Group {
                        if let image = viewModel.playlistImage {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 200)
                                .cornerRadius(10)
                                .overlay(alignment: .topTrailing) {
                                    Button {
                                        viewModel.generatePlaylistImage()
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
                                if !viewModel.playlistName.isEmpty {
                                    viewModel.generatePlaylistImage()
                                }
                            } label: {
                                VStack {
                                    Image(systemName: "photo.circle.fill")
                                        .font(.system(size: 100))
                                        .foregroundColor(viewModel.playlistName.isEmpty ? .gray : .blue)
                                    
                                    Text(viewModel.playlistName.isEmpty ? "Enter a name first" : "Tap to generate image")
                                        .font(.caption)
                                        .foregroundColor(viewModel.playlistName.isEmpty ? .gray : .blue)
                                }
                            }
                            .disabled(viewModel.playlistName.isEmpty)
                        }
                    }
                    .animation(.easeInOut, value: viewModel.playlistImage)
                    
                    Spacer()
                    
                    Button("Create Playlist") {
                        if viewModel.createPlaylist() {
                            dismiss()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.playlistName.isEmpty || viewModel.playlistImage == nil)
                }
                .padding()
            }
            .navigationTitle("New Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .imagePlaygroundSheet(
                isPresented: $viewModel.isShowingImagePlayground,
                concept: viewModel.playlistName,
                sourceImage: nil
            ) { url in
                if let data = try? Data(contentsOf: url),
                   let uiImage = UIImage(data: data) {
                    viewModel.playlistImage = Image(uiImage: uiImage)
                }
            }
        }
    }
}

#Preview {
    PlaylistCreationSheet()
}
