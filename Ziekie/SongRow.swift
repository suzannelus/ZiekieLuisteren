//
//  SongRow.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 17/02/2023.
//

import SwiftUI

struct SongRow: View {
    @State private var playCount = 0
    
    var musicItems: MusicItem
    
    
    var body: some View {
        ZStack {
            HStack {
                Image(musicItems.image ?? "")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .shadow(color: .accentColor, radius: 20)
                VStack(alignment: .leading) {
                    Text(musicItems.title)
                        .font(.largeTitle.width(.condensed))
                    Spacer()
                    Text("\(self.playCount)")
                    Button("Play") {
                        self.playCount += 1
                    }
                }
                
            }
          //  .padding()
        }
    }
}

struct SongRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            SongRow(musicItems: musicItems[0])
            SongRow(musicItems: musicItems[1])
            SongRow(musicItems: musicItems[2])
        }
    }
}
