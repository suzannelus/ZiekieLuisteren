//
//  ColorPalette.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 27/07/2025.
//


struct ColorPalette: Codable, Hashable {
    let primary: CodableColor      // Main dominant color
    let secondary: CodableColor    // Secondary color 
    let accent: CodableColor       // Accent/highlight color
    let background: CodableColor   // Background color (usually light)
    let text: CodableColor         // Text color (usually dark)
    
    // Computed SwiftUI Colors
    var primaryColor: Color { Color(primary) }
    var secondaryColor: Color { Color(secondary) }
    var accentColor: Color { Color(accent) }
    var backgroundColor: Color { Color(background) }
    var textColor: Color { Color(text) }
    
    // Default palette fallback
    static let `default` = ColorPalette(
        primary: CodableColor(.blue),
        secondary: CodableColor(.mint),
        accent: CodableColor(.purple),
        background: CodableColor(.white),
        text: CodableColor(.black)
    )
    
    // Create palette from UIColors
    init(primary: UIColor, secondary: UIColor, accent: UIColor, background: UIColor, text: UIColor) {
        self.primary = CodableColor(primary)
        self.secondary = CodableColor(secondary)
        self.accent = CodableColor(accent)
        self.background = CodableColor(background)
        self.text = CodableColor(text)
    }
}

// MARK: - Codable Color Wrapper
struct CodableColor: Codable, Hashable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double
    
    init(_ color: Color) {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        self.red = Double(red)
        self.green = Double(green)
        self.blue = Double(blue)
        self.alpha = Double(alpha)
    }
    
    init(_ uiColor: UIColor) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        self.red = Double(red)
        self.green = Double(green)
        self.blue = Double(blue)
        self.alpha = Double(alpha)
    }
}

extension Color {
    init(_ codableColor: CodableColor) {
        self.init(
            red: codableColor.red,
            green: codableColor.green,
            blue: codableColor.blue,
            opacity: codableColor.alpha
        )
    }
}

extension UIColor {
    convenience init(_ codableColor: CodableColor) {
        self.init(
            red: codableColor.red,
            green: codableColor.green,
            blue: codableColor.blue,
            alpha: codableColor.alpha
        )
    }
}

// MARK: - Updated Playlist Model
struct UpdatedPlaylist: Identifiable, Hashable, Codable {
    let id = UUID()
    var name: String
    var customImage: Image?
    var imageGenerationConcept: String?
    var songs: [UpdatedMusicItem]
    
    // NEW: Color palette extracted from image
    var colorPalette: ColorPalette?
    
    // MARK: - Initializers
    init(name: String, customImage: Image? = nil, imageGenerationConcept: String? = nil, songs: [UpdatedMusicItem] = [], colorPalette: ColorPalette? = nil) {
        self.name = name
        self.customImage = customImage
        self.imageGenerationConcept = imageGenerationConcept
        self.songs = songs
        self.colorPalette = colorPalette
    }
    
    // MARK: - Codable Implementation (same as before, but exclude customImage)
    enum CodingKeys: String, CodingKey {
        case id, name, imageGenerationConcept, songs, colorPalette
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(imageGenerationConcept, forKey: .imageGenerationConcept)
        try container.encode(songs, forKey: .songs)
        try container.encode(colorPalette, forKey: .colorPalette)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedId = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.imageGenerationConcept = try container.decodeIfPresent(String.self, forKey: .imageGenerationConcept)
        self.songs = try container.decode([UpdatedMusicItem].self, forKey: .songs)
        self.colorPalette = try container.decodeIfPresent(ColorPalette.self, forKey: .colorPalette)
        self.customImage = nil // Will be loaded separately
    }
    
    // MARK: - Color Helpers
    var effectivePalette: ColorPalette {
        return colorPalette ?? .default
    }
    
    static func == (lhs: UpdatedPlaylist, rhs: UpdatedPlaylist) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}