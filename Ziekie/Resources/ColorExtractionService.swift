//
//  ColorExtractionService.swift
//  Ziekie
//
//  Complete color extraction service - no external packages needed
//

import SwiftUI
import UIKit

// MARK: - Color Extraction Service
@MainActor
class ColorExtractionService: ObservableObject {
    static let shared = ColorExtractionService()
    
    private init() {}
    
    // MARK: - Main Color Extraction Method
    func extractColors(from image: UIImage) async throws -> ColorPalette {
        print("🎨 Starting color extraction from image...")
        
        return try await withCheckedThrowingContinuation { continuation in
            // Run color extraction on background thread
            Task.detached(priority: .userInitiated) {
                do {
                    // Extract key colors using our custom implementation
                    let keyColors = try image.extractKeyColors(count: 8)
                    
                    // Process colors and create palette
                    let palette = await self.createSmartPalette(from: keyColors)
                    
                    await MainActor.run {
                        print("✅ Color extraction complete")
                        continuation.resume(returning: palette)
                    }
                } catch {
                    await MainActor.run {
                        print("❌ Color extraction failed: \(error)")
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    // MARK: - Create Smart Color Palette
    private func createSmartPalette(from keyColors: [UIColor]) async -> ColorPalette {
        print("🎨 Creating palette from \(keyColors.count) key colors")
        
        // Ensure we have at least some colors
        guard !keyColors.isEmpty else {
            print("⚠️ No colors extracted, using default palette")
            return .default
        }
        
        // Sort colors by vibrancy score for better selection
        let sortedColors = keyColors.sorted { color1, color2 in
            let score1 = color1.vibrancyScore
            let score2 = color2.vibrancyScore
            return score1 > score2
        }
        
        // Extract specific color roles
        let primary = selectPrimary(from: sortedColors)
        let secondary = selectSecondary(from: sortedColors, avoiding: [primary])
        let accent = selectAccent(from: sortedColors, avoiding: [primary, secondary])
        let background = selectBackground(from: sortedColors)
        let text = selectText(for: background)
        
        let palette = ColorPalette(
            primary: primary,
            secondary: secondary,
            accent: accent,
            background: background,
            text: text
        )
        
        print("🎨 Created palette: Primary=\(primary.hexString), Secondary=\(secondary.hexString), Accent=\(accent.hexString)")
        
        return palette
    }
    
    // MARK: - Color Selection Methods
    private func selectPrimary(from colors: [UIColor]) -> UIColor {
        // Choose the most vibrant color that's not too dark or too light
        for color in colors {
            let brightness = color.brightness
            let saturation = color.saturation
            
            // Good primary colors are vibrant and not too extreme in brightness
            if brightness > 0.25 && brightness < 0.85 && saturation > 0.4 {
                return color
            }
        }
        
        // Fallback to first color or system blue
        return colors.first ?? UIColor.systemBlue
    }
    
    private func selectSecondary(from colors: [UIColor], avoiding avoided: [UIColor]) -> UIColor {
        // Find a color that's different enough from the avoided colors
        for color in colors {
            let isUnique = avoided.allSatisfy { avoidedColor in
                color.colorDistance(to: avoidedColor) > 0.3
            }
            
            if isUnique {
                return color
            }
        }
        
        // Create a complementary color if none found
        if let primary = avoided.first {
            return primary.complementary ?? UIColor.systemMint
        }
        
        return UIColor.systemMint
    }
    
    private func selectAccent(from colors: [UIColor], avoiding avoided: [UIColor]) -> UIColor {
        // Find a bright, saturated color for highlights
        for color in colors {
            let isUnique = avoided.allSatisfy { avoidedColor in
                color.colorDistance(to: avoidedColor) > 0.25
            }
            
            // Accent colors should be bright and attention-grabbing
            if isUnique && color.saturation > 0.6 && color.brightness > 0.4 {
                return color
            }
        }
        
        // Fallback to a bright color
        return UIColor.systemPurple
    }
    
    private func selectBackground(from colors: [UIColor]) -> UIColor {
        // Find the lightest color that could work as a background
        let lightColors = colors.filter { $0.brightness > 0.75 }
        let candidate = lightColors.max { $0.brightness < $1.brightness }
        
        // Ensure it's light enough for text readability
        if let candidate = candidate, candidate.brightness > 0.85 {
            return candidate
        }
        
        // Default to white
        return UIColor.white
    }
    
    private func selectText(for background: UIColor) -> UIColor {
        // Choose black or white based on background brightness for maximum contrast
        return background.brightness > 0.6 ? UIColor.black : UIColor.white
    }
    
    // MARK: - Convenience Methods
    func extractColorsFromImagePlayground(imageURL: URL) async throws -> ColorPalette {
        let data = try Data(contentsOf: imageURL)
        guard let image = UIImage(data: data) else {
            throw ColorExtractionError.invalidImage
        }
        
        return try await extractColors(from: image)
    }
    
    func extractColorsWithFallback(from image: UIImage?) async -> ColorPalette {
        guard let image = image else {
            print("⚠️ No image provided, using default palette")
            return .default
        }
        
        do {
            return try await extractColors(from: image)
        } catch {
            print("⚠️ Color extraction failed, using default palette: \(error)")
            return .default
        }
    }
}

// MARK: - Color Extraction Errors
enum ColorExtractionError: Error, LocalizedError {
    case invalidImage
    case extractionFailed
    case insufficientColors
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .extractionFailed:
            return "Failed to extract colors"
        case .insufficientColors:
            return "Not enough distinct colors found"
        }
    }
}

// MARK: - UIImage Color Extraction Extension
extension UIImage {
    /// Extract dominant colors from the image
    func extractKeyColors(count: Int = 5) throws -> [UIColor] {
        guard let cgImage = self.cgImage else {
            throw ColorExtractionError.invalidImage
        }
        
        // Resize image for faster processing
        let resizedImage = resizeForColorExtraction()
        guard let resizedCGImage = resizedImage.cgImage else {
            throw ColorExtractionError.extractionFailed
        }
        
        // Extract colors using pixel sampling
        let colors = extractDominantColors(from: resizedCGImage, targetCount: count)
        
        // Filter and process colors
        return processExtractedColors(colors, targetCount: count)
    }
    
    // MARK: - Private Helper Methods
    
    private func resizeForColorExtraction() -> UIImage {
        let targetSize = CGSize(width: 150, height: 150)
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    private func extractDominantColors(from cgImage: CGImage, targetCount: Int) -> [UIColor] {
        let width = cgImage.width
        let height = cgImage.height
        
        // Create bitmap context
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return defaultColorSet(count: targetCount)
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let data = context.data else {
            return defaultColorSet(count: targetCount)
        }
        
        // Sample pixels and count colors
        var colorCounts: [String: (color: UIColor, count: Int)] = [:]
        let pixelData = data.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)
        
        // Sample every nth pixel for performance
        let sampleRate = max(1, min(10, width / 20))
        
        for y in stride(from: 0, to: height, by: sampleRate) {
            for x in stride(from: 0, to: width, by: sampleRate) {
                let pixelIndex = (y * width + x) * bytesPerPixel
                
                let red = CGFloat(pixelData[pixelIndex]) / 255.0
                let green = CGFloat(pixelData[pixelIndex + 1]) / 255.0
                let blue = CGFloat(pixelData[pixelIndex + 2]) / 255.0
                let alpha = CGFloat(pixelData[pixelIndex + 3]) / 255.0
                
                // Skip transparent or very extreme pixels
                if alpha < 0.5 {
                    continue
                }
                
                let brightness = (red + green + blue) / 3.0
                if brightness < 0.05 || brightness > 0.95 {
                    continue
                }
                
                // Group similar colors together (reduce precision)
                let colorKey = String(format: "%.1f-%.1f-%.1f", 
                                     round(red * 10) / 10,
                                     round(green * 10) / 10,
                                     round(blue * 10) / 10)
                
                let color = UIColor(red: red, green: green, blue: blue, alpha: 1.0)
                
                if let existing = colorCounts[colorKey] {
                    colorCounts[colorKey] = (color: existing.color, count: existing.count + 1)
                } else {
                    colorCounts[colorKey] = (color: color, count: 1)
                }
            }
        }
        
        // Sort by frequency and vibrancy
        let sortedColors = colorCounts.values
            .sorted { first, second in
                let firstScore = first.count * Int(first.color.vibrancyScore * 100)
                let secondScore = second.count * Int(second.color.vibrancyScore * 100)
                return firstScore > secondScore
            }
            .map { $0.color }
        
        return Array(sortedColors.prefix(targetCount * 2)) // Get more than needed for filtering
    }
    
    private func processExtractedColors(_ colors: [UIColor], targetCount: Int) -> [UIColor] {
        guard !colors.isEmpty else {
            return defaultColorSet(count: targetCount)
        }
        
        // Filter out colors that are too similar
        var uniqueColors: [UIColor] = []
        
        for color in colors {
            let isUnique = uniqueColors.allSatisfy { existingColor in
                color.colorDistance(to: existingColor) > 0.15 // Minimum distance for uniqueness
            }
            
            if isUnique {
                uniqueColors.append(color)
            }
            
            if uniqueColors.count >= targetCount {
                break
            }
        }
        
        // Fill with defaults if needed
        let defaults = defaultColorSet(count: targetCount)
        while uniqueColors.count < targetCount && uniqueColors.count < defaults.count {
            let defaultColor = defaults[uniqueColors.count]
            uniqueColors.append(defaultColor)
        }
        
        return uniqueColors
    }
    
    private func defaultColorSet(count: Int) -> [UIColor] {
        let defaults: [UIColor] = [
            .systemBlue,
            .systemMint,
            .systemPurple,
            .systemOrange,
            .systemGreen,
            .systemRed,
            .systemYellow,
            .systemPink,
            .systemIndigo,
            .systemTeal
        ]
        
        return Array(defaults.prefix(count))
    }
}

// MARK: - UIColor Extensions for Color Analysis
extension UIColor {
    var brightness: CGFloat {
        var brightness: CGFloat = 0
        getHue(nil, saturation: nil, brightness: &brightness, alpha: nil)
        return brightness
    }
    
    var saturation: CGFloat {
        var saturation: CGFloat = 0
        getHue(nil, saturation: &saturation, brightness: nil, alpha: nil)
        return saturation
    }
    
    var hue: CGFloat {
        var hue: CGFloat = 0
        getHue(&hue, saturation: nil, brightness: nil, alpha: nil)
        return hue
    }
    
    /// Calculate how vibrant/appealing this color is for UI use
    var vibrancyScore: CGFloat {
        let saturationWeight: CGFloat = 0.4
        let brightnessWeight: CGFloat = 0.3
        let balanceWeight: CGFloat = 0.3
        
        // Prefer moderate brightness (not too dark or too light)
        let brightnessOptimal: CGFloat = 0.6
        let brightnessScore = 1.0 - abs(brightness - brightnessOptimal) / brightnessOptimal
        
        // Prefer higher saturation
        let saturationScore = saturation
        
        // Prefer colors that aren't too extreme in any channel
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let balance = 1.0 - abs(r - g) - abs(g - b) - abs(b - r)
        let balanceScore = max(0, balance)
        
        return saturationScore * saturationWeight + 
               brightnessScore * brightnessWeight + 
               balanceScore * balanceWeight
    }
    
    /// Calculate color distance for uniqueness checking
    func colorDistance(to other: UIColor) -> CGFloat {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        let distance = sqrt(pow(r1-r2, 2) + pow(g1-g2, 2) + pow(b1-b2, 2))
        return distance
    }
    
    /// Generate complementary color
    var complementary: UIColor? {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        guard getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
            return nil
        }
        
        let complementaryHue = hue + 0.5
        let normalizedHue = complementaryHue > 1.0 ? complementaryHue - 1.0 : complementaryHue
        
        return UIColor(hue: normalizedHue, saturation: saturation, brightness: brightness, alpha: alpha)
    }
    
    /// Hex string representation for debugging
    var hexString: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        return String(format: "#%02X%02X%02X",
                     Int(r * 255),
                     Int(g * 255),
                     Int(b * 255))
    }
}

#Preview {
    Text("Color Extraction Service Ready!")
        .foregroundColor(.blue)
}