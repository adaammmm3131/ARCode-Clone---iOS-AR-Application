//
//  ARCard.swift
//  ARCodeClone
//
//  Composant carte réutilisable du design system
//

import SwiftUI

/// Carte réutilisable AR Code
struct ARCard<Content: View>: View {
    let content: Content
    let shadowEnabled: Bool
    let cornerRadius: CGFloat
    let padding: EdgeInsets
    
    @State private var isHovered: Bool = false
    
    init(
        shadowEnabled: Bool = true,
        cornerRadius: CGFloat = 16,
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.shadowEnabled = shadowEnabled
        self.cornerRadius = cornerRadius
        self.padding = padding
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(ARColors.surface)
            .cornerRadius(cornerRadius)
            .shadow(
                color: shadowEnabled ? Color.black.opacity(isHovered ? 0.2 : 0.1) : .clear,
                radius: isHovered ? 12 : 8,
                x: 0,
                y: isHovered ? 4 : 2
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - Preview

#Preview {
    ARCard {
        VStack(alignment: .leading, spacing: 12) {
            Text("Card Title")
                .font(ARTypography.titleLarge)
                .foregroundColor(ARColors.textPrimary)
            
            Text("Card content goes here")
                .font(ARTypography.bodyMedium)
                .foregroundColor(ARColors.textSecondary)
        }
    }
    .padding()
}









