//
//  DetailView.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 14/02/2023.
//

import SwiftUI

struct DetailView: View {
    var body: some View {
        ScrollView {
            Text("12 transactions".uppercased())
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)
                .padding(20)
            Text("Entertainment")
                .font(.largeTitle.width(.expanded))
            ViewThatFits {
                HStack(alignment: .top, spacing: 20) {
                    VStack {
                        ChartView()
                        GridView()
                    }
                    VStack {
                        CardView()
                        GridView()
                    }
                    .frame(width: 400)
                }
                VStack {
                    ChartView()
                    CardView()
                    GridView()
                }
            }
        }
    }
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        DetailView()
    }
}
