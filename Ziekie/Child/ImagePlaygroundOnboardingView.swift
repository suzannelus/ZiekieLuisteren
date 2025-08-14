//
//  ImagePlaygroundOnboardingView.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 13/08/2025.
//


import SwiftUI

// MARK: - Image Playground Onboarding View
struct ImagePlaygroundOnboardingView: View {
    @StateObject private var viewModel = ImagePlaygroundOnboardingViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "photo.on.rectangle.angled")
                    .symbolRenderingMode(.palette)
                    .font(.system(size: 60))
                    .foregroundStyle(.indigo, .teal)
                
                Text("Image Playground Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Image Playground only works when your device language and Siri language are the same.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            // Language Status Card
            VStack(spacing: 16) {
                LanguageStatusRow(
                    title: "Device Language",
                    value: viewModel.languageChecker.getLanguageDisplayName(viewModel.languageChecker.deviceLanguage),
                    icon: "iphone",
                    isCorrect: viewModel.languageChecker.supportedLanguages.contains(viewModel.languageChecker.deviceLanguage.lowercased())
                )
                
                LanguageStatusRow(
                    title: "Siri Language",
                    value: viewModel.languageChecker.getLanguageDisplayName(viewModel.languageChecker.siriLanguage),
                    icon: "mic",
                    isCorrect: viewModel.languageChecker.supportedLanguages.contains(viewModel.languageChecker.siriLanguage.lowercased())
                )
                
                LanguageStatusRow(
                    title: "Region",
                    value: viewModel.languageChecker.getRegionDisplayName(viewModel.languageChecker.deviceRegion),
                    icon: "location",
                    isCorrect: true // Region doesn't affect Image Playground as much as language
                )
            }
            .padding()
            .background(Color(.indigo.opacity(0.1)))
            .cornerRadius(12)
            
            // Status Message
            HStack(spacing: 12) {
                Image(systemName: viewModel.languageChecker.statusIcon)
                    .foregroundColor(colorForStatus(viewModel.languageChecker.statusColor))
                
                Text(viewModel.languageChecker.statusMessage)
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding()
            .background(backgroundColorForStatus(viewModel.languageChecker.statusColor))
            .cornerRadius(8)
            
            // Instructions
            if viewModel.languageChecker.languagesMismatch || !viewModel.languageChecker.isImagePlaygroundSupported {
                VStack(alignment: .leading, spacing: 8) {
                    Text("How to fix:")
                        .font(.headline)
                    
                    Text(viewModel.languageChecker.getSettingsInstructions())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.indigo.opacity(0.1)))
                .cornerRadius(8)
            }
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 12) {
                if viewModel.languageChecker.languagesMismatch || !viewModel.languageChecker.isImagePlaygroundSupported {
                    Button(action: {
                        openSettings()
                    }) {
                        HStack {
                            Image(systemName: "gear")
                            Text("Open Settings")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                }
                
                Button(action: {
                    viewModel.dismissOnboarding()
                    dismiss()
                }) {
                    Text(viewModel.languageChecker.isImagePlaygroundSupported ? "Continue" : "Skip for Now")
                        .font(.headline)
                       
                        .foregroundColor(viewModel.languageChecker.isImagePlaygroundSupported ? .white : .orange)
                        .padding()

                        .background(viewModel.languageChecker.isImagePlaygroundSupported ? Color.indigo : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue, lineWidth: viewModel.languageChecker.isImagePlaygroundSupported ? 0 : 2)
                        )
                        .cornerRadius(10)
                        
                }
            }
        }
        .padding()
        .onAppear {
            viewModel.languageChecker.refreshLanguageSettings()
        }
    }
    
    // MARK: - SwiftUI Native Settings Opening
    private func openSettings() {
        if let settingsURL = URL(string: "App-Prefs:General&path=LanguageAndRegion") {
            openURL(settingsURL)
        } else if let fallbackURL = URL(string: "App-Prefs:") {
            openURL(fallbackURL)
        }
    }
    
    private func colorForStatus(_ status: String) -> Color {
        switch status {
        case "green": return .teal
        case "orange": return .orange
        case "red": return .pink
        default: return .gray
        }
    }
    
    private func backgroundColorForStatus(_ status: String) -> Color {
        switch status {
        case "green": return Color.teal.opacity(0.1)
        case "orange": return Color.orange.opacity(0.1)
        case "red": return Color.pink.opacity(0.1)
        default: return Color.gray.opacity(0.1)
        }
    }
}

// MARK: - Language Status Row Component
struct LanguageStatusRow: View {
    let title: String
    let value: String
    let icon: String
    let isCorrect: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.teal)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            Image(systemName: isCorrect ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(isCorrect ? .teal : .orange)
        }
    }
}

// MARK: - Compact Warning View for Create Image Screens
struct ImagePlaygroundLanguageWarning: View {
    @StateObject private var languageChecker = ImagePlaygroundLanguageChecker()
    @State private var showFullOnboarding = false
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        if languageChecker.languagesMismatch || !languageChecker.isImagePlaygroundSupported {
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text("Image generation may not work properly")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                }
                
                Text(languageChecker.statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 12) {
                    Button("Fix Settings") {
                        openSettings()
                    }
                    .font(.caption)
                    .foregroundColor(.teal)
                    
                    Spacer()
                    
                    Button("Learn More") {
                        showFullOnboarding = true
                    }
                    .font(.caption)
                    .foregroundColor(.teal)
                }
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
            .sheet(isPresented: $showFullOnboarding) {
                ImagePlaygroundOnboardingView()
            }
        }
    }
    
    // MARK: - SwiftUI Native Settings Opening
    private func openSettings() {
        if let settingsURL = URL(string: "App-Prefs:General&path=LanguageAndRegion") {
            openURL(settingsURL)
        } else if let fallbackURL = URL(string: "App-Prefs:") {
            openURL(fallbackURL)
        }
    }
}

// MARK: - Preview
#Preview {
    ImagePlaygroundOnboardingView()
}

#Preview("Warning View") {
    ImagePlaygroundLanguageWarning()
        .padding()
}
