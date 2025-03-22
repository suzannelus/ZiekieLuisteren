//
//  Data.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 14/02/2023.
//

import Foundation
import SwiftUICore
import ImagePlayground
import PhotosUI

struct Playlist: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var customImage: Image?
    var imageGenerationConcept: String?
    var songs: [MusicItem]
    
    static func == (lhs: Playlist, rhs: Playlist) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct MusicItem: Identifiable, Hashable {
    var id = UUID()
    var songID: String
    var title: String
    var url: URL?
    var image: String?
    var playCount = 0
    var lastPlayedDate: Date?
    var customImage: Image?
    var imageGenerationConcepts: String?

    func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(songID)
            hasher.combine(title)
            hasher.combine(url)
            hasher.combine(image)
            hasher.combine(playCount)
            hasher.combine(lastPlayedDate)
            // Don't include customImage in hash as Image isn't Hashable
            hasher.combine(imageGenerationConcepts)
        }
    
    static func == (lhs: MusicItem, rhs: MusicItem) -> Bool {
           lhs.id == rhs.id &&
           lhs.songID == rhs.songID &&
           lhs.title == rhs.title &&
           lhs.url == rhs.url &&
           lhs.image == rhs.image &&
           lhs.playCount == rhs.playCount &&
           lhs.lastPlayedDate == rhs.lastPlayedDate &&
           lhs.imageGenerationConcepts == rhs.imageGenerationConcepts
       }
}

// Create a shared data model to manage playlists
class PlaylistsContainer: ObservableObject {
    static let shared = PlaylistsContainer()
    
    @Published var playlists: [Playlist] = []
    
    private init() {
        setupDefaultPlaylists()
    }
    
    private static let defaultSongs = [
        MusicItem(songID: "1134585819", title: "Wheels on the Bus", url: URL(string: "https://music.apple.com/us/album/wheels-on-the-bus"), image: "bus", playCount: 0, imageGenerationConcepts: "A colorful cartoon school bus with big wheels"),
        MusicItem(songID: "1313810537", title: "Twinkle Twinkle Little Star", url: URL(string: "https://music.apple.com/us/album/twinkle-twinkle"), image: "star", playCount: 0, imageGenerationConcepts: "Shining stars in a peaceful night sky"),
        MusicItem(songID: "1444323823", title: "Old MacDonald Had a Farm", url: URL(string: "https://music.apple.com/us/album/old-macdonald"), image: "farm", playCount: 0, imageGenerationConcepts: "A cheerful farm with animals and a smiling farmer")
    ]
    
    func setupDefaultPlaylists() {
        let defaultPlaylistData = [
            (name: "Lullabies", concept: "A peaceful starry night with a sleeping moon and stars"),
            (name: "Party Songs", concept: "Colorful party balloons, confetti, and dancing children"),
            (name: "All Time Favorites", concept: "Rainbow with musical notes and happy children dancing")
        ]
        
        // Only setup if there are no playlists yet
        guard playlists.isEmpty else { return }
        
        for data in defaultPlaylistData {
            let playlist = Playlist(
                name: data.name,
                customImage: Image(systemName: "music.note"),
                imageGenerationConcept: data.concept,
                songs: []
            )
            playlists.append(playlist)
        }
        
        // Add sample songs to Lullabies playlist
        if let lullabies = playlists.first(where: { $0.name == "Lullabies" }) {
            addSongs(Self.defaultSongs, to: lullabies)
        }
    }
    
    func createPlaylist(name: String, image: Image, concept: String) {
        let newPlaylist = Playlist(
            name: name,
            customImage: image,
            imageGenerationConcept: concept,
            songs: []
        )
        playlists.append(newPlaylist)
    }
    
    func addSongs(_ songs: [MusicItem], to playlist: Playlist) {
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[index].songs.append(contentsOf: songs)
        }
    }
    
    func addSong(_ song: MusicItem, to playlist: Playlist) {
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[index].songs.append(song)
        }
    }
}
