//
//  SubscriptionStatusView.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 06/07/2025.
//

import SwiftUI

struct SubscriptionStatusView: View {
    @ObservedObject private var authManager = MusicAuthManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Apple Music Subscription")
                .font(.title)
                .bold()
            
            if authManager.isAuthorized {
                if let subscription = authManager.musicSubscription {
                    VStack(spacing: 10) {
                        Text("Authorized ✅")
                        if subscription.canPlayCatalogContent {
                            Text("You can play music from Apple Music")
                        } else {
                            Text("You cannot play Apple Music catalog")
                        }
                        
                        if subscription.canBecomeSubscriber {
                            Text("You can subscribe to Apple Music")
                                .foregroundStyle(.orange)
                            Button("Show Offer Sheet") {
                                authManager.showSubscriptionOffer()
                            }
                        } else {
                            Text("Already subscribed or not eligible to subscribe")
                                .foregroundStyle(.green)
                        }
                    }
                } else {
                    Text("Loading subscription info...")
                }
            } else {
                Text("Not authorized ❌")
                Button("Request Access") {
                    Task {
                        await authManager.requestAuthorizationWhenNeeded()
                    }
                }
            }
        }
        .padding()
        .handleMusicAuth()    }
}

#Preview {
    SubscriptionStatusView()
}
