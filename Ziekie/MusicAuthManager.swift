import SwiftUI
import MusicKit

public class MusicAuthManager: ObservableObject {
    static let shared = MusicAuthManager()
    
    @Published var musicSubscription: MusicSubscription?
    @Published var isAuthorized = false
    @Published var isShowingSubscriptionOffer = false
    @Published var subscriptionOfferOptions: MusicSubscriptionOffer.Options = .default
    @Published var isWelcomeViewPresented: Bool = true
    
    private init() {
        let authorizationStatus = MusicAuthorization.currentStatus
        isAuthorized = authorizationStatus == .authorized
        isWelcomeViewPresented = !isAuthorized
        
        Task {
            await checkAuthorizationStatus()
            await startSubscriptionUpdates()
        }
    }
    
    @MainActor
    func checkAuthorizationStatus() async {
        let status = await MusicAuthorization.request()
        isAuthorized = status == .authorized
        isWelcomeViewPresented = !isAuthorized
    }
    
    private func startSubscriptionUpdates() async {
        for await subscription in MusicSubscription.subscriptionUpdates {
            await MainActor.run {
                self.musicSubscription = subscription
            }
        }
    }
    
    var canPlayMusic: Bool {
        isAuthorized && (musicSubscription?.canPlayCatalogContent ?? false)
    }
    
    var shouldOfferSubscription: Bool {
        isAuthorized && (musicSubscription?.canBecomeSubscriber ?? false)
    }
    
    func showSubscriptionOffer() {
        subscriptionOfferOptions.messageIdentifier = .playMusic
        isShowingSubscriptionOffer = true
    }
}

// ViewModifier to handle subscription checks and welcome view
struct MusicAuthHandling: ViewModifier {
    @StateObject private var authManager = MusicAuthManager.shared
    
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
    }
}

extension View {
    func handleMusicAuth() -> some View {
        self.modifier(MusicAuthHandling())
    }
}
