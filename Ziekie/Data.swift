//
//  Data.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 14/02/2023.
//

import Foundation

struct MusicItem: Hashable {
   
    
 //   var id = MusicItemID
  //  var duration: TimeInterval?
    var title: String?
    var url: URL?
    var image: String?
    var playlist: Playlist
    var playCount: Int?
    var lastPlayedDate: Date?

}


var MusicItems =
[
    MusicItem(title: "De Wielen van de Bus", url: URL(string: "https://music.apple.com/nl/album/de-wielen-van-de-bus/1134585515?i=1134585819&l=en"), image: "Bus", playlist: .kindjes, playCount: 0),
    MusicItem(title: "In de maneschijn", url: URL(string: "https://music.apple.com/nl/album/in-de-maneschijn/1313809266?i=1313810537&l=en"), image: "Maneschijn", playlist: .kindjes, playCount: 0),
    MusicItem(title: "Dikkertje Dap", url: URL(string: "https://music.apple.com/nl/album/dikkertje-dap-titelsong/1444323550?i=1444323823&l=en"), image: "DikkertjeDap", playlist: .kindjes, playCount: 0)
]


enum Playlist: String {
    case kindjes
    case disney
    case sesamstraat
    case sinterklaas
    case kerst
    case verhalen
}
