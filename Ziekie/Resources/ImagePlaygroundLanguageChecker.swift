//
//  ImagePlaygroundLanguageChecker.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 13/08/2025.
//


import Foundation
import AVFoundation
import Speech

// MARK: - Image Playground Language Checker
@MainActor
class ImagePlaygroundLanguageChecker: ObservableObject {
    @Published var deviceLanguage: String = ""
    @Published var deviceRegion: String = ""
    @Published var siriLanguage: String = ""
    @Published var isImagePlaygroundSupported: Bool = false
    @Published var languagesMismatch: Bool = false
    @Published var supportedLanguages: [String] = []
    
    init() {
        detectLanguageSettings()
        checkImagePlaygroundSupport()
    }
    
    // MARK: - Detection Methods
    private func detectLanguageSettings() {
        // Get device language and region
        let locale = Locale.current
        deviceLanguage = locale.language.languageCode?.identifier ?? "en"
        deviceRegion = locale.region?.identifier ?? "US"
        
        // Get Siri language
        siriLanguage = getSiriLanguage()
        
        // Check if languages match
        languagesMismatch = !doLanguagesMatch()
        
        print("🌍 Device: \(deviceLanguage)-\(deviceRegion)")
        print("🗣️ Siri: \(siriLanguage)")
        print("✅ Match: \(!languagesMismatch)")
    }
    
    private func getSiriLanguage() -> String {
        // Method 1: Try to get from Speech Recognition
        if let speechRecognizer = SFSpeechRecognizer() {
            let siriLocale = speechRecognizer.locale
            return siriLocale.language.languageCode?.identifier ?? "unknown"
        }
        
        // Method 2: Check UserDefaults for Siri language preference
        if let appleLanguages = UserDefaults.standard.array(forKey: "AppleLanguages") as? [String],
           let firstLanguage = appleLanguages.first {
            let languageCode = String(firstLanguage.prefix(2))
            return languageCode
        }
        
        // Method 3: Check system voice settings
        let voices = AVSpeechSynthesisVoice.speechVoices()
        if let defaultVoice = voices.first(where: { $0.quality == .enhanced }) {
            let languageCode = String(defaultVoice.language.prefix(2))
            return languageCode
        }
        
        // Fallback to device language
        return deviceLanguage
    }
    
    private func doLanguagesMatch() -> Bool {
        // For Image Playground, device language and Siri language must match
        return deviceLanguage.lowercased() == siriLanguage.lowercased()
    }
    
    // MARK: - Image Playground Support Check
    private func checkImagePlaygroundSupport() {
        // Get supported languages for Image Playground
        supportedLanguages = getImagePlaygroundSupportedLanguages()
        
        // Check if current language is supported and languages match
        let currentLanguageSupported = supportedLanguages.contains(deviceLanguage.lowercased())
        let siriLanguageSupported = supportedLanguages.contains(siriLanguage.lowercased())
        
        isImagePlaygroundSupported = currentLanguageSupported &&
                                   siriLanguageSupported &&
                                   !languagesMismatch
        
        print("📱 Image Playground Supported: \(isImagePlaygroundSupported)")
    }
    
    private func getImagePlaygroundSupportedLanguages() -> [String] {
        // Based on Apple's official documentation as of iOS 18.4
        return [
            "en", // English (various regions)
            "zh", // Chinese (Simplified)
            "fr", // French
            "de", // German
            "it", // Italian
            "ja", // Japanese
            "ko", // Korean
            "pt", // Portuguese (Brazil)
            "es"  // Spanish
        ]
    }
    
    // MARK: - Helper Methods for UI
    func getLanguageDisplayName(_ languageCode: String) -> String {
        let locale = Locale.current
        return locale.localizedString(forLanguageCode: languageCode) ?? languageCode.uppercased()
    }
    
    func getRegionDisplayName(_ regionCode: String) -> String {
        let locale = Locale.current
        return locale.localizedString(forRegionCode: regionCode) ?? regionCode
    }
    
    func getSettingsInstructions() -> String {
        if languagesMismatch {
            return "Go to Settings > Apple Intelligence & Siri > Language and set it to match your device language (\(getLanguageDisplayName(deviceLanguage)))."
        } else if !supportedLanguages.contains(deviceLanguage.lowercased()) {
            return "Image Playground is not available in \(getLanguageDisplayName(deviceLanguage)). Switch to English, Spanish, French, German, Italian, Japanese, Korean, Portuguese, or Chinese in Settings."
        } else {
            return "Image Playground should be working with your current settings."
        }
    }
    
    // MARK: - Refresh Method
    func refreshLanguageSettings() {
        detectLanguageSettings()
        checkImagePlaygroundSupport()
    }
}

// MARK: - Image Playground Onboarding View Model
@MainActor
class ImagePlaygroundOnboardingViewModel: ObservableObject {
    @Published var languageChecker = ImagePlaygroundLanguageChecker()
    @Published var showOnboarding: Bool = false
    
    init() {
        checkIfOnboardingNeeded()
    }
    
    private func checkIfOnboardingNeeded() {
        // Show onboarding if languages don't match or Image Playground isn't supported
        showOnboarding = languageChecker.languagesMismatch ||
                        !languageChecker.isImagePlaygroundSupported
    }
    
    func dismissOnboarding() {
        showOnboarding = false
        // Save that user has seen the onboarding
        UserDefaults.standard.set(true, forKey: "HasSeenImagePlaygroundOnboarding")
    }
}

// MARK: - Extension for easier access
extension ImagePlaygroundLanguageChecker {
    var statusMessage: String {
        if languagesMismatch {
            return "Device language and Siri language must match for Image Playground to work."
        } else if !isImagePlaygroundSupported {
            return "Image Playground is not supported with your current language settings."
        } else {
            return "Image Playground is ready to use!"
        }
    }
    
    var statusIcon: String {
        if languagesMismatch || !isImagePlaygroundSupported {
            return "exclamationmark.triangle.fill"
        } else {
            return "checkmark.circle.fill"
        }
    }
    
    var statusColor: String {
        if languagesMismatch || !isImagePlaygroundSupported {
            return "orange"
        } else {
            return "green"
        }
    }
}
