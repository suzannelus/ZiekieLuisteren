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
    
    private var colorPalette: ColorPalette {
        playlist.effectivePalette
    }
    
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
                .cornerRadius(25)
               
                VStack(alignment: .leading, spacing: 2) {
                    Text(playlist.name)
                        .navigation()
                        .foregroundColor(colorPalette.textColor)
                        
                    
                    HStack(spacing: 0) {
                        Text("\(playlist.songs.count)")
                        Image(systemName: "music.note")
                        Spacer()
                        
                    }
                    .foregroundColor(.teal)
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
                .glassEffect()
                .shadow(
                    color: colorPalette.backgroundColor.opacity(0.8),
                    radius: 5,
                    x: 0,
                    y: 2
                )
            }
        }
        .scaleEffect(0.98) // Subtle scale for better touch feedback
        .animation(.easeInOut(duration: 0.2), value: colorPalette.primaryColor)
    }
}



#Preview {
    // Create a sample playlist with colors for preview
    let samplePlaylist = Playlist(
        name: "Kinderliedjest",
        customImage: nil,
        imageGenerationConcept: "Colorful music theme",
        songs: [],
     
        /*
        palette: ColorPalette(
            primary: UIColor.systemBlue,
            secondary: UIColor.systemMint,
            accent: UIColor.systemPurple,
            background: UIColor.systemBackground,
            text: UIColor.label
       
        )
         */
    )
    
    PlaylistGridView(playlist: samplePlaylist)
        .frame(width: 200, height: 200)
}



 #Preview {
 PlaylistGridView(playlist: Playlist(name: "Sample Playlist", customImage: nil, imageGenerationConcept: "Concept voor een afbeelding", songs: []))
 }
 
