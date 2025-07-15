//
//  PlaylistPreferenceSection.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 18/07/2025.
//


import SwiftUI
import Foundation

// MARK: - Playlist Loading Preference
enum PlaylistLoadingPreference: String, CaseIterable {
    case language = "language_priority"
    case region = "region_priority"
    
    var displayName: String {
        switch self {
        case .language:
            return "Interface Language"
        case .region:
            return "Local Culture"
        }
    }
    
    var description: String {
        switch self {
        case .language:
            return "Songs match phone language"
        case .region:
            return "Songs match current location"
        }
    }
    
    var icon: String {
        switch self {
        case .language:
            return "globe"
        case .region:
            return "location"
        }
    }
}

// MARK: - Preference Manager
@MainActor
class PlaylistPreferenceManager: ObservableObject {
    static let shared = PlaylistPreferenceManager()
    
    @Published var loadingPreference: PlaylistLoadingPreference {
        didSet {
            UserDefaults.standard.set(loadingPreference.rawValue, forKey: preferenceKey)
            print("🎵 Playlist preference changed to: \(loadingPreference.displayName)")
        }
    }
    
    private let preferenceKey = "PlaylistLoadingPreference"
    
    private init() {
        let savedPreference = UserDefaults.standard.string(forKey: preferenceKey) ?? PlaylistLoadingPreference.region.rawValue
        self.loadingPreference = PlaylistLoadingPreference(rawValue: savedPreference) ?? .region
    }
    
    func getPlaylistLoadingOrder(language: String, region: String) -> [String] {
        switch loadingPreference {
        case .language:
            return [
                "\(language)-\(region)",
                "\(language)-US",
                "\(language)",
                "\(region.lowercased())-\(region)",
                "en-US"
            ]
        case .region:
            return [
                "\(language)-\(region)",
                "\(region.lowercased())-\(region)",
                "\(language)-US",
                "\(language)",
                "en-US"
            ]
        }
    }
}
