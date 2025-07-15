import SwiftUI
import MusicKit

@MainActor
public class MusicAuthManager: ObservableObject {
    static let shared = MusicAuthManager()
    
    @Published var musicSubscription: MusicSubscription?
    @Published var isAuthorized = false
    @Published var isShowingSubscriptionOffer = false
    @Published var subscriptionOfferOptions: MusicSubscriptionOffer.Options = .default
    @Published var isWelcomeViewPresented: Bool = false
    @Published var authorizationError: String?
    @Published var hasInitialized = false
    @Published var initializationMessage = ""
    
    private let affiliateToken = "11l8Ds"
    private var authorizationTask: Task<Void, Never>?
    private var subscriptionTask: Task<Void, Never>?

    private init() {
            print("🎵 MusicAuthManager initialized (ultra-lightweight)")
            
            #if targetEnvironment(simulator)
            // Instant bypass for simulator
            isAuthorized = true
            hasInitialized = true
            print("🎵 Simulator mode - instant bypass")
            #else
            // CRITICAL: Only check current status, don't request authorization yet
            hasInitialized = true
            Task.detached(priority: .background) {
                let currentStatus = MusicAuthorization.currentStatus
                await MainActor.run {
                    self.isAuthorized = currentStatus == .authorized
                    self.isWelcomeViewPresented = !self.isAuthorized
                }
            }
            #endif
        }
    
    // NON-BLOCKING: Initialize when actually needed
    func initializeIfNeeded() async {
        guard !hasInitialized else {
            print("🎵 MusicAuth already initialized")
            return
        }
        
        #if targetEnvironment(simulator)
        // Skip initialization in simulator
        hasInitialized = true
        return
        #endif
        
        print("🎵 Starting MusicAuth initialization...")
        initializationMessage = "Checking music access..."
        
        // Get current status without triggering UI blocking calls
        let currentStatus = await Task.detached {
            return MusicAuthorization.currentStatus
        }.value
        
        // Update UI state
        isAuthorized = currentStatus == .authorized
        isWelcomeViewPresented = !isAuthorized
        hasInitialized = true
        initializationMessage = ""
        
        print("🎵 MusicAuth initialization complete - status: \(currentStatus)")
        
        // Only start subscription monitoring if already authorized
        if isAuthorized {
            Task {
                await startSubscriptionMonitoring()
            }
        }
    }
    
    // SAFE: Only call this when user actually needs music access
        func requestAuthorizationWhenNeeded() async {
            guard !isAuthorized else { return }
            
            print("🎵 User requested music access - starting authorization...")
            
            authorizationTask?.cancel()
            authorizationTask = Task.detached(priority: .userInitiated) {
                do {
                    // This runs entirely off main thread
                    let status = await MusicAuthorization.request()
                    
                    await MainActor.run {
                        self.isAuthorized = status == .authorized
                        self.isWelcomeViewPresented = !self.isAuthorized
                        self.authorizationError = nil
                        print("🎵 Authorization complete: \(status)")
                    }
                    
                    if status == .authorized {
                        await self.startSubscriptionMonitoring()
                    }
                } catch {
                    await MainActor.run {
                        self.authorizationError = "Authorization failed: \(error.localizedDescription)"
                        print("❌ Authorization error: \(error)")
                    }
                }
            }
            
            await authorizationTask?.value
        }
    
    /*
    // SAFE: Request authorization without blocking
    func checkAuthorizationStatus() async {
        // Cancel any existing task
        authorizationTask?.cancel()
        
        authorizationTask = Task { @MainActor in
            do {
                initializationMessage = "Requesting music access..."
                print("🎵 Requesting MusicKit authorization...")
                
                // This is the potentially blocking call, so we monitor it
                let status = try await withTaskTimeout(seconds: 10) {
                    await MusicAuthorization.request()
                }
                
                self.isAuthorized = status == .authorized
                self.isWelcomeViewPresented = !self.isAuthorized
                self.authorizationError = nil
                self.initializationMessage = ""
                
                print("🎵 MusicKit authorization result: \(status)")
                
                // Start subscription monitoring if authorized
                if status == .authorized {
                    Task {
                        await self.startSubscriptionMonitoring()
                    }
                }
                
            } catch {
                self.authorizationError = "Authorization timed out or failed: \(error.localizedDescription)"
                self.initializationMessage = ""
                print("❌ MusicKit authorization error: \(error)")
            }
        }
        
        await authorizationTask?.value
    }
    */
    // BACKGROUND: Monitor subscription
    private func startSubscriptionMonitoring() async {
        subscriptionTask?.cancel()
        subscriptionTask = Task.detached(priority: .background) {
            do {
                for await subscription in MusicSubscription.subscriptionUpdates {
                    await MainActor.run {
                        self.musicSubscription = subscription
                        print("🎵 Subscription updated: canPlay=\(subscription.canPlayCatalogContent)")
                    }
                }
            } catch {
                print("⚠️ Subscription monitoring failed: \(error)")
            }
        }
    }
    
    var canPlayMusic: Bool {
        guard isAuthorized else { return false }
        return musicSubscription?.canPlayCatalogContent ?? false
    }
    
    var shouldOfferSubscription: Bool {
        guard isAuthorized else { return false }
        return musicSubscription?.canBecomeSubscriber ?? false
    }
    
    func showSubscriptionOffer() {
        subscriptionOfferOptions.messageIdentifier = .playMusic
        subscriptionOfferOptions.affiliateToken = affiliateToken
        isShowingSubscriptionOffer = true
    }
    
    // CLEANUP: Cancel tasks on deinit
    deinit {
        authorizationTask?.cancel()
        subscriptionTask?.cancel()
    }
}

// Helper function to prevent blocking operations
func withTaskTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw TimeoutError()
        }
        
        guard let result = try await group.next() else {
            throw TimeoutError()
        }
        
        group.cancelAll()
        return result
    }
}

struct TimeoutError: Error {
    let localizedDescription = "Operation timed out"
}

// LIGHTWEIGHT: ViewModifier that doesn't block
struct MusicAuthHandling: ViewModifier {
    @StateObject private var authManager = MusicAuthManager.shared
    @State private var showingErrorAlert = false
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $authManager.isWelcomeViewPresented) {
                WelcomeView()
                    .interactiveDismissDisabled()
            }
            .musicSubscriptionOffer(
                isPresented: $authManager.isShowingSubscriptionOffer,
                options: authManager.subscriptionOfferOptions
            )
            .alert("Music Access", isPresented: $showingErrorAlert) {
                Button("Open Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Try Again") {
                    Task {
                        await authManager.requestAuthorizationWhenNeeded()
                    }
                }
                Button("Continue", role: .cancel) { }
            } message: {
                Text("Enable music access in Settings → Privacy & Security → Media & Apple Music")
            }
            .onChange(of: authManager.authorizationError) { _, newValue in
                showingErrorAlert = newValue != nil
            }
            // CRITICAL: Initialize async without blocking UI
            .task {
                await authManager.initializeIfNeeded()
            }
    }
}

extension View {
    func handleMusicAuth() -> some View {
        self.modifier(MusicAuthHandling())
    }
}
