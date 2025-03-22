//
//  ImageGeneratorView.swift
//  Ziekie
//

import SwiftUI
import ImagePlayground

struct ImageGeneratorView: View {
    let concept: String
    let onImageGenerated: (UIImage) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.supportsImagePlayground) var supportsImagePlayground
    
    @State private var imageGenerationConcepts: String
    @State private var isShowingImagePlayground = false
    @State private var generatedImage: Image?
    
    init(concept: String, onImageGenerated: @escaping (UIImage) -> Void) {
        self.concept = concept
        self.onImageGenerated = onImageGenerated
        self._imageGenerationConcepts = State(initialValue: concept)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let image = generatedImage {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Image(systemName: "photo.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.gray)
                }
                
                TextField("Enter image description", text: $imageGenerationConcepts)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button(action: {
                    isShowingImagePlayground = true
                }) {
                    Label("Generate Image", systemImage: "sparkles")
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
                
                if generatedImage != nil {
                    Button("Accept") {
                        if let uiImage = generatedImage?.asUIImage() {
                            onImageGenerated(uiImage)
                            dismiss()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            }
            .padding()
            .navigationTitle("Generate Image")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .imagePlaygroundSheet(isPresented: $isShowingImagePlayground,
                                concept: imageGenerationConcepts,
                                sourceImage: nil) { url in
                if let data = try? Data(contentsOf: url),
                   let image = UIImage(data: data) {
                    generatedImage = Image(uiImage: image)
                }
            }
        }
    }
}

// Extension to convert SwiftUI Image to UIImage
extension Image {
    func asUIImage() -> UIImage? {
        let controller = UIHostingController(rootView: self)
        let view = controller.view
        
        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: targetSize)

        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}

