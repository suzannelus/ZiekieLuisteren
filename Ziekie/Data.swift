//
//  Data.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 14/02/2023.
//

import Foundation

struct MusicItem: Identifiable, Hashable {
    var id = UUID()
  //  var duration: TimeInterval?
    var title: String
    var url: URL?
    var image: String?
    var playlist: Playlist
    var playCount = 0
    var lastPlayedDate: Date?

}


var musicItems =
[
    MusicItem(title: "De Wielen van de Bus", url: URL(string: "https://music.apple.com/nl/album/de-wielen-van-de-bus/1134585515?i=1134585819&l=en"), image: "Bus", playlist: .kindjes, playCount: 0),
    MusicItem(title: "In de maneschijn", url: URL(string: "https://music.apple.com/nl/album/in-de-maneschijn/1313809266?i=1313810537&l=en"), image: "Maneschijn", playlist: .kindjes, playCount: 0),
    MusicItem(title: "Dikkertje Dap", url: URL(string: "https://music.apple.com/nl/album/dikkertje-dap-titelsong/1444323550?i=1444323823&l=en"), image: "DikkertjeDap", playlist: .kindjes, playCount: 0),
    MusicItem(title: "Helicopter", url: URL(string: "https://music.apple.com/nl/album/helicopter/1512219762?i=1512219916&l=en"), image: "Helicopter", playlist: .kindjes, playCount: 0)
]


enum Playlist: String {
    case kindjes
    case disney
    case sesamstraat
    case sinterklaas
    case kerst
    case verhalen
}
