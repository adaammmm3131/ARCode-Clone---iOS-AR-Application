//
//  ARSkeletonView.swift
//  ARCodeClone
//
//  Composant skeleton loader avec shimmer effect
//

import SwiftUI

/// Skeleton loader avec shimmer effect
struct ARSkeletonView: View {
    let shape: SkeletonShape
    let width: CGFloat?
    let height: CGFloat?
    
    @State private var shimmerOffset: CGFloat = -200
    
    init(
        shape: SkeletonShape = .rectangle,
        width: CGFloat? = nil,
        height: CGFloat? = nil
    ) {
        self.shape = shape
        self.width = width
        self.height = height
    }
    
    var body: some View {
        Group {
            switch shape {
            case .rectangle:
                Rectangle()
                    .fill(skeletonGradient)
                    .frame(width: width, height: height)
            case .circle:
                Circle()
                    .fill(skeletonGradient)
                    .frame(width: width ?? height ?? 50, height: height ?? width ?? 50)
            case .roundedRectangle(let cornerRadius):
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(skeletonGradient)
                    .frame(width: width, height: height)
            }
        }
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                shimmerOffset = 200
            }
        }
    }
    
    // MARK: - Shimmer Gradient
    
    private var skeletonGradient: LinearGradient {
        LinearGradient(
            colors: [
                ARColors.border.opacity(0.3),
                ARColors.border.opacity(0.5),
                ARColors.border.opacity(0.3)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .offset(x: shimmerOffset)
    }
}

enum SkeletonShape {
    case rectangle
    case circle
    case roundedRectangle(CGFloat)
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        ARSkeletonView(shape: .rectangle, width: 200, height: 20)
        ARSkeletonView(shape: .circle, width: 60, height: 60)
        ARSkeletonView(shape: .roundedRectangle(12), width: 150, height: 100)
    }
    .padding()
}









