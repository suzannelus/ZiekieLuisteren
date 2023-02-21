//
//  ZiekieApp.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 13/02/2023.
//

import SwiftUI
import MusicKit

@main
struct ZiekieApp: App {
    
   // @Binding var musicAuthorizationStatus: MusicAuthorization.Status

    var body: some Scene {
        WindowGroup {
           // SongView(isPreparedToPlay: true)
            WelcomeView(musicAuthorizationStatus: .constant(.notDetermined))
        }
    }
}
