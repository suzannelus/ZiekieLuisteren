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
        // MOVED: Font setup to background to prevent blocking
        setupUIAsync()
    }

    var body: some Scene {
        WindowGroup {
#if DEBUG
        ZiekieApp.enableDevelopmentDebugging()
        #else
            AppRootView()
                .environmentObject(MusicPlayerManager.shared)
                .environmentObject(parentModeManager)
                .handleMusicAuth()
                .font(.quicksandResponsive(.body, weight: .regular))
                .background(
                    CanvasDottedBackground()
                        .ignoresSafeArea(.all)
                )
#endif
        }
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

// STAGED: Root view that initializes components in sequence
struct AppRootView: View {
    @State private var initializationStage: InitStage = .starting
    @State private var loadingMessage = "Starting Tune Gallery..."
    
    enum InitStage {
        case starting
        case loadingData
        case ready
        case error(String)
    }
    
    var body: some View {
        Group {
            switch initializationStage {
            case .starting, .loadingData:
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
    
    // SEQUENTIAL: Initialize components one by one to prevent overwhelm
    @MainActor
    private func initializeApp() async {
        print("📱 Starting app initialization sequence...")
        
        do {
            // Stage 1: Music Auth (quick check)
            initializationStage = .starting
            loadingMessage = "Checking music access..."
            
            await MusicAuthManager.shared.initializeIfNeeded()
            
            // Brief pause to let UI update
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            // Stage 2: Data Loading
            initializationStage = .loadingData
            loadingMessage = "Loading your playlists..."
            
            await PlaylistsContainer.shared.initializeIfNeeded()
            
            // Brief pause for smooth transition
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            
            // Stage 3: Ready
            withAnimation(.easeInOut(duration: 0.5)) {
                initializationStage = .ready
            }
            
            print("✅ App initialization complete")
            
        } catch {
            print("❌ App initialization failed: \(error)")
            initializationStage = .error("Failed to initialize app: \(error.localizedDescription)")
        }
    }
}

// SMOOTH: Loading view during initialization
struct LaunchLoadingView: View {
    let message: String
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Animated app icon/logo
            VStack(spacing: 10) {
                Text("🎵")
                    .font(.system(size: 80))
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(), value: isAnimating)
                
                Text("Tune Gallery")
                    .appTitle()
                    .foregroundColor(.accentColor)
            }
            
            VStack(spacing: 15) {
                Text(message)
                    .captionBold()
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

// ERROR: Retry view if initialization fails
struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Oops!")
                .screenTitle()
            
            Text(message)
                .captionBold()
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
