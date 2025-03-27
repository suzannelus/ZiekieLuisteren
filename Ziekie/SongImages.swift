//
//  SongImages.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 02/02/2025.
//

import SwiftUI
import ImagePlayground
import PhotosUI


struct SongImages: View {
    
    @Binding var musicItem: MusicItem

    @Environment(\.supportsImagePlayground) var supportsImagePlayground
    
    @Binding var generatedImage: Image?

    @State private var imageGenerationConcepts: String
        @State private var isShowingImagePlayground = false

    @State private var avatarImage: Image?
    @State private var photosPickerItem: PhotosPickerItem?
    
    init(musicItem: Binding<MusicItem>, generatedImage: Binding<Image?>) {
            self._musicItem = musicItem
            self._generatedImage = generatedImage
            // Initialize imageGenerationConcepts with the stored value or empty string
            self._imageGenerationConcepts = State(initialValue: musicItem.wrappedValue.imageGenerationConcepts ?? "")
        }
    
    
    var body: some View {
        VStack(spacing: 32) {
            HStack(spacing: 20) {
                
                VStack(alignment: .leading) {
                    Text(musicItem.title)
                        .font(.title.bold())
                    
                    if let image = musicItem.customImage ?? generatedImage {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        Image(musicItem.image ?? "")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                    }
                }
                
                TextField("Enter song description", text: $imageGenerationConcepts)
                    .font(.title3)
                    .padding()
                    .background(.quaternary, in: .rect(cornerRadius: 16, style: .continuous))
                
                Button("Generate Image", systemImage: "sparkles") {
                    isShowingImagePlayground = true
                }
                .padding()
                .foregroundStyle(.mint)
                .fontWeight(.bold)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.mint, lineWidth: 2)
                )
                
                .padding(30)
                .imagePlaygroundSheet(isPresented: $isShowingImagePlayground,
                                      concept: imageGenerationConcepts,
                                      sourceImage: nil) { url in
                    if let data = try? Data(contentsOf: url),
                       let image = UIImage(data: data) {
                        generatedImage = Image(uiImage: image)
                        musicItem.customImage = generatedImage
                    }
                }
                
                
                
                Spacer()
                
                
            }
            
            
            //   if supportsImagePlayground {
            TextField("Enter song description", text: $imageGenerationConcepts)
                .font(.title.bold())
                .padding()
                .background(.quaternary, in: .rect(cornerRadius: 16, style: .continuous))
            Button("Generate Image", systemImage: "sparkles") {
                isShowingImagePlayground = true
            }
            .padding()
            .foregroundStyle(.mint)
            .fontWeight(.bold)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.mint, lineWidth: 2)
            )
            
            //    }
        }
        .padding(30)
        .onChange(of: photosPickerItem) { _, _ in
            Task {
                if let photosPickerItem, let data = try? await photosPickerItem.loadTransferable(type: Data.self) {
                    if let image = UIImage(data: data) { avatarImage = Image(uiImage: image) }
                }
            }
        }
        .imagePlaygroundSheet(isPresented: $isShowingImagePlayground,
                              concept: imageGenerationConcepts,
                              sourceImage: nil) { url in
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                generatedImage = Image(uiImage: image)
                musicItem.customImage = generatedImage
                musicItem.imageGenerationConcepts = imageGenerationConcepts
            }
        }
        
    }
}



/*
struct SongImages_Previews: PreviewProvider {
    static var previews: some View {
        // Create a State wrapper for the preview
        @State var previewMusicItem = musicItems[0]
        @State var previewImage: Image? = nil
        
        return SongImages(
            musicItem: Binding(
                get: { previewMusicItem },
                set: { previewMusicItem = $0 }
            ),
            generatedImage: Binding(
                get: { previewImage },
                set: { previewImage = $0 }
            )
        )
    }
}
*/
