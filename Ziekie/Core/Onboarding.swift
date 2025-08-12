//
//  WelcomeView.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 13/02/2023.

import SwiftUI
import MusicKit

struct WelcomeView: View {
    @StateObject private var authManager = MusicAuthManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep: OnboardingStep = .intro
    @State private var showingSubscriptionOffer = false
    
    // Animation states for smooth transitions
    @State private var floatPhase: CGFloat = 0
    @State private var contentOpacity: Double = 1
    @State private var isTransitioning = false
    
    var body: some View {
        ZStack {
            // Beautiful gradient background with orbs
            backgroundView
            
            // Main content that changes based on current step
            VStack(spacing: 0) {
                // App title (always visible)
            //    RainbowText(text: "Tune Gallery", font: .merriweatherResponsive(.largeTitle))
           //         .padding(.top, 60)
                
                Spacer()
                
                // Dynamic content based on onboarding step
                mainContentView
                    .opacity(contentOpacity)
                    .animation(.easeInOut(duration: 0.4), value: contentOpacity)
                
                Spacer()
                
                // Bottom action area
                bottomActionView
                    .padding(.bottom, 60)
            }
        }
        .onAppear {
            startFloatingAnimation()
            // Start subscription check after a brief moment
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay for better UX
                await authManager.checkSubscriptionStatus()
            }
        }
        .sheet(isPresented: $authManager.isShowingSubscriptionOffer) {
            // This uses the built-in Apple Music subscription offer
            // The sheet will automatically be presented by the musicSubscriptionOffer modifier
            EmptyView()
        }
    }
    
    // MARK: - Background View
    private var backgroundView: some View {
        ZStack {
            // Gradient orbs that create depth and visual interest
            GradientOrb(gradient: .tealMint, size: 220, blur: 28)
                .offset(x: -120, y: -190)
                .opacity(0.85)
            
            GradientOrb(gradient: .bluePurple, size: 260, blur: 30)
                .offset(x: 120, y: -40)
                .opacity(0.9)
            
            GradientOrb(gradient: .orangePink, size: 230, blur: 30)
                .offset(x: 40, y: 200)
                .opacity(0.9)
        }
    }
    
    // MARK: - Main Content View
    private var mainContentView: some View {
        ZStack {
            switch currentStep {
            case .intro:
                introStepView
            case .subscriptionCheck:
                subscriptionCheckStepView
            case .customArtPreview:
                customArtPreviewStepView
            case .readyToUse:
                readyToUseStepView
            }
        }
    }
    
    // MARK: - Intro Step (Maneschijn Image)
    private var introStepView: some View {
        ZStack {
            // The polaroid card with maneschijn image
            PolaroidCard()
                .padding()
            
            // Floating glass music notes for visual appeal
            floatingMusicNotes
        }
        .onTapGesture {
            proceedToSubscriptionCheck()
        }
    }
    
    // MARK: - Subscription Check Step
    private var subscriptionCheckStepView: some View {
        VStack(spacing: 24) {
            // Loading indicator or status icon
            subscriptionStatusIcon
            
            // Subscription status text
            Text(authManager.subscriptionStatusText)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            // Additional context based on subscription status
            subscriptionContextText
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
    
    // MARK: - Custom Art Preview Step
    private var customArtPreviewStepView: some View {
        ZStack {
            // Show the transition from default to custom art
            CustomArtTransitionView()
                .padding()
            
            // Floating music notes with custom art theme
            floatingMusicNotes
        }
    }
    
    // MARK: - Ready to Use Step
    private var readyToUseStepView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("You're all set!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Start creating beautiful playlists with custom artwork")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
    
    // MARK: - Subscription Status Icon
    private var subscriptionStatusIcon: some View {
        Group {
            if authManager.isCheckingSubscription {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
            } else if authManager.canPlayMusic {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
            } else if authManager.shouldOfferSubscription {
                Image(systemName: "music.note.list")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
            }
        }
    }
    
    // MARK: - Subscription Context Text
    private var subscriptionContextText: some View {
        Group {
            if authManager.isCheckingSubscription {
                Text("Please wait while we verify your Apple Music subscription...")
            } else if authManager.canPlayMusic {
                Text("Perfect! You can enjoy full Apple Music playback with your custom artwork.")
            } else if authManager.shouldOfferSubscription {
                Text("Subscribe to Apple Music to unlock unlimited song playback with your custom artwork.")
            } else {
                Text("Apple Music may not be available on this device. Some features may be limited.")
            }
        }
    }
    
    // MARK: - Floating Music Notes
    private var floatingMusicNotes: some View {
        Group {
            GlassMusicNote(symbol: "music.note", size: 64, rotation: .degrees(0))
                .offset(x: -120, y: -80)
                .opacity(0.95)
                .scaleEffect(1.0 + 0.02 * sin(floatPhase))
            
            GlassMusicNote(symbol: "music.note", size: 70, rotation: .degrees(14))
                .offset(x: 140, y: -30)
                .opacity(0.95)
                .scaleEffect(1.0 + 0.02 * cos(floatPhase * 1.3))
            
            GlassMusicNote(symbol: "music.note", size: 54, rotation: .degrees(-8))
                .offset(x: -40, y: 160)
                .opacity(0.9)
                .scaleEffect(1.0 + 0.02 * sin(floatPhase * 0.9))
        }
    }
    
    // MARK: - Bottom Action View
    private var bottomActionView: some View {
        VStack(spacing: 16) {
            switch currentStep {
            case .intro:
                VStack(spacing: 8) {
                    Text("Add custom images to playlists and songs")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.accentColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Text("Tap anywhere to continue")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
            case .subscriptionCheck:
                subscriptionActionButtons
                
            case .customArtPreview:
                Button("Continue") {
                    proceedToFinalStep()
                }
                .buttonStyle(PrimaryButtonStyle())
                
            case .readyToUse:
                Button("Start Using Tune Gallery") {
                    completeOnboarding()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
    }
    
    // MARK: - Subscription Action Buttons
    private var subscriptionActionButtons: some View {
        VStack(spacing: 12) {
            if authManager.isCheckingSubscription {
                // Show nothing while checking
                EmptyView()
            } else if authManager.canPlayMusic {
                // User has subscription - proceed to custom art preview
                Button("Continue") {
                    proceedToCustomArtPreview()
                }
                .buttonStyle(PrimaryButtonStyle())
            } else if authManager.shouldOfferSubscription {
                // User can subscribe - show subscription offer
                VStack(spacing: 8) {
                    Button("Subscribe to Apple Music") {
                        authManager.showSubscriptionOffer()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    Button("Continue without subscription") {
                        proceedToCustomArtPreview()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
                    Text("Note: Song playback requires an Apple Music subscription")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
            } else {
                // Restricted access - continue with limited functionality
                VStack(spacing: 8) {
                    Button("Continue") {
                        proceedToCustomArtPreview()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    Text("Some features may be limited on this device")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func startFloatingAnimation() {
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            floatPhase = .pi * 2
        }
    }
    
    private func proceedToSubscriptionCheck() {
        withAnimation(.easeInOut(duration: 0.4)) {
            currentStep = .subscriptionCheck
        }
    }
    
    private func proceedToCustomArtPreview() {
        withAnimation(.easeInOut(duration: 0.4)) {
            currentStep = .customArtPreview
        }
    }
    
    private func proceedToFinalStep() {
        withAnimation(.easeInOut(duration: 0.4)) {
            currentStep = .readyToUse
        }
    }
    
    private func completeOnboarding() {
        authManager.isWelcomeViewPresented = false
        dismiss()
    }
}

// MARK: - Onboarding Steps
enum OnboardingStep {
    case intro                 // Show manenschijn image with tap to continue
    case subscriptionCheck     // Check and display subscription status
    case customArtPreview      // Show custom art transition
    case readyToUse           // Final confirmation screen
}

// MARK: - Custom Art Transition View
struct CustomArtTransitionView: View {
    @State private var showCustomArt = false
    
    var body: some View {
        ZStack {
            // Default polaroid
            PolaroidCard()
                .opacity(showCustomArt ? 0 : 1)
                .scaleEffect(showCustomArt ? 0.8 : 1)
            
            // Custom art version (you can customize this)
            CustomPolaroidCard()
                .opacity(showCustomArt ? 1 : 0)
                .scaleEffect(showCustomArt ? 1 : 0.8)
        }
        .onAppear {
            withAnimation(.spring(response: 1.5, dampingFraction: 0.8).delay(0.5)) {
                showCustomArt = true
            }
        }
    }
}

// MARK: - Custom Polaroid Card (with different artwork)
struct CustomPolaroidCard: View {
    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(
                            LinearGradient(colors: [.white.opacity(0.8), .white.opacity(0.2)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1.2
                        )
                )
                .shadow(color: .black.opacity(0.18), radius: 24, x: 0, y: 16)
                .aspectRatio(100/115, contentMode: .fit)
            
            // Custom artwork placeholder (you can replace this with any image)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(LinearGradient(colors: [.purple, .pink, .orange],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    VStack {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("Custom\nArtwork")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                )
                .padding(18)
        }
        .rotationEffect(.degrees(-10))
        .padding()
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(LinearGradient(colors: [.accentColor, .accentColor.opacity(0.8)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .foregroundColor(.accentColor)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.accentColor.opacity(0.5), lineWidth: 1)
                    .fill(.ultraThinMaterial)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preserve existing components from original WelcomeView
// (GradientOrb, GlassMusicNote, ManeschijnImage, PolaroidCard remain the same)

// MARK: - Signature Colors (keeping your existing gradients)
extension LinearGradient {
    static let tealMint = LinearGradient(
        colors: [Color(#colorLiteral(red: 0.0, green: 0.754, blue: 0.694, alpha: 1)),
                 Color(#colorLiteral(red: 0.675, green: 0.949, blue: 0.855, alpha: 1))],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let bluePurple = LinearGradient(
        colors: [Color(#colorLiteral(red: 0.223, green: 0.54, blue: 0.996, alpha: 1)),
                 Color(#colorLiteral(red: 0.53, green: 0.33, blue: 0.96, alpha: 1))],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let orangePink = LinearGradient(
        colors: [Color(#colorLiteral(red: 1.0, green: 0.58, blue: 0.33, alpha: 1)),
                 Color(#colorLiteral(red: 1.0, green: 0.42, blue: 0.63, alpha: 1))],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

// MARK: - Gradient Orb (keeping your existing component)
struct GradientOrb: View {
    var gradient: LinearGradient
    var size: CGFloat
    var blur: CGFloat = 22
    var body: some View {
        Circle()
            .fill(gradient)
            .frame(width: size, height: size)
            .blur(radius: blur)
            .overlay(
                Circle().stroke(.white.opacity(0.05), lineWidth: 1)
                    .blur(radius: 2)
            )
            .opacity(0.85)
    }
}

// MARK: - Glass Music Note (keeping your existing component)
struct GlassMusicNote: View {
    var symbol: String = "music.note"
    var size: CGFloat = 264
    var rotation: Angle = .degrees(0)
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size/3)
                .fill(.clear)
                .frame(width: size, height: size)
                .opacity(0)
            Image(systemName: symbol)
                .font(.system(size: size, weight: .regular))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.white.opacity(0.65))
                .rotationEffect(rotation)
        }
    }
}

// MARK: - ManenschijnImage (keeping your existing component)
struct ManeschijnImage: View {
    var body: some View {
        Image("In de Manenschijn")
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.white.opacity(0.25), lineWidth: 1)
            )
    }
}

// MARK: - Polaroid Card (keeping your existing component)
struct PolaroidCard: View {
    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(
                            LinearGradient(colors: [.white.opacity(0.8), .white.opacity(0.2)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1.2
                        )
                )
                .shadow(color: .black.opacity(0.18), radius: 24, x: 0, y: 16)
                .aspectRatio(100/115, contentMode: .fit)
            ManeschijnImage()
                .padding(18)
        }
        .rotationEffect(.degrees(-10))
        .padding()
    }
}
