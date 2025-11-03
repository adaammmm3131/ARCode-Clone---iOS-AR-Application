//
//  ARProgressBar.swift
//  ARCodeClone
//
//  Composant progress bar réutilisable du design system
//

import SwiftUI

/// Style de progress bar
enum ARProgressBarStyle {
    case linear
    case circular
}

/// Progress bar réutilisable AR Code
struct ARProgressBar: View {
    let progress: Double // 0.0 - 1.0
    let style: ARProgressBarStyle
    let showPercentage: Bool
    let color: Color
    let backgroundColor: Color
    let height: CGFloat
    
    @State private var animatedProgress: Double = 0.0
    
    init(
        progress: Double,
        style: ARProgressBarStyle = .linear,
        showPercentage: Bool = false,
        color: Color = ARColors.primary,
        backgroundColor: Color = ARColors.border,
        height: CGFloat = 8
    ) {
        self.progress = progress
        self.style = style
        self.showPercentage = showPercentage
        self.color = color
        self.backgroundColor = backgroundColor
        self.height = height
    }
    
    var body: some View {
        Group {
            switch style {
            case .linear:
                linearProgress
            case .circular:
                circularProgress
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { newValue in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animatedProgress = newValue
            }
        }
    }
    
    // MARK: - Linear Progress
    
    private var linearProgress: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(backgroundColor)
                        .frame(height: height)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * animatedProgress, height: height)
                }
            }
            .frame(height: height)
            
            // Percentage
            if showPercentage {
                Text("\(Int(animatedProgress * 100))%")
                    .font(ARTypography.labelSmall)
                    .foregroundColor(ARColors.textSecondary)
            }
        }
    }
    
    // MARK: - Circular Progress
    
    private var circularProgress: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(backgroundColor, lineWidth: height)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: [color, color.opacity(0.6)],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: height, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            // Percentage text
            if showPercentage {
                Text("\(Int(animatedProgress * 100))%")
                    .font(ARTypography.labelMedium)
                    .foregroundColor(ARColors.textPrimary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        ARProgressBar(progress: 0.65, showPercentage: true)
        
        ARProgressBar(
            progress: 0.45,
            style: .circular,
            showPercentage: true,
            height: 12
        )
        .frame(width: 100, height: 100)
    }
    .padding()
}









