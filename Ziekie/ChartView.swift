//
//  ChartView.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 14/02/2023.
//

import SwiftUI
import Charts

struct ChartView: View {
    var body: some View {
        Chart {
            ForEach(data) { item in
                LineMark(x: .value("Day", item.day), y: .value("Value", item.value), series: .value("Year", "2023"))
                    .cornerRadius(10)
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(by: .value("Year", "2023"))
                    .symbol(by: .value("Year", "2023"))
            }
            ForEach(data2) { item in
                LineMark(x: .value("Day", item.day), y: .value("Value", item.value), series: .value("Year", "2022"))
                    .cornerRadius(10)
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(by: .value("Year", "2022"))
                    .symbol(by: .value("Year", "2022"))
            }
        }
       // .foregroundStyle(.linearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom))
        .frame(height: 300)
        .padding(20)
    }
}

struct ChartView_Previews: PreviewProvider {
    static var previews: some View {
        ChartView()
    }
}


struct Value: Identifiable {
    var id = UUID()
    var day: String
    var value: Double
}

let data = [
Value(day: "Jun 1", value: 200),
Value(day: "Jun 2", value: 96),
Value(day: "Jun 3", value: 210),
Value(day: "Jun 4", value: 45),
Value(day: "Jun 5", value: 250)

]

let data2 = [
Value(day: "Jun 1", value: 240),
Value(day: "Jun 2", value: 104),
Value(day: "Jun 3", value: 220),
Value(day: "Jun 4", value: 60),
Value(day: "Jun 5", value: 160)

]
