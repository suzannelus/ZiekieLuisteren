//
//  ZiekieApp.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 13/02/2023.
//

// Existing code ...
// Import MusicAuthManager
@_exported import MusicKit

// Your other imports remain the same
import SwiftUI
import MusicKit

// CRITICAL: Minimal app initialization
@main
struct ZiekieApp: App {
    @StateObject private var authManager = MusicAuthManager.shared
    @StateObject private var parentModeManager = ParentModeManager.shared
    
    init() {
        print("📱 App launching...")
        // Set playlist preference to region priority before anything else
        setupPlaylistPreferences()
        // MOVED: Font setup to background to prevent blocking
        setupUIAsync()
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                        .environmentObject(MusicPlayerManager.shared)
                        .environmentObject(parentModeManager)
                        // INLINE: Handle music auth directly without external dependencies
                        .sheet(isPresented: $authManager.isWelcomeViewPresented) {
                            WelcomeView()
                                .interactiveDismissDisabled()
                        }
                        .musicSubscriptionOffer(
                            isPresented: $authManager.isShowingSubscriptionOffer,
                            options: authManager.subscriptionOfferOptions
                        )
                       
        }
    }
    
    // CRITICAL: Set up playlist preferences early
    private func setupPlaylistPreferences() {
        // Ensure region priority is set as default (your specified requirement)
        let preferenceManager = PlaylistPreferenceManager.shared
        
        // Only set if no preference has been saved before
        let hasExistingPreference = UserDefaults.standard.object(forKey: "PlaylistLoadingPreference") != nil
        if !hasExistingPreference {
            preferenceManager.loadingPreference = .region
            print("📱 Set default playlist preference to region priority")
        }
        
        print("📱 Current playlist preference: \(preferenceManager.loadingPreference.displayName)")
    }
    
    // ASYNC: Setup UI without blocking main thread
    private func setupUIAsync() {
        Task.detached(priority: .background) {
            await setupFonts()
            print("📱 UI setup complete")
        }
    }
    
    // BACKGROUND: Font configuration
    private func setupFonts() async {
        await MainActor.run {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            
            if let merriweatherFont = UIFont(name: "Merriweather-Italic", size: 22) {
                appearance.titleTextAttributes = [.font: merriweatherFont]
                appearance.largeTitleTextAttributes = [.font: UIFont(name: "Merriweather-Italic", size: 34) ?? merriweatherFont]
            }
            
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// RESTORED: Root view with proper playlist loading
struct AppRootView: View {
    @StateObject private var authManager = MusicAuthManager.shared
    @StateObject private var playlistContainer = PlaylistsContainer.shared
    @State private var initializationStage: InitStage = .starting
    @State private var loadingMessage = "Starting Tune Gallery..."
    
    // FIXED: Added Equatable conformance to resolve compilation error
    enum InitStage: Equatable {
        case starting
        case loadingAuth
        case loadingPlaylists
        case ready
        case error(String)
    }
    
    var body: some View {
        Group {
            switch initializationStage {
            case .starting, .loadingAuth, .loadingPlaylists:
                LaunchLoadingView(message: loadingMessage)
            case .ready:
                HomeView()
            case .error(let message):
                ErrorView(message: message) {
                    initializationStage = .starting
                    Task {
                        await initializeApp()
                    }
                }
            }
        }
        .task {
            await initializeApp()
        }
    }
    
    // RESTORED: Proper initialization sequence with playlist loading
    @MainActor
    private func initializeApp() async {
        print("📱 Starting app initialization sequence...")
        
        do {
            // Stage 1: Music Auth Check
            initializationStage = .starting
            loadingMessage = "Starting Tune Gallery..."
            
            // Brief initial pause for smooth UI
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            
            // Stage 2: Auth Initialization
            initializationStage = .loadingAuth
            loadingMessage = "Checking music access..."
            
            // Wait for auth manager to initialize if needed
            if !authManager.hasInitialized {
                var waitCount = 0
                while !authManager.hasInitialized && waitCount < 50 { // Max 5 seconds
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    waitCount += 1
                }
                
                if !authManager.hasInitialized {
                    throw AppInitializationError.authTimeout
                }
            }
            
            print("📱 Auth manager initialized: \(authManager.hasInitialized)")
            
            // Stage 3: Playlist Loading (RESTORED!)
            initializationStage = .loadingPlaylists
            loadingMessage = "Loading your playlists..."
            
            // CRITICAL: Proper playlist initialization
            await initializePlaylists()
            
            // Brief pause for smooth transition
            try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            
            // Stage 4: Ready
            withAnimation(.easeInOut(duration: 0.5)) {
                initializationStage = .ready
            }
            
            print("✅ App initialization complete")
            
        } catch {
            print("❌ App initialization failed: \(error)")
            let errorMessage: String
            if let appError = error as? AppInitializationError {
                errorMessage = appError.localizedDescription
            } else {
                errorMessage = "Failed to initialize app: \(error.localizedDescription)"
            }
            initializationStage = .error(errorMessage)
        }
    }
    
    // Proper playlist initialization with region priority and en-US fallback
    @MainActor
    private func initializePlaylists() async {
        print("📱 Starting playlist initialization...")
        
        // Get current locale information
        let currentLocale = Locale.current
        let regionCode = currentLocale.region?.identifier ?? "US"
        let languageCode = currentLocale.language.languageCode?.identifier ?? "en"
        
        print("📁 User locale: \(languageCode)-\(regionCode)")
        
        // Log the loading order that will be used (region priority)
        let preferenceManager = PlaylistPreferenceManager.shared
        let loadingOrder = preferenceManager.getPlaylistLoadingOrder(language: languageCode, region: regionCode)
        print("📁 Playlist: \(loadingOrder)")
        
        // Initialize the playlist container
        if !playlistContainer.hasInitialized {
            // Call the existing initialization method
            await playlistContainer.initializeIfNeeded()
            
            // Wait for playlists to be loaded
            var playlistWaitCount = 0
            while !playlistContainer.hasInitialized && playlistWaitCount < 30 { // Max 3 seconds
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                playlistWaitCount += 1
            }
            
            if !playlistContainer.hasInitialized {
                print("⚠️ Playlist container did not initialize in time, but continuing...")
            }
        }
        
        // Log results
        let playlistCount = playlistContainer.playlists.count
        print("📁 Loaded \(playlistCount) playlists")
        
        if playlistCount > 0 {
            print("📁 Playlist names: \(playlistContainer.playlists.map { $0.name }.joined(separator: ", "))")
        } else {
            print("⚠️ No playlists loaded - check if JSON files exist for locale \(languageCode)-\(regionCode)")
        }
    }
}

// HELPER: Custom error types for better error handling
enum AppInitializationError: LocalizedError {
    case authTimeout
    case playlistLoadingFailed
    
    var errorDescription: String? {
        switch self {
        case .authTimeout:
            return "Music authorization took too long. Please check your internet connection and try again."
        case .playlistLoadingFailed:
            return "Failed to load your playlists. Please try again."
        }
    }
}

// ENHANCED: Loading view with playlist-aware messaging
struct LaunchLoadingView: View {
    let message: String
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 30) {
            // App title with fallback styling if RainbowText isn't available
            VStack(spacing: 10) {
                if #available(iOS 16.0, *) {
                    Text("Tune Gallery")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple, .pink, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .scaleEffect(isAnimating ? 1.02 : 1.0)
                        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: isAnimating)
                } else {
                    Text("Tune Gallery")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .scaleEffect(isAnimating ? 1.02 : 1.0)
                        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: isAnimating)
                }
            }
            
            VStack(spacing: 15) {
                Text(message)
                    
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.mint)
                
                
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            isAnimating = true
        }
    }
    
    
}

// UNCHANGED: Keep your existing error view
struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Oops!")
                .font(.title)
                .fontWeight(.bold)
            
            Text(message)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
            .tint(.mint)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
