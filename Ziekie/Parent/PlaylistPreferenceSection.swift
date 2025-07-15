//
//  PlaylistPreferenceSection 2.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 18/07/2025.
//


import SwiftUI

// MARK: - Simple Playlist Preference Section
struct PlaylistPreferenceSection: View {
    @StateObject private var preferenceManager = PlaylistPreferenceManager.shared
    @StateObject private var parentModeManager = ParentModeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Music Selection")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                PreferenceRow(
                    title: "Interface Language",
                    description: "Songs match phone language",
                    icon: "globe",
                    isSelected: preferenceManager.loadingPreference == .language
                ) {
                    preferenceManager.loadingPreference = .language
                    parentModeManager.resetInactivityTimer()
                }
                
                PreferenceRow(
                    title: "Local Culture", 
                    description: "Songs match current location",
                    icon: "location",
                    isSelected: preferenceManager.loadingPreference == .region
                ) {
                    preferenceManager.loadingPreference = .region
                    parentModeManager.resetInactivityTimer()
                }
            }
        }
        .padding()
        .background(.gray.opacity(0.2))
        .cornerRadius(12)
    }
}

// MARK: - Simple Preference Row
struct PreferenceRow: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .mint : .gray)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .mint : .gray)
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
            .padding()
            .background(isSelected ? .mint.opacity(0.1) : .clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}