//
//  Data.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 14/02/2023.
//

import Foundation

struct MusicItem: Hashable {
   
    
 //   var id = MusicItemID
    var duration: TimeInterval?
    var title: String?
    var url: URL?
    var image: String?
    var playlist: Playlist
    var playCount: Int?
    var lastPlayedDate: Date?

}


var MusicItems =
[
    MusicItem(title: "De Wielen van de Bus", playlist: .kindjes)
]


enum Playlist: String {
    case kindjes
    case disney
    case sesamstraat
    case sinterklaas
    case kerst
    case verhalen
}
