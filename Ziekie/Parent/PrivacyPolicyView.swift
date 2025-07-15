//
//  PrivacyPolicyView.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 06/07/2025.
//

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Policy")
                    .font(.largeTitle.bold())
                
                Text("Effective Date: [Current Date]")
                    .foregroundColor(.secondary)
                
                privacyContent
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var privacyContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            policySection(
                title: "Information We Collect",
                content: "Ziekie does not collect any personal information from users. All playlist data, listening data and generated images are stored locally on your device only."
            )
            
            policySection(
                title: "Children's Privacy",
                content: "This app is designed for children and complies with COPPA. We do not collect any personal information from children under 13. Parent verification is required for playlist creation features."
            )
            
            policySection(
                title: "Apple Music Integration", 
                content: "This app uses Apple's MusicKit to access your Apple Music library. We do not store or access your music data - all interactions go directly through Apple's secure systems."
            )
            
           
        }
    }
    
    private func policySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(content)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    PrivacyPolicyView()
}
