import SwiftUI
import MusicKit
import StoreKit

public class MusicAuthManager: ObservableObject {
    public static let shared = MusicAuthManager()
    
    @Published public var musicSubscription: MusicSubscription?
    @Published public var isAuthorized = false
    @Published public var isShowingSubscriptionOffer = false
    @Published public var subscriptionOfferOptions: MusicSubscriptionOffer.Options = .default
    
    private init() {
        Task {
            await checkAuthorizationStatus()
            await startSubscriptionUpdates()
        }
    }
    
    @MainActor
    public func checkAuthorizationStatus() async {
        let status = await MusicAuthorization.request()
        isAuthorized = status == .authorized
    }
    
    private func startSubscriptionUpdates() async {
        for await subscription in MusicSubscription.subscriptionUpdates {
            await MainActor.run {
                self.musicSubscription = subscription
            }
        }
    }
    
    public var canPlayMusic: Bool {
        isAuthorized && (musicSubscription?.canPlayCatalogContent ?? false)
    }
    
    public var shouldOfferSubscription: Bool {
        isAuthorized && (musicSubscription?.canBecomeSubscriber ?? false)
    }
    
    func showSubscriptionOffer(messageId: MusicSubscriptionOffer.MessageIdentifier = .playMusic) {
            subscriptionOfferOptions.messageIdentifier = messageId
            isShowingSubscriptionOffer = true
        }
}

// ViewModifier to handle subscription checks
public struct MusicAuthHandling: ViewModifier {
    @StateObject private var authManager = MusicAuthManager.shared
    
    public func body(content: Content) -> some View {
        content
            .musicSubscriptionOffer(
                isPresented: $authManager.isShowingSubscriptionOffer,
                options: authManager.subscriptionOfferOptions
            )
    }
}

public extension View {
    func handleMusicAuth() -> some View {
        self.modifier(MusicAuthHandling())
    }
}
