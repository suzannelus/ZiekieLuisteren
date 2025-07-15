//
//  ParentAnalyticsView.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 15/07/2025.
//


import SwiftUI
import Charts

struct ParentAnalyticsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var container = PlaylistsContainer.shared
    @StateObject private var parentModeManager = ParentModeManager.shared
    
    @State private var selectedTimeframe: AnalyticsTimeframe = .week
    @State private var selectedPlaylist: Playlist?
    
    enum AnalyticsTimeframe: String, CaseIterable {
        case week = "This Week"
        case month = "This Month"
        case allTime = "All Time"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .colorScheme(.dark)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Timeframe selector
                        timeframeSelectorSection
                        
                        // Summary cards
                        summaryCardsSection
                        
                        // Most played content
                        mostPlayedSection
                        
                        // Playlist breakdown
                        playlistBreakdownSection
                        
                        // Usage patterns
                        usagePatternsSection
                        
                        // Detailed playlist analytics
                        if let selectedPlaylist = selectedPlaylist {
                            detailedPlaylistSection(selectedPlaylist)
                        }
                    }
                    .padding()
                }
            }
        }
        .colorScheme(.dark)
        .navigationTitle("Usage Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .foregroundColor(.blue)
            }
        }
        .onTapGesture {
            parentModeManager.resetInactivityTimer()
        }
    }
    
    // MARK: - Timeframe Selector
    private var timeframeSelectorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time Period")
                .font(.headline)
                .foregroundColor(.white)
            
            Picker("Timeframe", selection: $selectedTimeframe) {
                ForEach(AnalyticsTimeframe.allCases, id: \.self) { timeframe in
                    Text(timeframe.rawValue).tag(timeframe)
                }
            }
            .pickerStyle(.segmented)
            .background(.gray.opacity(0.3))
            .cornerRadius(8)
            .onChange(of: selectedTimeframe) { _, _ in
                parentModeManager.resetInactivityTimer()
            }
        }
    }
    
    // MARK: - Summary Cards
    private var summaryCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                AnalyticsCard(
                    title: "Total Plays",
                    value: "\(totalPlaysCount)",
                    subtitle: "All songs",
                    icon: "play.circle.fill",
                    color: .blue
                )
                
                AnalyticsCard(
                    title: "Active Playlists",
                    value: "\(activePlaylists.count)",
                    subtitle: "With plays",
                    icon: "music.note.list",
                    color: .green
                )
                
                AnalyticsCard(
                    title: "Favorite Song",
                    value: mostPlayedSong?.title ?? "None",
                    subtitle: "\(mostPlayedSong?.playCount ?? 0) plays",
                    icon: "heart.fill",
                    color: .red,
                    isCompact: true
                )
                
                AnalyticsCard(
                    title: "Total Songs",
                    value: "\(totalSongsCount)",
                    subtitle: "In library",
                    icon: "music.note",
                    color: .purple
                )
            }
        }
    }
    
    // MARK: - Most Played
    private var mostPlayedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Most Played")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                // Most played songs
                VStack(alignment: .leading, spacing: 8) {
                    Text("Songs")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    ForEach(Array(topSongs.enumerated()), id: \.element.id) { index, song in
                        HStack {
                            Text("\(index + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(song.title)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                Text("\(song.playCount) plays")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            
                            Spacer()
                            
                            // Play frequency indicator
                            PlayFrequencyIndicator(playCount: song.playCount, maxPlays: topSongs.first?.playCount ?? 1)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Divider()
                    .background(.gray)
                
                // Most played playlists
                VStack(alignment: .leading, spacing: 8) {
                    Text("Playlists")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    ForEach(Array(topPlaylists.enumerated()), id: \.element.id) { index, playlist in
                        HStack {
                            Text("\(index + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(playlist.name)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                Text("\(playlistPlayCount(playlist)) total plays")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            
                            Spacer()
                            
                            Button("Details") {
                                selectedPlaylist = playlist
                                parentModeManager.resetInactivityTimer()
                            }
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.blue)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding()
        .background(.gray.opacity(0.2))
        .cornerRadius(12)
    }
    
    // MARK: - Playlist Breakdown
    private var playlistBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Playlist Usage")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(container.playlists) { playlist in
                PlaylistUsageRow(
                    playlist: playlist,
                    totalPlays: playlistPlayCount(playlist),
                    maxPlays: maxPlaylistPlays
                ) {
                    selectedPlaylist = playlist
                    parentModeManager.resetInactivityTimer()
                }
            }
        }
        .padding()
        .background(.gray.opacity(0.2))
        .cornerRadius(12)
    }
    
    // MARK: - Usage Patterns
    private var usagePatternsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                InsightRow(
                    icon: "clock",
                    title: "Peak Usage",
                    description: "Most activity happens \(peakUsageTime)",
                    color: .orange
                )
                
                InsightRow(
                    icon: "repeat",
                    title: "Listening Habits",
                    description: averageListeningHabit,
                    color: .blue
                )
                
                InsightRow(
                    icon: "heart",
                    title: "Favorites",
                    description: "Child prefers \(preferredGenre) style music",
                    color: .pink
                )
            }
        }
        .padding()
        .background(.gray.opacity(0.2))
        .cornerRadius(12)
    }
    
    // MARK: - Detailed Playlist Section
    private func detailedPlaylistSection(_ playlist: Playlist) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Playlist Details: \(playlist.name)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Close") {
                    selectedPlaylist = nil
                }
                .font(.caption)
                .foregroundColor(.red)
            }
            
            VStack(spacing: 12) {
                // Playlist stats
                HStack {
                    StatPill(label: "Songs", value: "\(playlist.songs.count)")
                    StatPill(label: "Total Plays", value: "\(playlistPlayCount(playlist))")
                    StatPill(label: "Avg per Song", value: String(format: "%.1f", averagePlaysPerSong(playlist)))
                }
                
                // Individual song performance
                Text("Song Performance")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ForEach(playlist.songs.sorted { $0.playCount > $1.playCount }) { song in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(song.title)
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            if let lastPlayed = song.lastPlayedDate {
                                Text("Last: \(formatRelativeDate(lastPlayed))")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                        
                        Text("\(song.playCount)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(.black.opacity(0.3))
                    .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(.blue.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.blue, lineWidth: 1)
        )
    }
    
    // MARK: - Computed Properties
    private var totalPlaysCount: Int {
        container.playlists.flatMap { $0.songs }.reduce(0) { $0 + $1.playCount }
    }
    
    private var totalSongsCount: Int {
        container.playlists.flatMap { $0.songs }.count
    }
    
    private var activePlaylists: [Playlist] {
        container.playlists.filter { playlistPlayCount($0) > 0 }
    }
    
    private var mostPlayedSong: MusicItem? {
        container.playlists.flatMap { $0.songs }.max { $0.playCount < $1.playCount }
    }
    
    private var topSongs: [MusicItem] {
        container.playlists
            .flatMap { $0.songs }
            .sorted { $0.playCount > $1.playCount }
            .prefix(5)
            .map { $0 }
    }
    
    private var topPlaylists: [Playlist] {
        container.playlists
            .sorted { playlistPlayCount($0) > playlistPlayCount($1) }
            .prefix(3)
            .map { $0 }
    }
    
    private var maxPlaylistPlays: Int {
        container.playlists.map { playlistPlayCount($0) }.max() ?? 1
    }
    
    private var peakUsageTime: String {
        // Simplified - in real app, analyze play times
        "in the afternoon"
    }
    
    private var averageListeningHabit: String {
        let avgPlays = Double(totalPlaysCount) / Double(totalSongsCount)
        if avgPlays > 3 {
            return "Loves to repeat favorite songs"
        } else if avgPlays > 1 {
            return "Enjoys variety in music"
        } else {
            return "Exploring new music"
        }
    }
    
    private var preferredGenre: String {
        // Simplified - analyze playlist names/concepts
        "playful and energetic"
    }
    
    // MARK: - Helper Methods
    private func playlistPlayCount(_ playlist: Playlist) -> Int {
        playlist.songs.reduce(0) { $0 + $1.playCount }
    }
    
    private func averagePlaysPerSong(_ playlist: Playlist) -> Double {
        guard !playlist.songs.isEmpty else { return 0 }
        return Double(playlistPlayCount(playlist)) / Double(playlist.songs.count)
    }
    
    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Supporting Components
struct AnalyticsCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    var isCompact: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                if !isCompact {
                    Spacer()
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(isCompact ? .headline : .title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(.black.opacity(0.3))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct PlayFrequencyIndicator: View {
    let playCount: Int
    let maxPlays: Int
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(index < normalizedBars ? .blue : .gray.opacity(0.3))
                    .frame(width: 3, height: 12)
            }
        }
    }
    
    private var normalizedBars: Int {
        guard maxPlays > 0 else { return 0 }
        return Int(ceil(Double(playCount) / Double(maxPlays) * 5))
    }
}

struct PlaylistUsageRow: View {
    let playlist: Playlist
    let totalPlays: Int
    let maxPlays: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(playlist.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("\(playlist.songs.count) songs • \(totalPlays) plays")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Usage bar
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(totalPlays)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(.gray.opacity(0.3))
                                .frame(height: 4)
                            
                            Rectangle()
                                .fill(.blue)
                                .frame(width: geometry.size.width * progressPercentage, height: 4)
                        }
                    }
                    .frame(width: 40, height: 4)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private var progressPercentage: CGFloat {
        guard maxPlays > 0 else { return 0 }
        return CGFloat(totalPlays) / CGFloat(maxPlays)
    }
}

struct InsightRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct StatPill: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.black.opacity(0.3))
        .cornerRadius(8)
    }
}

#Preview {
    ParentAnalyticsView()
        .colorScheme(.dark)
}