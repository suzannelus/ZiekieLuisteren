//
//  MessageView.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 14/02/2023.
//

import SwiftUI

struct MessageView: View {
    @State var time = 0.0
    @State var showMessage = true
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        content
            .opacity(showMessage ? 1 : 0)
            .scaleEffect(showMessage ? 1 : 0)
            .rotationEffect(.degrees(showMessage ? 0 : 30))
            .offset(y: showMessage ? 0 : 500)
            .blur(radius: showMessage ? 0 : 20)
    }
    
    var content: some View {
            VStack {
                Image(systemName: "waveform", variableValue: time)
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                    .font(.system(size: 100))
                    .onReceive(timer) { value in
                        if time < 1.0 {
                            time += 0.1
                        } else {
                            time = 0.0
                        }
                    }
                Text("Ziekie Luisteren".uppercased())
                    .font(.largeTitle.width(.condensed))
                    .fontWeight(.bold)
                
                Button {
                    withAnimation(.easeInOut) {
                        showMessage = false
                    }
                } label: {
                    Image(systemName: "play.square.fill")
                }
                .font(.largeTitle)
                .padding(.all)
                .frame(maxWidth: .infinity)
                .background(.white.opacity(0.2).gradient)
                .cornerRadius(10)
                .background(RoundedRectangle(cornerRadius: 10).stroke()
                    .foregroundStyle(.linearGradient(colors:[.white.opacity(0.5), .clear, .white.opacity(0.5), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
                )
            }
        .padding(30)
        .background(.ultraThinMaterial)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke()
            .foregroundStyle(.linearGradient(colors:[.white.opacity(0.5), .clear, .white.opacity(0.5), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .shadow(color: .black.opacity(0.3), radius: 20, y: 20)
        .frame(maxWidth: 500)
        .padding(10)
        .dynamicTypeSize(.xSmall ... .xxxLarge)
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        MessageView()
    }
}
