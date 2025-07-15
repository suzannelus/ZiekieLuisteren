//
//  FontExtension.swift
//  Ziekie
//
//  Created by Alex AI on 30/03/2025.
//

import SwiftUI

extension Font {
    // Quicksand font variants
    static func quicksand(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let fontName = quicksandFontName(for: weight)
        return Font.custom(fontName, size: size)
    }
    
    // Convenience methods for common text styles
    static var quicksandTitle: Font {
        quicksand(28, weight: .bold)
    }
    
    static var quicksandTitle2: Font {
        quicksand(22, weight: .semibold)
    }
    
    static var quicksandTitle3: Font {
        quicksand(20, weight: .semibold)
    }
    
    static var quicksandHeadline: Font {
        quicksand(17, weight: .semibold)
    }
    
    static var quicksandBody: Font {
        quicksand(17, weight: .regular)
    }
    
    static var quicksandCallout: Font {
        quicksand(16, weight: .regular)
    }
    
    static var quicksandSubheadline: Font {
        quicksand(15, weight: .regular)
    }
    
    static var quicksandFootnote: Font {
        quicksand(13, weight: .regular)
    }
    
    static var quicksandCaption: Font {
        quicksand(12, weight: .regular)
    }
    
    static var quicksandCaption2: Font {
        quicksand(11, weight: .regular)
    }
    
    // Helper method to get the correct font name based on weight
    private static func quicksandFontName(for weight: Font.Weight) -> String {
        switch weight {
        case .ultraLight, .thin:
            return "Quicksand-Light"
        case .light:
            return "Quicksand-Light"
        case .regular:
            return "Quicksand-Regular"
        case .medium:
            return "Quicksand-Medium"
        case .semibold:
            return "Quicksand-SemiBold"
        case .bold:
            return "Quicksand-Bold"
        case .heavy, .black:
            return "Quicksand-Bold"
        default:
            return "Quicksand-Regular"
        }
    }
}

// View modifier to easily apply Quicksand font
struct QuicksandFont: ViewModifier {
    let size: CGFloat
    let weight: Font.Weight
    
    func body(content: Content) -> some View {
        content
            .font(.quicksand(size, weight: weight))
    }
}

extension View {
    func quicksandFont(size: CGFloat, weight: Font.Weight = .regular) -> some View {
        modifier(QuicksandFont(size: size, weight: weight))
    }
}