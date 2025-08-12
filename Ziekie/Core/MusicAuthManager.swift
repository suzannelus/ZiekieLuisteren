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
    @Published var isCheckingSubscription = false
    @Published var subscriptionStatusText = "Checking Apple Music subscription..."
    
    private let affiliateToken = "11l8Ds"
    private var authorizationTask: Task<Void, Never>?
    private var subscriptionTask: Task<Void, Never>?
    private var initialSubscriptionFetched = false

    private init() {
        print("🎵 MusicAuthManager initialized")
        hasInitialized = true
        
        #if targetEnvironment(simulator)
        // Simulator mock states for testing
        isAuthorized = true
        Task {
            await createMockSubscriptionForSimulator()
        }
        print("🎵 Simulator mode - using mock subscription")
        #else
        // Real device - check current authorization status
        Task.detached(priority: .background) {
            let currentStatus = MusicAuthorization.currentStatus
            await MainActor.run {
                self.isAuthorized = currentStatus == .authorized
                self.isWelcomeViewPresented = !self.isAuthorized
                
                // If already authorized, fetch subscription immediately
                if self.isAuthorized {
                    Task {
                        await self.fetchInitialSubscription()
                        await self.startSubscriptionMonitoring()
                    }
                }
            }
        }
        #endif
    }
    
    // ENHANCED: Subscription status checking for onboarding
    func checkSubscriptionStatus() async {
        print("🎵 Starting subscription status check...")
        
        await MainActor.run {
            isCheckingSubscription = true
            subscriptionStatusText = "Checking Apple Music subscription..."
        }
        
        // Small delay for better UX (prevents flash)
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        guard isAuthorized else {
            await requestAuthorizationForOnboarding()
            return
        }
        
        // If already authorized, check subscription
        if musicSubscription == nil {
            await fetchInitialSubscription()
        }
        
        await updateSubscriptionStatusText()
    }
    
    // NEW: Request authorization specifically for onboarding flow
    private func requestAuthorizationForOnboarding() async {
        print("🎵 Requesting authorization for onboarding...")
        
        await MainActor.run {
            subscriptionStatusText = "Requesting Apple Music access..."
        }
        
        authorizationTask?.cancel()
        authorizationTask = Task.detached(priority: .userInitiated) {
            do {
                let status = await MusicAuthorization.request()
                
                await MainActor.run {
                    self.isAuthorized = status == .authorized
                    self.authorizationError = nil
                    print("🎵 Authorization complete: \(status)")
                }
                
                if status == .authorized {
                    await self.fetchInitialSubscription()
                    await self.startSubscriptionMonitoring()
                }
                
                await self.updateSubscriptionStatusText()
                
            } catch {
                await MainActor.run {
                    self.authorizationError = "Authorization failed: \(error.localizedDescription)"
                    self.subscriptionStatusText = "Unable to check subscription status"
                    print("❌ Authorization error: \(error)")
                }
            }
        }
        
        await authorizationTask?.value
    }
    
    // NEW: Generate user-friendly subscription status text
    private func updateSubscriptionStatusText() async {
        await MainActor.run {
            isCheckingSubscription = false
            
            guard isAuthorized else {
                subscriptionStatusText = "Apple Music access required"
                return
            }
            
            guard let subscription = musicSubscription else {
                subscriptionStatusText = "Unable to verify subscription"
                return
            }
            
            if subscription.canPlayCatalogContent {
                subscriptionStatusText = "✅ Apple Music subscription active"
            } else if subscription.canBecomeSubscriber {
                subscriptionStatusText = "Apple Music subscription required"
            } else {
                // User is restricted (device limitations, region, etc.)
                subscriptionStatusText = "Apple Music not available on this device"
            }
        }
    }
    
    // ENHANCED: Fetch subscription with better error handling
    private func fetchInitialSubscription() async {
        guard !initialSubscriptionFetched else { return }
        initialSubscriptionFetched = true
        
        print("🎵 Fetching initial subscription...")
        
        do {
            // Use timeout to handle slow network conditions
            let subscription = try await withTaskTimeout(seconds: 10) {
                try await MusicSubscription.current
            }
            
            await MainActor.run {
                self.musicSubscription = subscription
                print("🎵 Initial subscription loaded successfully")
                print("   - canPlayCatalogContent: \(subscription.canPlayCatalogContent)")
                print("   - canBecomeSubscriber: \(subscription.canBecomeSubscriber)")
            }
        } catch {
            print("❌ Failed to fetch initial subscription: \(error)")
            await handleSubscriptionError(error)
        }
    }
    
    // ENHANCED: Better subscription monitoring
    private func startSubscriptionMonitoring() async {
        subscriptionTask?.cancel()
        subscriptionTask = Task.detached(priority: .background) {
            do {
                print("🎵 Starting subscription monitoring...")
                for await subscription in MusicSubscription.subscriptionUpdates {
                    await MainActor.run {
                        self.musicSubscription = subscription
                        print("🎵 Subscription updated: canPlay=\(subscription.canPlayCatalogContent)")
                    }
                }
            } catch {
                print("⚠️ Subscription monitoring failed: \(error)")
                await self.retrySubscriptionFetch()
            }
        }
    }
    
    // FALLBACK: Retry subscription fetch if monitoring fails
    private func retrySubscriptionFetch() async {
        print("🎵 Retrying subscription fetch...")
        try? await Task.sleep(nanoseconds: 2_000_000_000) // Wait 2 seconds
        
        do {
            let subscription = try await MusicSubscription.current
            await MainActor.run {
                self.musicSubscription = subscription
                print("🎵 Subscription retry successful: canPlay=\(subscription.canPlayCatalogContent)")
            }
        } catch {
            print("❌ Subscription retry failed: \(error)")
            await handleSubscriptionError(error)
        }
    }
    
    // ENHANCED: Better error handling for offline scenarios
    private func handleSubscriptionError(_ error: Error) async {
        if let musicError = error as? MusicSubscription.Error {
            switch musicError {
            case .permissionDenied:
                await MainActor.run {
                    self.authorizationError = "Music access denied. Please enable in Settings."
                    self.subscriptionStatusText = "Apple Music access required"
                }
            case .privacyAcknowledgementRequired:
                await MainActor.run {
                    self.authorizationError = "Please accept Apple Music privacy policy."
                    self.subscriptionStatusText = "Privacy acknowledgment required"
                }
            case .unknown:
                await MainActor.run {
                    self.authorizationError = "Unable to check subscription. Please check your internet connection."
                    self.subscriptionStatusText = "Connection required to verify subscription"
                }
            @unknown default:
                await MainActor.run {
                    self.authorizationError = "Subscription error: \(error.localizedDescription)"
                    self.subscriptionStatusText = "Unable to verify subscription"
                }
            }
        } else {
            await MainActor.run {
                self.authorizationError = "Network error: \(error.localizedDescription)"
                self.subscriptionStatusText = "Please check your internet connection"
            }
        }
    }
    
    // ENHANCED: Check if user can play music (removed Voice Plan references)
    var canPlayMusic: Bool {
        guard isAuthorized else {
            print("🎵 canPlayMusic: false - not authorized")
            return false
        }
        
        guard let subscription = musicSubscription else {
            print("🎵 canPlayMusic: false - no subscription object")
            return false
        }
        
        let canPlay = subscription.canPlayCatalogContent
        print("🎵 canPlayMusic: \(canPlay)")
        return canPlay
    }
    
    // ENHANCED: Check if subscription offer should be shown
    var shouldOfferSubscription: Bool {
        guard isAuthorized else { return false }
        return musicSubscription?.canBecomeSubscriber ?? false
    }
    
    // ENHANCED: Show subscription offer with affiliate token
    func showSubscriptionOffer() {
        subscriptionOfferOptions.messageIdentifier = .playMusic
        subscriptionOfferOptions.affiliateToken = affiliateToken
        isShowingSubscriptionOffer = true
        print("🎵 Showing subscription offer with affiliate token: \(affiliateToken)")
    }
    
    // SIMULATOR: Create mock subscription for testing different states
    #if targetEnvironment(simulator)
    private func createMockSubscriptionForSimulator() async {
        await MainActor.run {
            // You can change this to test different scenarios:
            // - Set to "subscribed" to test successful subscription flow
            // - Set to "unsubscribed" to test subscription offer flow
            // - Set to "restricted" to test restricted device flow
            let mockState = "subscribed" // Change this for testing
            
            switch mockState {
            case "subscribed":
                subscriptionStatusText = "✅ Apple Music subscription active"
                print("🎵 Simulator: Mocking active subscription")
            case "unsubscribed":
                subscriptionStatusText = "Apple Music subscription required"
                print("🎵 Simulator: Mocking no subscription")
            case "restricted":
                subscriptionStatusText = "Apple Music not available on this device"
                print("🎵 Simulator: Mocking restricted access")
            default:
                subscriptionStatusText = "✅ Apple Music subscription active"
            }
            
            isCheckingSubscription = false
        }
    }
    #endif
    
    // SAFE: Only call when user actually needs music access
    func requestAuthorizationWhenNeeded() async {
        guard !isAuthorized else {
            if musicSubscription == nil {
                await fetchInitialSubscription()
            }
            return
        }
        
        await requestAuthorizationForOnboarding()
    }
    
    // CLEANUP: Cancel tasks on deinit
    deinit {
        authorizationTask?.cancel()
        subscriptionTask?.cancel()
    }
}

// HELPER: Timeout function for network operations
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

// ENHANCED: ViewModifier with better subscription handling
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
            .alert("Apple Music Access", isPresented: $showingErrorAlert) {
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
                Text("Enable Apple Music access in Settings → Privacy & Security → Media & Apple Music")
            }
            .onChange(of: authManager.authorizationError) { error in
                showingErrorAlert = error != nil
            }
    }
}
