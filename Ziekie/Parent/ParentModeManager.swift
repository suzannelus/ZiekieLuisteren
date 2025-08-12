//
//  ParentModeManager.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 15/07/2025.
//

import SwiftUI
import Combine

// MARK: - Parent Mode Manager
@MainActor
class ParentModeManager: ObservableObject {
    static let shared = ParentModeManager()
    
    @Published var isParentModeActive = false
    @Published var timeRemaining: TimeInterval = 120 // 2 minutes
    @Published var isTimerPaused = false // ✅ NEW: Track paused state
    
    private var inactivityTimer: Timer?
    private var backgroundObserver: AnyCancellable?
    private var foregroundObserver: AnyCancellable?
    
    private init() {
        setupBackgroundObservers()
    }
    
    func enterParentMode() {
        isParentModeActive = true
        isTimerPaused = false
        timeRemaining = 120  // ✅ CRITICAL: Reset timer to 2 minutes
        startInactivityTimer()
        print("🔒 Parent mode activated with \(timeRemaining) seconds")
    }
    
    func exitParentMode() {
        print("👶 Exiting parent mode... (timeRemaining was: \(Int(timeRemaining)))")
        isParentModeActive = false
        isTimerPaused = false
        stopInactivityTimer()
        print("👶 Child mode activated")
    }
        
    func resetInactivityTimer() {
        print("⏰ Resetting inactivity timer to 120 seconds")
        timeRemaining = 120
        isTimerPaused = false
        stopInactivityTimer()
        if isParentModeActive {
            startInactivityTimer()
        }
    }
    
    // ✅ NEW: Pause the timer (e.g., when ImagePlayground opens)
    func pauseTimer() {
        guard isParentModeActive && !isTimerPaused else { return }
        
        print("⏸️ Pausing parent mode timer at \(Int(timeRemaining)) seconds")
        isTimerPaused = true
        stopInactivityTimer()
    }
    
    // ✅ NEW: Resume the timer (e.g., when ImagePlayground closes)
    func resumeTimer() {
        guard isParentModeActive && isTimerPaused else { return }
        
        print("▶️ Resuming parent mode timer with \(Int(timeRemaining)) seconds remaining")
        isTimerPaused = false
        startInactivityTimer()
    }
    
    private func startInactivityTimer() {
        guard !isTimerPaused else {
            print("⏰ Timer start requested but currently paused")
            return
        }
        
        // ✅ SAFETY: Stop any existing timer before starting new one
        stopInactivityTimer()
        
        print("⏰ Starting inactivity timer with \(Int(timeRemaining)) seconds remaining")
        
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, !self.isTimerPaused else { return }
            
            self.timeRemaining -= 1
            
            // Debug logging every 10 seconds
            if Int(self.timeRemaining) % 10 == 0 {
                print("⏰ Timer: \(Int(self.timeRemaining)) seconds remaining")
            }
            
            if self.timeRemaining <= 0 {
                print("⏰ Timer expired - exiting parent mode")
                self.exitParentMode()
            }
        }
    }
    
    private func stopInactivityTimer() {
        print("⏰ Stopping inactivity timer")
        inactivityTimer?.invalidate()
        inactivityTimer = nil
    }
    
    private func setupBackgroundObservers() {
        // Exit parent mode when device is locked/backgrounded
        backgroundObserver = NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                print("📱 App backgrounded - exiting parent mode")
                self?.exitParentMode()
            }
        
        // Resume timer when returning to foreground (if it was running before)
        foregroundObserver = NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                print("📱 App foregrounded")
                if self?.isParentModeActive == true && self?.isTimerPaused == false {
                    // Only reset timer if it wasn't paused
                    self?.resetInactivityTimer()
                }
            }
    }
}

// MARK: - Parent Playlist Manager View
struct ParentPlaylistManagerView: View {
    @StateObject private var parentModeManager = ParentModeManager.shared
    @StateObject private var container = PlaylistsContainer.shared
    @State private var showingCreatePlaylist = false
    @State private var showingAnalytics = false
    @State private var selectedPlaylists: Set<UUID> = []
    @State private var showingBatchActions = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dark theme background
                Color(.systemBackground)
                    .colorScheme(.dark)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with timer
                        parentModeHeader
                        
                        // Analytics Summary
                        analyticsSummaryCard
                                                
                        // default playlists
                        //PlaylistPreferenceSection()
                        
                        // Playlist Management
                        playlistManagementSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
        }
        .colorScheme(.dark)
        .navigationBarHidden(true)
        .sheet(isPresented: $showingCreatePlaylist) {
            PlaylistCreationSheet()
                .colorScheme(.dark)
        }
        .sheet(isPresented: $showingAnalytics) {
            ParentAnalyticsView()
                .colorScheme(.dark)
        }
        .onTapGesture {
            // Only reset timer if not paused
            if !parentModeManager.isTimerPaused {
                parentModeManager.resetInactivityTimer()
            }
        }
        .onAppear {
            parentModeManager.enterParentMode()
        }
    }
    
    // MARK: - Header
    private var parentModeHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Parent Mode")
                        .screenTitle()
                        .foregroundColor(.white)
                    
                    
                    Text("Playlist & Settings")
                        .caption()
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    // Exit button
                    Button("Exit to Child Mode") {
                        parentModeManager.exitParentMode()
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .glassEffect(.regular.tint( .pink).interactive())
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            
            Divider()
                .background(.gray)
        }
    }
    
    // MARK: - Analytics Summary
    private var analyticsSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Quick Stats")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("More Details") {
                    showingAnalytics = true
                    if !parentModeManager.isTimerPaused {
                        parentModeManager.resetInactivityTimer()
                    }
                }
                .font(.caption)
                .foregroundColor(.teal)
                 
            }
            
            HStack(spacing: 12) {
                StatCard(
                    title: "Playlists",
                    value: "\(container.playlists.count)",
                    icon: "music.note.list"
                )
                
                StatCard(
                    title: "Total Songs",
                    value: "\(totalSongsCount)",
                    icon: "music.note"
                )
                
                StatCard(
                    title: "Most Played",
                    value: mostPlayedSong?.title.prefix(10).appending("...") ?? "None",
                    icon: "play.circle"
                )
            }
        }
        .padding()
        .background(.teal.opacity(0.2))
        .cornerRadius(12)
    }
    
    // MARK: - Quick Actions
    private var quickActionsRow: some View {
        VStack(alignment: .leading, spacing: 12) {
           
            HStack(spacing: 12) {
                ActionButton(
                    title: "New Playlist",
                    icon: "plus.circle.fill",
                    color: .purple
                ) {
                    showingCreatePlaylist = true
                    if !parentModeManager.isTimerPaused {
                        parentModeManager.resetInactivityTimer()
                    }
                }
                
                
            }
        }
    }
    
    // MARK: - Playlist Management
    private var playlistManagementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Manage Playlists")
                .font(.headline)
                .foregroundColor(.white)
            // Quick Actions
            quickActionsRow
            
            HStack {
                               
                Spacer()
                if showingBatchActions {
                    Button("Cancel") {
                        showingBatchActions = false
                        selectedPlaylists.removeAll()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
            if container.playlists.isEmpty {
                EmptyPlaylistsView()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(container.playlists.reversed()) { playlist in
                        ParentPlaylistRow(
                            playlist: playlist,
                            isSelected: selectedPlaylists.contains(playlist.id),
                            showingBatchActions: showingBatchActions
                        ) { isSelected in
                            if isSelected {
                                selectedPlaylists.insert(playlist.id)
                            } else {
                                selectedPlaylists.remove(playlist.id)
                            }
                            if !parentModeManager.isTimerPaused {
                                parentModeManager.resetInactivityTimer()
                            }
                        }
                    }
                }
                
                if showingBatchActions && !selectedPlaylists.isEmpty {
                    batchActionsBar
                }
            }
        }
    }
    
    // MARK: - Batch Actions
    private var batchActionsBar: some View {
        HStack {
            Text("\(selectedPlaylists.count) selected")
                .font(.caption)
                .foregroundColor(.gray)
            
            Spacer()
            
            Button("Delete Selected") {
                deleteSelectedPlaylists()
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.red)
            .foregroundColor(.white)
            .cornerRadius(6)
        }
        .padding()
        .background(.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Helper Methods
    private var totalSongsCount: Int {
        container.playlists.reduce(0) { $0 + $1.songs.count }
    }
    
    private var mostPlayedSong: MusicItem? {
        container.playlists
            .flatMap { $0.songs }
            .max { $0.playCount < $1.playCount }
    }
    
    private func deleteSelectedPlaylists() {
        withAnimation {
            container.playlists.removeAll { selectedPlaylists.contains($0.id) }
        }
        selectedPlaylists.removeAll()
        showingBatchActions = false
        if !parentModeManager.isTimerPaused {
            parentModeManager.resetInactivityTimer()
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Supporting Views
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.teal)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.black.opacity(0.3))
        .cornerRadius(8)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.purple.opacity(0.2))
            .cornerRadius(12)
        }
    }
}

struct EmptyPlaylistsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Playlists Created")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Tap 'New Playlist' to create your first playlist")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(.purple.opacity(0.2))
        .cornerRadius(12)
    }
}

#Preview {
    ParentPlaylistManagerView()
}
