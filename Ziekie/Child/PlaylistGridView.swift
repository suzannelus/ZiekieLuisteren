//
//  PlaylistRowView.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 27/03/2025.
//

import SwiftUI
import MusicKit

struct PlaylistGridView: View {
    let playlist: Playlist
    
    var body: some View {
        NavigationLink(destination: PlaylistDetailView(playlistId: playlist.id)) {
            ZStack(alignment: .bottomLeading) {
                Group {
                    if let image = playlist.customImage {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Image("WheelsOnTheBus")
                            .resizable()
                            .scaledToFit()
                            .aspectRatio(contentMode: .fit)
                    }
                }
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(playlist.name)
                        .navigation()
                    
                    HStack {
                        Text("\(playlist.songs.count) ")
                        Image(systemName: "music.note")
                        Spacer()
                    }
                    .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color.white.opacity(0.9).clipShape(RoundedRectangle(cornerRadius: 12)))
                .padding(8)
            }
        }
    }
}

#Preview {
    PlaylistGridView(playlist: Playlist(name: "Sample Playlist", customImage: nil, imageGenerationConcept: "Concept voor een afbeelding", songs: []))
}
