//
//  Data.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 14/02/2023.
//

import Foundation
import SwiftUI

// MARK: - Core Data Models

struct Playlist: Identifiable, Hashable, Codable {
    let id = UUID()
    var name: String
    var customImage: Image?
    var imageGenerationConcept: String?
    var songs: [MusicItem]
    var colorPalette: ColorPalette?
    
    // MARK: - Initializers
    init(name: String, customImage: Image? = nil, imageGenerationConcept: String? = nil, songs: [MusicItem] = []), colorPalette: ColorPalette? = nil) {

        self.name = name
        self.customImage = customImage
        self.imageGenerationConcept = imageGenerationConcept
        self.songs = songs
        self.colorPalette = colorPalette

    }
    
    // MARK: - Codable Implementation
    
    
    enum CodingKeys: String, CodingKey {
            case id, songID, name, artworkURL, playCount, lastPlayedDate
            case imageGenerationConcepts, playHistory, totalPlayTimeSeconds, colorPalette
        }
    
    func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(name, forKey: .name)
            try container.encode(imageGenerationConcept, forKey: .imageGenerationConcept)
            try container.encode(songs, forKey: .songs)
            try container.encode(colorPalette, forKey: .colorPalette)
        }
    
    init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let decodedId = try container.decode(UUID.self, forKey: .id)
            self.name = try container.decode(String.self, forKey: .name)
            self.imageGenerationConcept = try container.decodeIfPresent(String.self, forKey: .imageGenerationConcept)
            self.songs = try container.decode([UpdatedMusicItem].self, forKey: .songs)
            self.colorPalette = try container.decodeIfPresent(ColorPalette.self, forKey: .colorPalette)
            self.customImage = nil // Will be loaded separately
        }
    
    // MARK: - Color Helpers
    var effectivePalette: ColorPalette {
            return colorPalette ?? .default
        }
    
    // MARK: - Hashable & Equatable
    static func == (lhs: UpdatedPlaylist, rhs: UpdatedPlaylist) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct MusicItem: Identifiable, Hashable, Codable {
    let id = UUID()
    var songID: String
    var title: String
    var artworkURL: URL?
    var playCount: Int = 0
    var lastPlayedDate: Date?
    var customImage: Image?
    var imageGenerationConcepts: String?
    
    // MARK: Color palette for individual songs
    var colorPalette: ColorPalette?

    
    // MARK: - Analytics Properties
    var playHistory: [PlaySession] = []
    var totalPlayTimeSeconds: Int = 0
    
    // MARK: - Computed Analytics Properties
    var playsThisMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        return playHistory.filter { $0.playDate >= startOfMonth }.count
    }
    
    var playsThisWeek: Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        return playHistory.filter { $0.playDate >= startOfWeek }.count
    }
    
    // MARK: - Initializers
    init(songID: String, title: String, artworkURL: URL? = nil, playCount: Int = 0,
         lastPlayedDate: Date? = nil, customImage: Image? = nil, imageGenerationConcepts: String? = nil) {
        self.songID = songID
        self.title = title
        self.artworkURL = artworkURL
        self.playCount = playCount
        self.lastPlayedDate = lastPlayedDate
        self.customImage = customImage
        self.imageGenerationConcepts = imageGenerationConcepts
        self.colorPalette = colorPalette

        self.playHistory = []
        self.totalPlayTimeSeconds = 0
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case id, songID, title, artworkURL, playCount, lastPlayedDate
        case imageGenerationConcepts, playHistory, totalPlayTimeSeconds
    }
    
    func encode(to encoder: Encoder) throws {
          var container = encoder.container(keyedBy: CodingKeys.self)
          try container.encode(id, forKey: .id)
          try container.encode(songID, forKey: .songID)
          try container.encode(title, forKey: .title)
          try container.encode(artworkURL, forKey: .artworkURL)
          try container.encode(playCount, forKey: .playCount)
          try container.encode(lastPlayedDate, forKey: .lastPlayedDate)
          try container.encode(imageGenerationConcepts, forKey: .imageGenerationConcepts)
          try container.encode(playHistory, forKey: .playHistory)
          try container.encode(totalPlayTimeSeconds, forKey: .totalPlayTimeSeconds)
          try container.encode(colorPalette, forKey: .colorPalette)
      }
    
    init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let decodedId = try container.decode(UUID.self, forKey: .id)
            self.songID = try container.decode(String.self, forKey: .songID)
            self.title = try container.decode(String.self, forKey: .title)
            self.artworkURL = try container.decodeIfPresent(URL.self, forKey: .artworkURL)
            self.playCount = try container.decode(Int.self, forKey: .playCount)
            self.lastPlayedDate = try container.decodeIfPresent(Date.self, forKey: .lastPlayedDate)
            self.imageGenerationConcepts = try container.decodeIfPresent(String.self, forKey: .imageGenerationConcepts)
            self.playHistory = try container.decode([PlaySession].self, forKey: .playHistory)
            self.totalPlayTimeSeconds = try container.decode(Int.self, forKey: .totalPlayTimeSeconds)
            self.colorPalette = try container.decodeIfPresent(ColorPalette.self, forKey: .colorPalette)
            self.customImage = nil
        }
    
    var effectivePalette: ColorPalette {
           return colorPalette ?? .default
       }
    
    
    
    // MARK: - Hashable & Equatable
    
       static func == (lhs: UpdatedMusicItem, rhs: UpdatedMusicItem) -> Bool {
           lhs.id == rhs.id &&
           lhs.songID == rhs.songID &&
           lhs.title == rhs.title &&
           lhs.artworkURL == rhs.artworkURL &&
           lhs.playCount == rhs.playCount &&
           lhs.lastPlayedDate == rhs.lastPlayedDate &&
           lhs.imageGenerationConcepts == rhs.imageGenerationConcepts &&
           lhs.colorPalette == rhs.colorPalette
       }
    
    func hash(into hasher: inout Hasher) {
          hasher.combine(id)
          hasher.combine(songID)
          hasher.combine(title)
          hasher.combine(artworkURL)
          hasher.combine(playCount)
          hasher.combine(lastPlayedDate)
          hasher.combine(imageGenerationConcepts)
          hasher.combine(colorPalette)
    }
}

struct PlaySession: Codable, Identifiable {
    let id = UUID()
    let playDate: Date
    let durationSeconds: Int
    let completedSong: Bool
    
    init(durationSeconds: Int = 0, completedSong: Bool = false) {
        self.playDate = Date()
        self.durationSeconds = durationSeconds
        self.completedSong = completedSong
    }
}

// MARK: - Localization Models

struct LocalizedPlaylistBundle: Codable {
    let regionCode: String
    let languageCode: String
    let playlists: [LocalizedPlaylist]
}

struct LocalizedPlaylist: Codable {
    let name: String
    let localizedName: String
    let imageGenerationConcept: String
    let songs: [LocalizedSong]
}

struct LocalizedSong: Codable {
    let appleMusicID: String
    let title: String
    let artist: String
    let imageGenerationConcept: String
}

// MARK: - Playlists Container

@MainActor
class PlaylistsContainer: ObservableObject {
    static let shared = PlaylistsContainer()
    
    // MARK: - Published Properties
    @Published var playlists: [Playlist] = []
    @Published var isLoading = false
    @Published var hasInitialized = false
    @Published var loadingMessage = "Initializing..."
    
    // MARK: - Private Properties
    private let userDefaultsKey = "SavedPlaylists"
    
    // MARK: - Initialization
    private init() {
        print("📁 PlaylistsContainer initialized")
        // NO WORK ON MAIN THREAD - everything deferred loadPlaylistsFromDisk()
    }
    
    // MARK: - Public Methods
    
    // CRITICAL: This method does ZERO main thread work
        func initializeIfNeeded() async {
            guard !hasInitialized else { return }
            
            print("📁 Starting background initialization...")
            isLoading = true
            loadingMessage = "Loading playlists..."
            
            // ALL heavy work happens off main thread
            let result = await Task.detached(priority: .userInitiated) { [weak self] in
                await self?.loadAllDataBackground() ?? []
            }.value
            
            // Quick UI update on main thread
            withAnimation(.easeInOut(duration: 0.3)) {
                self.playlists = result
                self.isLoading = false
                self.hasInitialized = true
                self.loadingMessage = ""
            }
            
            print("✅ Initialization complete - \(result.count) playlists")
        }
    
    // BACKGROUND: All heavy lifting happens here
     private func loadAllDataBackground() async -> [Playlist] {
         print("📁 Loading data on background thread...")
         
         // Try to load from UserDefaults first
         if let savedData = UserDefaults.standard.data(forKey: userDefaultsKey),
            let savedPlaylists = try? JSONDecoder().decode([Playlist].self, from: savedData) {
             print("📁 Loaded \(savedPlaylists.count) saved playlists")
             return savedPlaylists
         }
         
         // Load from localized files if no saved data
         return await loadLocalizedPlaylistsOrDefaults()
     }
    
  
    
    // THREAD-SAFE: Playlist operations
        func createPlaylistAsync(name: String, image: Image, concept: String, songs: [MusicItem] = []) async {
            let newPlaylist = Playlist(
                name: name,
                customImage: image,
                imageGenerationConcept: concept,
                songs: songs
            )
            
            withAnimation(.easeInOut(duration: 0.3)) {
                playlists.append(newPlaylist)
            }
            
            // Save in background
            Task.detached(priority: .background) { [weak self] in
                await self?.savePlaylistsBackground()
            }
            
            print("✅ Created playlist: \(name)")
        }
    
    // BACKGROUND: Save operation
        private func savePlaylistsBackground() {
            do {
                let encoded = try JSONEncoder().encode(playlists)
                UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
                print("💾 Saved playlists in background")
            } catch {
                print("❌ Failed to save: \(error)")
            }
        }
    
    /// Update an existing playlist
        func updatePlaylist(_ playlist: Playlist) {
            guard let index = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
            
            withAnimation {
                playlists[index] = playlist
            }
            
            Task.detached(priority: .background) { [weak self] in
                await self?.savePlaylistsBackground()
            }
        }
    
    /// Delete a playlist
    func deletePlaylist(id: UUID) {
           withAnimation {
               playlists.removeAll { $0.id == id }
           }
           
           Task.detached(priority: .background) { [weak self] in
               await self?.savePlaylistsBackground()
           }
       }
    
    /// Delete multiple playlists
    func batchDeletePlaylists(ids: Set<UUID>) {
            withAnimation {
                playlists.removeAll { ids.contains($0.id) }
            }
            
            Task.detached(priority: .background) { [weak self] in
                await self?.savePlaylistsBackground()
            }
        }
    
    /// Add a song to a playlist
    func addSongToPlaylist(playlistId: UUID, song: MusicItem) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistId }) else {
            print("❌ Playlist not found for adding song")
            return
        }
        
        withAnimation {
            playlists[index].songs.append(song)
        }
        
        savePlaylistsToDisk()
        objectWillChange.send()
        print("✅ Added song '\(song.title)' to playlist")
    }
    
    /// Remove a song from a playlist
    func removeSongFromPlaylist(playlistId: UUID, songId: String) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistId }) else {
            print("❌ Playlist not found for removing song")
            return
        }
        
        let songTitle = playlists[index].songs.first { $0.songID == songId }?.title ?? "Unknown"
        
        withAnimation {
            playlists[index].songs.removeAll { $0.songID == songId }
        }
        
        savePlaylistsToDisk()
        objectWillChange.send()
        print("✅ Removed song '\(songTitle)' from playlist")
    }
    
    /// Add multiple songs to a playlist
    func addSongsAsync(_ songs: [MusicItem], to playlist: Playlist) async {
        guard let index = playlists.firstIndex(where: { $0.id == playlist.id }) else {
            print("❌ Playlist not found: \(playlist.name)")
            return
        }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            playlists[index].songs.append(contentsOf: songs)
        }
        
        savePlaylistsToDisk()
        objectWillChange.send()
        print("✅ Added \(songs.count) songs to \(playlist.name)")
    }
    
    // MARK: - Private Methods
    
    /// Load playlists from disk synchronously
    private func loadPlaylistsFromDisk() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            print("📱 No saved playlists found, will load defaults later")
            return
        }
        
        do {
            playlists = try JSONDecoder().decode([Playlist].self, from: data)
            hasInitialized = true
            print("✅ Loaded \(playlists.count) playlists from disk")
        } catch {
            print("❌ Failed to load playlists from disk: \(error.localizedDescription)")
            // Don't set hasInitialized to allow async loading of defaults
        }
    }
    
    /// Load playlists asynchronously (from localized files or defaults)
    private func loadPlaylistsAsync() async -> [Playlist] {
        // If we already have playlists loaded from disk, return them
        if !playlists.isEmpty {
            return playlists
        }
        
        // Load from localized bundle or create defaults
        return await Task.detached(priority: .userInitiated) {
            await self.loadLocalizedPlaylistsOrDefaults()
        }.value
    }
    
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
                return "Songs match phone language (English songs for English interface)"
            case .region:
                return "Songs match current location (Dutch songs in Netherlands)"
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
            // Load saved preference or default to region priority
            let savedPreference = UserDefaults.standard.string(forKey: preferenceKey) ?? PlaylistLoadingPreference.region.rawValue
            self.loadingPreference = PlaylistLoadingPreference(rawValue: savedPreference) ?? .region
            print("🎵 Loaded playlist preference: \(loadingPreference.displayName)")
        }
        
        // MARK: - Playlist Loading Logic
        func getPlaylistLoadingOrder(language: String, region: String) -> [String] {
            switch loadingPreference {
            case .language:
                return [
                    "\(language)-\(region)",  // en-NL (exact match)
                    "\(language)-US",         // en-US (language match)
                    "\(language)",            // en (language only)
                    "\(region.lowercased())-\(region)",  // nl-NL (regional fallback)
                    "en-US"                   // universal fallback
                ]
                
            case .region:
                return [
                    "\(language)-\(region)",  // en-NL (exact match)
                    "\(region.lowercased())-\(region)",  // nl-NL (regional content)
                    "\(language)-US",         // en-US (language match with default region)
                    "\(language)",            // en (language only)
                    "en-US"                   // universal fallback
                ]
            }
        }
    }
    
    
    
    // BACKGROUND: File operations
        private func loadLocalizedPlaylistsOrDefaults() async -> [Playlist] {
            let currentLocale = Locale.current
            let regionCode = currentLocale.region?.identifier ?? "US"
            let languageCode = currentLocale.language.languageCode?.identifier ?? "en"
            
            print("📁 Loading for locale: \(languageCode)-\(regionCode)")
            
            // Try localized bundle
            if let bundle = await loadLocalizedPlaylistBundle(region: regionCode, language: languageCode) {
                return createPlaylistsFromBundle(bundle)
            }
            
            // Fall back to defaults
            return createDefaultPlaylists()
        }
    
        
        // Updated method to use preference manager
    private func loadLocalizedPlaylistBundle(region: String, language: String) async -> LocalizedPlaylistBundle? {
        let preferenceManager = PlaylistPreferenceManager.shared
        let loadingOrder = preferenceManager.getPlaylistLoadingOrder(language: language, region: region)
        
        print("📁 Using \(preferenceManager.loadingPreference.displayName) priority")
        
        for filename in loadingOrder {
            if let bundle = loadPlaylistBundleFromFile(filename: filename) {
                print("✅ Loaded: \(filename).json")
                return bundle
            }
        }
        
        return nil
    }

    
    
    
    // SYNCHRONOUS: File operations (called from background thread)
        private func loadPlaylistBundleFromFile(filename: String) -> LocalizedPlaylistBundle? {
            guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
                print("📁 No JSON file: \(filename).json")
                return nil
            }
            
            do {
                let data = try Data(contentsOf: url)
                let bundle = try JSONDecoder().decode(LocalizedPlaylistBundle.self, from: data)
                print("📁 Loaded JSON: \(filename).json")
                return bundle
            } catch {
                print("❌ Error loading \(filename).json: \(error)")
                return nil
            }
        }
    
    
    
    // BACKGROUND: Create playlists from bundle
        private func createPlaylistsFromBundle(_ bundle: LocalizedPlaylistBundle) -> [Playlist] {
            return bundle.playlists.map { localizedPlaylist in
                let songs = localizedPlaylist.songs.map { localizedSong in
                    MusicItem(
                        songID: localizedSong.appleMusicID,
                        title: localizedSong.title,
                        artworkURL: nil,
                        imageGenerationConcepts: localizedSong.imageGenerationConcept
                    )
                }
                
                return Playlist(
                    name: localizedPlaylist.localizedName,
                    customImage: nil,
                    imageGenerationConcept: localizedPlaylist.imageGenerationConcept,
                    songs: songs
                )
            }
        }
    
    /// Create default playlists when no localized content is available
    private func createDefaultPlaylists() -> [Playlist] {
        let defaultPlaylistData = [
            (name: "Lullabies", concept: "A peaceful starry night with a sleeping moon and stars"),
            (name: "Party Songs", concept: "Colorful party balloons, confetti, and dancing children"),
        ]
        
        return defaultPlaylistData.map { data in
            Playlist(
                name: data.name,
                customImage: nil,
                imageGenerationConcept: data.concept,
                songs: []
            )
        }
    }
    
    /// Save playlists to disk
    private func savePlaylistsToDisk() {
        do {
            let encoded = try JSONEncoder().encode(playlists)
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            print("💾 Saved \(playlists.count) playlists to disk")
        } catch {
            print("❌ Failed to save playlists: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Legacy Compatibility Methods
    
    /// Legacy method for backward compatibility
    func createPlaylist(name: String, image: Image, concept: String) {
        Task {
            await createPlaylistAsync(name: name, image: image, concept: concept)
        }
    }
    
    /// Legacy method for backward compatibility
    func addSongs(_ songs: [MusicItem], to playlist: Playlist) {
        Task {
            await addSongsAsync(songs, to: playlist)
        }
    }
    
    /// Legacy method for backward compatibility
    func addSong(_ song: MusicItem, to playlist: Playlist) {
        Task {
            await addSongsAsync([song], to: playlist)
        }
    }
}

