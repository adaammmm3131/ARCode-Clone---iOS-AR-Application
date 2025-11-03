//
//  SkeletonLoader.swift
//  ARCodeClone
//
//  Skeleton loading screens for better UX
//

import Foundation
import SwiftUI

struct SkeletonView: View {
    var width: CGFloat? = nil
    var height: CGFloat = 20
    var cornerRadius: CGFloat = 8
    
    @State private var isAnimating = false
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.gray.opacity(0.2),
                        Color.gray.opacity(0.4),
                        Color.gray.opacity(0.2)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .cornerRadius(cornerRadius)
            .shimmer(isAnimating: isAnimating)
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

struct ARCodeCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SkeletonView(width: nil, height: 200, cornerRadius: 12)
            
            SkeletonView(width: 150, height: 20)
            SkeletonView(width: 200, height: 16)
            SkeletonView(width: 100, height: 16)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ARCodeListSkeleton: View {
    var count: Int = 3
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<count, id: \.self) { _ in
                ARCodeCardSkeleton()
            }
        }
        .padding()
    }
}

// MARK: - Shimmer Effect

extension View {
    func shimmer(isAnimating: Bool) -> some View {
        self.modifier(ShimmerModifier(isAnimating: isAnimating))
    }
}

struct ShimmerModifier: ViewModifier {
    var isAnimating: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.white.opacity(0.3),
                            Color.clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: isAnimating ? geometry.size.width : -geometry.size.width)
                }
            )
            .clipped()
    }
}







