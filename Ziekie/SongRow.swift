//
//  SongRow.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 17/02/2023.
//

import SwiftUI

struct SongRow: View {
    let musicItems: MusicItem
    
    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let customImage = musicItems.customImage {
                    customImage
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                } else {
                    Image(musicItems.image ?? "")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                }
            }
            .cornerRadius(8)
            
            Text(musicItems.title)
                .font(.headline)
                .lineLimit(1)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        SongRow(musicItems: MusicItem(
            songID: "preview",
            title: "Preview Song",
            url: nil,
            image: "preview",
            playCount: 0,
            imageGenerationConcepts: nil
        ))
    }
}
