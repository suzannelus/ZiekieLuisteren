//
//  ImageAssetLoader.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 29/07/2025.
//


import SwiftUI
import UIKit

@MainActor
class ImageAssetLoader {
    static let shared = ImageAssetLoader()
    
    // CACHE: Store loaded images to avoid repeated lookups
    private var imageCache: [String: Image] = [:]
    
    // FALLBACK: Always available placeholder
    private let fallbackImage = Image(systemName: "music.note")
    
    private init() {}
    
    /// Load image from assets with caching and fallback
    func loadImage(named imageName: String) -> Image {
        // Check cache first
        if let cachedImage = imageCache[imageName] {
            return cachedImage
        }
        
        // Try to load from assets using standardized name
        let standardizedName = standardizeName(imageName)
        
        if let uiImage = UIImage(named: standardizedName) {
            let image = Image(uiImage: uiImage)
            imageCache[imageName] = image // Cache using original name as key
            
            #if DEBUG
            print("✅ Loaded: '\(imageName)' -> '\(standardizedName)'")
            #endif
            
            return image
        }
        
        // Try exact name as backup
        if standardizedName != imageName,
           let uiImage = UIImage(named: imageName) {
            let image = Image(uiImage: uiImage)
            imageCache[imageName] = image
            
            #if DEBUG
            print("✅ Loaded exact: '\(imageName)'")
            #endif
            
            return image
        }
        
        // Cache the fallback to avoid repeated lookups
        imageCache[imageName] = fallbackImage
        
        #if DEBUG
        print("⚠️ Using fallback for: '\(imageName)'")
        #endif
        
        return fallbackImage
    }
    
    /// STANDARDIZE: Convert any name to consistent format
    /// Strategy: kebab-case (lowercase with hyphens)
    private func standardizeName(_ name: String) -> String {
        return name
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: ".", with: "")
    }
    
    /// Preload common images (optional - call during app startup)
    func preloadCommonImages(_ imageNames: [String]) {
        for name in imageNames {
            _ = loadImage(named: name) // This will cache them
        }
        
        #if DEBUG
        print("📦 Preloaded \(imageNames.count) images")
        #endif
    }
    
    /// Clear cache if needed (for memory management)
    func clearCache() {
        imageCache.removeAll()
        
        #if DEBUG
        print("🗑️ Image cache cleared")
        #endif
    }
}