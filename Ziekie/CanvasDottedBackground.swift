struct CanvasDottedBackground: View {
    let dotSize: CGFloat = 8
    let spacing: CGFloat = 20
    let dotColor: Color = Color.gray.opacity(0.9)
    
    var body: some View {
        // Random gekleurde dots
        Canvas { context, size in
            let colors: [Color] = [.pink, .blue, .green, .yellow, .purple]
            let spacing: CGFloat = 25
            
            for row in 0..<Int(size.height / spacing) {
                for col in 0..<Int(size.width / spacing) {
                    let randomColor = colors.randomElement() ?? .gray
                    let x = CGFloat(col) * spacing
                    let y = CGFloat(row) * spacing
                    
                    context.fill(
                        Circle().path(in: CGRect(x: x-1, y: y-1, width: 2, height: 2)),
                        with: .color(randomColor.opacity(0.8))
                    )
                }
            }
        }
    }
}