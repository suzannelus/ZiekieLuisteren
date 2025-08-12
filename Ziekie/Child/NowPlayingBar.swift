import SwiftUI
import MusicKit

struct NowPlayingBar: View {
    @StateObject private var playerManager = MusicPlayerManager.shared
    @ObservedObject private var queue = ApplicationMusicPlayer.shared.queue
    @State private var isShowingSongView = false
    
    var body: some View {
        // Only show the bar when there's a currently playing song
        if let currentSong = playerManager.getCurrentSong() {
            VStack(spacing: 0) {
               
                
                
                HStack(spacing: 12) {
                    // Album artwork
                    Group {
                        if let customImage = currentSong.customImage {
                            customImage
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .cornerRadius(6)
                        } else if let artwork = queue.currentEntry?.artwork {
                            ArtworkImage(artwork, height: 50)
                                .cornerRadius(6)
                        } else {
                            Image("WheelsOnTheBus") // Your default image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50)
                                .cornerRadius(6)
                        }
                    }
                    
                    VStack {
                        // Song info
                        Text(currentSong.title)
                            .bodyLarge()
                            .lineLimit(1)
                        // Thin progress bar 
                        ProgressView(value: playerManager.currentProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                            .animation(.smooth(duration: 0.5), value: playerManager.currentProgress)
                    }
                    
                    
                    Spacer()
                    GlassEffectContainer(spacing: 20.0) {
                        Button(action: {
                            Task {
                                await playerManager.togglePlayback()
                            }
                        }) {
                            Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.title2)
                                .foregroundColor(currentSong.colorPalette?.textColor)
                                .glassEffect()
                        }
                        Button(action: {
                            Task {
                                await playerManager.playNext()
                            }
                        }) {
                            Image(systemName: "forward.fill")
                                .font(.title3)
                                .foregroundColor(.accentColor)
                                .glassEffect()
                        }
                    }
                }
                .padding()
            }
            .onTapGesture {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                isShowingSongView = true
            }
            .glassEffect()
            
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: playerManager.currentlyPlayingSongID)
            .fullScreenCover(isPresented: $isShowingSongView) {
                if let playlist = playerManager.currentPlaylist,
                   let currentSongID = playerManager.currentlyPlayingSongID {
                    SongView(playlist: playlist, initialSongID: currentSongID)
                }
            }
        }
    }
}


#Preview("NowPlayingBar - Playing") {
    VStack {
        Spacer()
        Text("Hello world")
        NowPlayingBar()
    }
}

