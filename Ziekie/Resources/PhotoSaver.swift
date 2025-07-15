//
//  PhotoSaver.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 29/07/2025.
//


import Photos
import UIKit
import SwiftUI

class PhotoSaver: NSObject {
    static let shared = PhotoSaver()
    
    func saveImageToPhotos(_ image: UIImage, completion: @escaping (Bool, String) -> Void) {
        // Check and request permission
        requestPhotoLibraryPermission { granted in
            if granted {
                self.performSave(image, completion: completion)
            } else {
                DispatchQueue.main.async {
                    completion(false, "Photo library access denied. Please enable in Settings.")
                }
            }
        }
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
    
    private func performSave(_ image: UIImage, completion: @escaping (Bool, String) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(true, "Image saved to Photos successfully!")
                } else {
                    let errorMessage = error?.localizedDescription ?? "Failed to save image"
                    completion(false, errorMessage)
                }
            }
        }
    }
}
