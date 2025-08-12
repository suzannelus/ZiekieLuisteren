//
//  CustomFonts.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 04/07/2025.
//


import SwiftUI

extension Font {
    
    // MARK: - Responsive Merriweather (Titles)
    static func merriweatherResponsive(_ textStyle: TextStyle) -> Font {
        return .custom("Merriweather-Italic", size: 28, relativeTo: textStyle)
    }
    
    // MARK: - Responsive Quicksand (Body Text)
    static func quicksandResponsive(_ textStyle: TextStyle, weight: Font.Weight = .regular) -> Font {
        let fontName = quicksandFontName(for: weight)
        
        // Base sizes die schalen met Dynamic Type
        let baseSize: CGFloat = {
            switch textStyle {
            case .largeTitle: return 34
            case .title: return 28
            case .title2: return 22
            case .title3: return 20
            case .headline: return 17
            case .body: return 17
            case .callout: return 16
            case .subheadline: return 15
            case .footnote: return 13
            case .caption: return 16
            case .caption2: return 12
            @unknown default: return 17
            }
        }()
        
        return .custom(fontName, size: baseSize, relativeTo: textStyle)
    }
    
    // Helper method voor Quicksand font namen
    private static func quicksandFontName(for weight: Font.Weight) -> String {
        switch weight {
        case .ultraLight, .thin, .light:
            return "QuicksandLight-Regular"
        case .regular:
            return "QuicksandBook-Book"
        case .medium:
            return "QuicksandBook-Book"
        case .semibold:
            return "QuicksandBold-Regular"
        case .bold, .heavy, .black:
            return "QuicksandBold-Regular"
        default:
            return "QuicksandBook-Regular"
        }
    }
}

// MARK: - Responsive View Extensions
extension View {
    
    // MARK: - Responsive Titles (Merriweather)
    func appTitle() -> some View {
        font(.merriweatherResponsive(.largeTitle))
    }
    
    func screenTitle() -> some View {
        font(.merriweatherResponsive(.title))
    }
    
    func sectionTitle() -> some View {
        font(.merriweatherResponsive(.title2))
    }
    
    func cardTitle() -> some View {
        font(.merriweatherResponsive(.title3))
    }
    
    // MARK: - Responsive Body Text (Quicksand)
    func bodyLarge() -> some View {
        font(.quicksandResponsive(.headline, weight: .semibold))
    }
    
    func body() -> some View {
        font(.quicksandResponsive(.body, weight: .regular))
    }
    
    func bodySmall() -> some View {
        font(.quicksandResponsive(.callout, weight: .regular))
    }
    
    func button() -> some View {
        font(.quicksandResponsive(.callout, weight: .semibold))
    }
    
    func navigation() -> some View {
        font(.quicksandResponsive(.headline, weight: .medium))
    }
    
    func caption() -> some View {
        font(.quicksandResponsive(.caption, weight: .regular))
    }
    
    func captionBold() -> some View {
        font(.quicksandResponsive(.caption, weight: .semibold))
    }
    
    // Voor default font system
    func withDefaultFont(_ customFont: Font? = nil) -> some View {
        font(customFont ?? .quicksandResponsive(.body, weight: .regular))
    }
}

extension View {
    func textFieldQuicksand(_ size: CGFloat = 16) -> some View {
        font(.custom("QuicksandBook-Regular", size: size))
    }
}

// MARK: - Alternative UIKit-based approach (meer controle)
extension View {
    func quicksandScaled(_ textStyle: UIFont.TextStyle, weight: Font.Weight = .regular) -> some View {
        let fontName: String = {
            switch weight {
            case .ultraLight, .thin, .light:
                return "QuicksandLight-Regular"
            case .regular:
                return "QuicksandBook-Regular"
            case .medium:
                return "QuicksandBook-Regular"
            case .semibold:
                return "QuicksandBold-Regular"
            case .bold, .heavy, .black:
                return "QuicksandBold-Regular"
            default:
                return "QuicksandBook-Regular"
            }
        }()
        
        let baseSize = UIFont.preferredFont(forTextStyle: textStyle).pointSize
        let scaledSize = UIFontMetrics(forTextStyle: textStyle).scaledValue(for: baseSize)
        
        return font(.custom(fontName, size: scaledSize))
    }
}

/// ColorfulTextAlternatives.swift
import SwiftUI

// MARK: - Gradient Text
struct GradientText: View {
    let text: String
    let gradient: LinearGradient
    let font: Font
    
    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(gradient)
    }
}

// MARK: - Rainbow Text (Each Letter Different Color)
struct RainbowText: View {
    let text: String
    let font: Font
    let colors: [Color] = [.yellow, .teal, .blue, .pink, .purple, .orange, .cyan]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(text.enumerated()), id: \.offset) { index, character in
                Text(String(character))
                    .font(.system(.largeTitle, design: .rounded))
                    .fontWeight(.heavy)
                    .foregroundColor(colors[index % colors.count])
                    .rotationEffect(Angle(degrees: Double.random(in: -14.0...14.0)))
                    
            }
        }
    }
}




// MARK: - 3D Text Effect
struct Text3D: View {
    let text: String
    let font: Font
    let frontColor: Color
    let shadowColor: Color
    
    var body: some View {
        ZStack {
            // Shadow layers voor 3D effect
            Text(text)
                .font(font)
                .foregroundColor(shadowColor.opacity(0.3))
                .offset(x: 3, y: 3)
            
            Text(text)
                .font(font)
                .foregroundColor(shadowColor.opacity(0.5))
                .offset(x: 2, y: 2)
            
            Text(text)
                .font(font)
                .foregroundColor(shadowColor.opacity(0.7))
                .offset(x: 1, y: 1)
            
            // Front text
            Text(text)
                .font(font)
                .foregroundColor(frontColor)
        }
    }
}

// MARK: - Playful Text Styles voor Kinderapp
extension View {
    func rainbowTitle() -> some View {
        RainbowText(text: "Sample Text", font: .merriweatherResponsive(.largeTitle))
    }
    
    func gradientTitle(_ text: String) -> some View {
        GradientText(
            text: text,
            gradient: LinearGradient(
                colors: [.pink, .purple, .blue],
                startPoint: .leading,
                endPoint: .trailing
            ),
            font: .merriweatherResponsive(.title)
        )
    }
    
    func playfulTitle(_ text: String) -> some View {
        Text3D(
            text: text,
            font: .merriweatherResponsive(.title),
            frontColor: .blue,
            shadowColor: .purple
        )
    }
}

// MARK: - Fun Text Modifiers
extension View {
    func kidsTitle(_ colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]) -> some View {
        // Voor individuele letters met verschillende kleuren
        self // Dit zou je per Text view toepassen
    }
    
    func withGradient(_ colors: [Color]) -> some View {
        self.foregroundStyle(
            LinearGradient(
                colors: colors,
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
    
    func with3DEffect(_ frontColor: Color = .blue, shadowColor: Color = .purple) -> some View {
        ZStack {
            self
                .foregroundColor(shadowColor.opacity(0.3))
                .offset(x: 2, y: 2)
            
            self
                .foregroundColor(frontColor)
        }
    }
}

// MARK: - Example Usage
struct ColorfulTextExamples: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Rainbow text
            RainbowText(text: "Tune Gallery", font: .merriweatherResponsive(.title))
            // Gradient text
            Text("Tune Gallery")
                .screenTitle()
                .withGradient([.pink, .purple, .blue])
            
            
            
            // Simple rainbow modifier
            Text("🎵 Sing Along! 🎵")
                .body()
                .withGradient([.red, .orange, .yellow, .green, .blue])
            
            Text("Dit is de app titel")
            
            Text("Dit is een titel")
                .captionBold()
            Text("Dit is een body text Q")
                .bodySmall()
            Text("Dit is een song titel")
            Text("Dit is een knop")
            Text("Dit is de parent mode titel")
            Text("")
        }
        .padding()
    }
}

// MARK: - Advanced: Custom Text Rendering
struct CustomColorfulText: View {
    let text: String
    let font: Font
    
    var body: some View {
        // Voor geavanceerde effecten kun je ook Core Graphics gebruiken
        Canvas { context, size in
            // Custom text drawing met Core Graphics
            // Hier kun je complexe effecten maken zoals schaduwen, outlines, etc.
        }
    }
}

#Preview {
    ColorfulTextExamples()
}
