//
//  SongView.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 15/02/2023.
//

import SwiftUI
import MusicKit

struct SongView: View {
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [Color("Background1"), Color("Background2")], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                VStack {
                    
                }
            }
        }
        .navigationTitle("Kindjes")
        // Start observing changes to the music subscription.
        .task {
            for await subscription in MusicSubscription.subscriptionUpdates {
                musicSubscription = subscription
            }
        }
        // Display the subscription offer when appropriate.
            .musicSubscriptionOffer(isPresented: $isShowingSubscriptionOffer, options: subscriptionOfferOptions)
    }
        
    
    
    // MARK: - Playback
    
    /// The MusicKit player to use for Apple Music playback.
    private let player = ApplicationMusicPlayer.shared
    
    /// The state of the MusicKit player to use for Apple Music playback.
    @ObservedObject private var playerState = ApplicationMusicPlayer.shared.state
    
    /// `true` when the album detail view sets a playback queue on the player.
    @State private var isPlaybackQueueSet = false
    
    /// `true` when the player is playing.
    private var isPlaying: Bool {
        return (playerState.playbackStatus == .playing)
    }
    
    /// The Apple Music subscription of the current user.
    @State private var musicSubscription: MusicSubscription?
    
    /// The localized label of the Play/Pause button when in the play state.
    private let playButtonTitle: LocalizedStringKey = "Play"
    
    /// The localized label of the Play/Pause button when in the paused state.
    private let pauseButtonTitle: LocalizedStringKey = "Pause"
    
    /// `true` when the album detail view needs to disable the Play/Pause button.
    private var isPlayButtonDisabled: Bool {
        let canPlayCatalogContent = musicSubscription?.canPlayCatalogContent ?? false
        return !canPlayCatalogContent
    }
    
    /// `true` when the album detail view needs to offer an Apple Music subscription to the user.
    private var shouldOfferSubscription: Bool {
        let canBecomeSubscriber = musicSubscription?.canBecomeSubscriber ?? false
        return canBecomeSubscriber
    }
    
    /// A declaration of the Play/Pause button, and (if appropriate) the Join button, side by side.
    private var playButtonRow: some View {
        HStack {
            Button(action: handlePlayButtonSelected) {
                HStack {
                    Image(systemName: (isPlaying ? "pause.fill" : "play.fill"))
                    Text((isPlaying ? pauseButtonTitle : playButtonTitle))
                }
                .frame(maxWidth: 200)
            }
         //   .buttonStyle(.prominent)
            .disabled(isPlayButtonDisabled)
            .animation(.easeInOut(duration: 0.1), value: isPlaying)
            
            if shouldOfferSubscription {
                subscriptionOfferButton
            }
        }
    }
    
    /// The action to perform when the user taps the Play/Pause button.
    private func handlePlayButtonSelected() {
        if !isPlaying {
            if !isPlaybackQueueSet {
              //  player.queue = [album]
                isPlaybackQueueSet = true
                beginPlaying()
            } else {
                Task {
                    do {
                        try await player.play()
                    } catch {
                        print("Failed to resume playing with error: \(error).")
                    }
                }
            }
        } else {
            player.pause()
        }
    }
    /// A convenience method for beginning music playback.
    ///
    /// Call this instead of `MusicPlayer`’s `play()`
    /// method whenever the playback queue is reset.
    private func beginPlaying() {
        Task {
            do {
                try await player.play()
            } catch {
                print("Failed to prepare to play with error: \(error).")
            }
        }
    }
    // MARK: - Subscription offer
    
    private var subscriptionOfferButton: some View {
        Button(action: handleSubscriptionOfferButtonSelected) {
            HStack {
                Image(systemName: "applelogo")
                Text("Join")
            }
            .frame(maxWidth: 200)
        }
     //   .buttonStyle(.prominent)
    }
    /// The state that controls whether the album detail view displays a subscription offer for Apple Music.
    @State private var isShowingSubscriptionOffer = false
    
    /// The options for the Apple Music subscription offer.
    @State private var subscriptionOfferOptions: MusicSubscriptionOffer.Options = .default
    
    /// Computes the presentation state for a subscription offer.
    private func handleSubscriptionOfferButtonSelected() {
        subscriptionOfferOptions.messageIdentifier = .playMusic
   //     subscriptionOfferOptions.itemID = album.id
        isShowingSubscriptionOffer = true
    }
}


struct SongView_Previews: PreviewProvider {
    static var previews: some View {
        SongView()
    }
}
