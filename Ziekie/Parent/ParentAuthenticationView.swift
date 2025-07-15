//
//  ParentAuthenticationView.swift
//  Ziekie
//
//  Created by Suzanne Lustenhouwer on 04/07/2025.
//
import SwiftUI

struct ParentAuthenticationView: View {
    let onAuthenticated: () -> Void
    
    @State private var answer = ""
    @State private var showError = false
    @State private var mathProblem = generateMathProblem()
    
    var body: some View {
        ZStack {
            CanvasDottedBackground()
                .ignoresSafeArea()
                
            VStack(spacing: 20) {
                Text("Parent Verification")
                    .screenTitle()
                    .foregroundColor(.primary)
                Spacer()
                
                Text("Solve this math problem to continue:")
                    .captionBold()
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                VStack {
                    Text(mathProblem.question)
                        .bodyLarge()
                    TextField("Your answer", text: $answer)
                        .bodyLarge()
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .frame(maxWidth: 150)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                }
                .multilineTextAlignment(.center)
                .padding()
                .background(.mint.opacity(0.3))
                .cornerRadius(12)
                Spacer()
                Button("Continue") {
                    if Int(answer) == mathProblem.answer {
                        onAuthenticated()
                    } else {
                        showError = true
                        // Generate new problem on wrong answer
                        mathProblem = ParentAuthenticationView.generateMathProblem()
                        answer = ""
                    }
                }
                
                .foregroundStyle(Color.white)
                .padding()
                .glassEffect(.regular.tint(.mint).interactive())
                .disabled(answer.isEmpty)
                
            }
            .padding()
            .alert("Incorrect Answer", isPresented: $showError) {
                Button("Try Again") { }
            } message: {
                Text("Please try the new problem.")
            }
        }
    }
    
    static func generateMathProblem() -> MathProblem {
        let problemType = Int.random(in: 1...4)
        
        switch problemType {
        case 1: // Addition with carrying
            let a = Int.random(in: 25...89)
            let b = Int.random(in: 15...67)
            return MathProblem(question: "\(a) + \(b) = ?", answer: a + b)
            
        case 2: // Subtraction with borrowing
            let larger = Int.random(in: 50...95)
            let smaller = Int.random(in: 18...47)
            return MathProblem(question: "\(larger) − \(smaller) = ?", answer: larger - smaller)
            
        case 3: // Multiplication (double digit × single digit)
            let a = Int.random(in: 12...25)
            let b = Int.random(in: 3...8)
            return MathProblem(question: "\(a) × \(b) = ?", answer: a * b)
            
        case 4: // Division (no remainders)
            let quotient = Int.random(in: 8...15)
            let divisor = Int.random(in: 3...9)
            let dividend = quotient * divisor
            return MathProblem(question: "\(dividend) ÷ \(divisor) = ?", answer: quotient)
            
        default:
            // Fallback
            let a = Int.random(in: 25...75)
            let b = Int.random(in: 15...45)
            return MathProblem(question: "\(a) + \(b) = ?", answer: a + b)
        }
    }
}

struct MathProblem {
    let question: String
    let answer: Int
}

#Preview {
    PreviewWrapper()
}

struct PreviewWrapper: View {
    @State private var isAuthenticated = false
    @State private var showAuth = true
    
    var body: some View {
        VStack {
            if isAuthenticated {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.mint)
                    
                    Text("Parent Authenticated!")
                        .captionBold()
                    
                    Button("Try Again") {
                        isAuthenticated = false
                        showAuth = true
                    }
                    .glassEffect(.regular.tint(.mint).interactive())
                }
                .padding()
            } else {
                Color.clear
            }
        }
        .sheet(isPresented: $showAuth) {
            ParentAuthenticationView {
                showAuth = false
                isAuthenticated = true
            }
        }
    }
}
