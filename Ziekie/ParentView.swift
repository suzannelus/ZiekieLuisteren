//
//  ParentView.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 03/02/2025.
//

import SwiftUI

struct ParentView: View {
    
    @State var digit = 0
    
    var body: some View {
        VStack {
            Button("1") {
                digit += 1
            }
            .padding()
            
            
        }
    }
}

#Preview {
    ParentView()
}
