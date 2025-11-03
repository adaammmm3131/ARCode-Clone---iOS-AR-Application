//
//  ARButton.swift
//  ARCodeClone
//
//  Composant bouton réutilisable du design system
//

import SwiftUI

/// Style de bouton AR Code
enum ARButtonStyle {
    case primary
    case secondary
    case accent
    case outlined
    case text
    case destructive
}

/// Taille de bouton
enum ARButtonSize {
    case small
    case medium
    case large
    
    var padding: EdgeInsets {
        switch self {
        case .small:
            return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        case .medium:
            return EdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24)
        case .large:
            return EdgeInsets(top: 16, leading: 32, bottom: 16, trailing: 32)
        }
    }
    
    var fontSize: Font {
        switch self {
        case .small:
            return ARTypography.labelSmall
        case .medium:
            return ARTypography.labelMedium
        case .large:
            return ARTypography.labelLarge
        }
    }
}

/// Bouton réutilisable AR Code
struct ARButton: View {
    let title: String
    let style: ARButtonStyle
    let size: ARButtonSize
    let icon: String?
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    @State private var isPressed: Bool = false
    
    init(
        _ title: String,
        style: ARButtonStyle = .primary,
        size: ARButtonSize = .medium,
        icon: String? = nil,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.icon = icon
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            guard !isLoading && !isDisabled else { return }
            
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            
            action()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(size.fontSize)
                }
                
                Text(title)
                    .font(size.fontSize)
                    .fontWeight(.semibold)
            }
            .foregroundColor(foregroundColor)
            .padding(size.padding)
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(isDisabled ? 0.5 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled || isLoading)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isDisabled && !isLoading {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
    
    // MARK: - Style Properties
    
    private var foregroundColor: Color {
        switch style {
        case .primary, .accent, .destructive:
            return .white
        case .secondary:
            return ARColors.primary
        case .outlined, .text:
            return ARColors.primary
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return ARColors.primary
        case .secondary:
            return ARColors.secondary
        case .accent:
            return ARColors.accent
        case .outlined, .text:
            return Color.clear
        case .destructive:
            return ARColors.error
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .outlined:
            return ARColors.primary
        case .primary, .secondary, .accent, .text, .destructive:
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .outlined:
            return 1.5
        default:
            return 0
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        ARButton("Primary Button", style: .primary) {}
        ARButton("Secondary Button", style: .secondary) {}
        ARButton("Outlined Button", style: .outlined) {}
        ARButton("Loading Button", style: .primary, isLoading: true) {}
        ARButton("Disabled Button", style: .primary, isDisabled: true) {}
    }
    .padding()
}









