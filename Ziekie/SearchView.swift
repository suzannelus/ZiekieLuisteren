//
//  ContentView.swift
//  ziekie
//
//  Created by Suzanne Lustenhouwer on 13/02/2023.
//
// done with IOS Academy youtube https://www.youtube.com/watch?v=-t9Arg7LP1Q
import MusicKit
import SwiftUI



struct Item: Identifiable, Hashable {
    var id = UUID()
    let name: String
    let artist: String
    let imageURL: URL?
}


struct Search: View {
    
    @State var songs = [Item]()
    
    var body: some View {
        NavigationView {
            List(songs) { song in
                HStack {
                    AsyncImage(url: song.imageURL)
                        .frame(width: 75, height: 75, alignment: .center)
                    VStack(alignment: .leading) {
                        Text(song.name)
                            .font(.title3)
                        Text(song.artist)
                            .font(.footnote)
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            fetchMusic()
        }
    }
    
    // ios 16 gives us more options but for now choose musiccatalogsearchrequest
    private let request: MusicCatalogSearchRequest = {
        var request = MusicCatalogSearchRequest(term: "Happy", types: [Song.self])
        request.limit = 5
        return request
    }()
    
    private func fetchMusic() {
        Task {
            // request permission
         let status = await MusicAuthorization.request()
            switch status {
            case.authorized:
                
            
                // request -> response
                
                do {
                    let result = try await request.response()
                    self.songs = result.songs.compactMap({
                        return.init(name: $0.title,
                                    artist: $0.artistName,
                                    imageURL: $0.artwork?.url(width: 75, height: 75))
                    })
                    print(String(describing: songs[0]))
                } catch {
                    print(String(describing: error))
                }
                
                // assign songs
                
            default:
                break
                
                
                // add other status cases
            }
        }
    }
}

struct Search_Previews: PreviewProvider {
    static var previews: some View {
        Search()
    }
}
