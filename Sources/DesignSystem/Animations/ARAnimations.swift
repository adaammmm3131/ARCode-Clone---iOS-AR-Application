//
//  ARAnimations.swift
//  ARCodeClone
//
//  Animations réutilisables du design system
//

import SwiftUI

/// Animations standards AR Code
struct ARAnimations {
    // MARK: - Spring Animations
    
    /// Spring animation standard (0.3s duration)
    static let spring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    
    /// Spring animation rapide
    static let springFast = Animation.spring(response: 0.2, dampingFraction: 0.8)
    
    /// Spring animation lente
    static let springSlow = Animation.spring(response: 0.5, dampingFraction: 0.6)
    
    // MARK: - Page Transitions
    
    /// Transition slide horizontale
    static let slideHorizontal = AnyTransition.asymmetric(
        insertion: .move(edge: .trailing).combined(with: .opacity),
        removal: .move(edge: .leading).combined(with: .opacity)
    )
    
    /// Transition slide verticale
    static let slideVertical = AnyTransition.asymmetric(
        insertion: .move(edge: .bottom).combined(with: .opacity),
        removal: .move(edge: .top).combined(with: .opacity)
    )
    
    // MARK: - Modal Transitions
    
    /// Transition modal (scale + fade)
    static let modal = AnyTransition.scale(scale: 0.8).combined(with: .opacity)
    
    /// Transition modal avec spring
    static func modalSpring(scale: CGFloat = 0.8) -> AnyTransition {
        AnyTransition.scale(scale: scale).combined(with: .opacity)
    }
    
    // MARK: - Card Animations
    
    /// Animation hover lift pour cartes
    static let cardHover = Animation.spring(response: 0.3, dampingFraction: 0.7)
    
    // MARK: - Button Animations
    
    /// Animation ripple effect pour boutons
    static let buttonRipple = Animation.easeOut(duration: 0.3)
}

// MARK: - View Modifiers

extension View {
    /// Applique une transition slide horizontale
    func slideHorizontalTransition() -> some View {
        self.transition(ARAnimations.slideHorizontal)
    }
    
    /// Applique une transition modal
    func modalTransition() -> some View {
        self.transition(ARAnimations.modal)
    }
}









