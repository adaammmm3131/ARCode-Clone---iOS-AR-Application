//
//  ARSpinningLogo.swift
//  ARCodeClone
//
//  Logo AR Code avec animation 3D spinning
//

import SwiftUI

/// Logo AR Code avec animation rotation 3D
struct ARSpinningLogo: View {
    let size: CGFloat
    let animationSpeed: Double
    let autoSpin: Bool
    
    @State private var rotationAngle: Double = 0
    
    init(
        size: CGFloat = 100,
        animationSpeed: Double = 2.0,
        autoSpin: Bool = true
    ) {
        self.size = size
        self.animationSpeed = animationSpeed
        self.autoSpin = autoSpin
    }
    
    var body: some View {
        ZStack {
            // Logo placeholder - en production, utiliser vrai logo
            Circle()
                .fill(ARColors.primaryGradient)
                .frame(width: size, height: size)
            
            // Texte AR Code (temporaire jusqu'à logo réel)
            Text("AR")
                .font(.system(size: size * 0.3, weight: .bold))
                .foregroundColor(.white)
        }
        .rotation3DEffect(
            .degrees(rotationAngle),
            axis: (x: 0, y: 1, z: 0)
        )
        .onAppear {
            if autoSpin {
                startRotation()
            }
        }
    }
    
    private func startRotation() {
        withAnimation(
            Animation.linear(duration: animationSpeed)
                .repeatForever(autoreverses: false)
        ) {
            rotationAngle = 360
        }
    }
    
    /// Arrêter rotation
    func stopRotation() {
        withAnimation {
            rotationAngle = 0
        }
    }
    
    /// Reprendre rotation
    func resumeRotation() {
        startRotation()
    }
}

// MARK: - Preview

#Preview {
    ARSpinningLogo(size: 100)
        .padding()
}









