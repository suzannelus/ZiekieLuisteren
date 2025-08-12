import UIKit
import Photos

// ENHANCED PhotoSaver with format conversion
class PhotoSaver: NSObject {
    static let shared = PhotoSaver()
    
    enum ImageFormat {
        case heic      // Original Apple format (smaller file, Apple ecosystem only)
        case png       // Best for Xcode projects (lossless, transparency support)
        case jpeg(quality: CGFloat) // Best for sharing (universal compatibility)
        
        var fileExtension: String {
            switch self {
            case .heic: return "heic"
            case .png: return "png"
            case .jpeg: return "jpg"
            }
        }
    }
    
    // OPTION 1: Save with format conversion (RECOMMENDED)
    func saveImageToPhotos(_ image: UIImage, format: ImageFormat = .png, completion: @escaping (Bool, String) -> Void) {
        guard Bundle.main.object(forInfoDictionaryKey: "NSPhotoLibraryAddUsageDescription") != nil else {
            DispatchQueue.main.async {
                completion(false, "Missing photo library permission in Info.plist.")
            }
            return
        }
        
        DispatchQueue.main.async {
            self.requestPhotoLibraryPermission { granted in
                if granted {
                    self.performSave(image, format: format, completion: completion)
                } else {
                    completion(false, "Photo library access denied. Please enable in Settings.")
                }
            }
        }
    }
    
    // OPTION 2: Save both PNG and HEIC versions
    func saveImageBothFormats(_ image: UIImage, completion: @escaping (Bool, String) -> Void) {
        var savedCount = 0
        var errors: [String] = []
        
        let group = DispatchGroup()
        
        // Save PNG version
        group.enter()
        saveImageToPhotos(image, format: .png) { success, message in
            if success {
                savedCount += 1
            } else {
                errors.append("PNG: \(message)")
            }
            group.leave()
        }
        
        // Save HEIC version
        group.enter()
        saveImageToPhotos(image, format: .heic) { success, message in
            if success {
                savedCount += 1
            } else {
                errors.append("HEIC: \(message)")
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            if savedCount > 0 {
                completion(true, "✅ Saved \(savedCount) version(s) to Photos")
            } else {
                completion(false, "❌ Failed to save: \(errors.joined(separator: ", "))")
            }
        }
    }
    
    private func performSave(_ image: UIImage, format: ImageFormat, completion: @escaping (Bool, String) -> Void) {
        let convertedImage = convertImage(image, to: format)
        
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest.creationRequestForAsset(from: convertedImage)
            request.creationDate = Date()
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(true, "✅ Image saved as \(format.fileExtension.uppercased()) to Photos!")
                } else {
                    let errorMessage = error?.localizedDescription ?? "Failed to save image"
                    completion(false, "❌ \(errorMessage)")
                }
            }
        }
    }
    
    private func convertImage(_ image: UIImage, to format: ImageFormat) -> UIImage {
        switch format {
        case .png:
            if let pngData = image.pngData() {
                return UIImage(data: pngData) ?? image
            }
        case .jpeg(let quality):
            if let jpegData = image.jpegData(compressionQuality: quality) {
                return UIImage(data: jpegData) ?? image
            }
        case .heic:
            // Keep original (likely already HEIC from Image Playground)
            return image
        }
        return image
    }
    
    private func requestPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        switch status {
        case .authorized, .limited:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                DispatchQueue.main.async {
                    completion(newStatus == .authorized || newStatus == .limited)
                }
            }
        @unknown default:
            completion(false)
        }
    }
}

