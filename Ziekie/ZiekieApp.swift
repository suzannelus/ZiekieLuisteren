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

@main
struct ZiekieApp: App {
    @StateObject private var authManager = MusicAuthManager.shared
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .handleMusicAuth()
        }
    }
}

// End of file 
// Existing code ...
