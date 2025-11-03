//
//  ARTypography.swift
//  ARCodeClone
//
//  Système typographique avec Inter font
//

import SwiftUI

/// Système typographique AR Code
struct ARTypography {
    // MARK: - Font Families
    
    /// Inter Bold
    static let bold = Font.custom("Inter-Bold", size: 16)
    
    /// Inter Regular
    static let regular = Font.custom("Inter-Regular", size: 16)
    
    /// Inter Medium
    static let medium = Font.custom("Inter-Medium", size: 16)
    
    /// Inter SemiBold
    static let semiBold = Font.custom("Inter-SemiBold", size: 16)
    
    // MARK: - Display Styles
    
    /// Display Large (H1)
    static let displayLarge = Font.custom("Inter-Bold", size: 57)
    
    /// Display Medium (H2)
    static let displayMedium = Font.custom("Inter-Bold", size: 45)
    
    /// Display Small (H3)
    static let displaySmall = Font.custom("Inter-Bold", size: 36)
    
    // MARK: - Headline Styles
    
    /// Headline Large (H4)
    static let headlineLarge = Font.custom("Inter-SemiBold", size: 32)
    
    /// Headline Medium (H5)
    static let headlineMedium = Font.custom("Inter-SemiBold", size: 28)
    
    /// Headline Small (H6)
    static let headlineSmall = Font.custom("Inter-SemiBold", size: 24)
    
    // MARK: - Title Styles
    
    /// Title Large
    static let titleLarge = Font.custom("Inter-SemiBold", size: 22)
    
    /// Title Medium
    static let titleMedium = Font.custom("Inter-Medium", size: 16)
    
    /// Title Small
    static let titleSmall = Font.custom("Inter-Medium", size: 14)
    
    // MARK: - Body Styles
    
    /// Body Large
    static let bodyLarge = Font.custom("Inter-Regular", size: 16)
    
    /// Body Medium (default)
    static let bodyMedium = Font.custom("Inter-Regular", size: 14)
    
    /// Body Small
    static let bodySmall = Font.custom("Inter-Regular", size: 12)
    
    // MARK: - Label Styles
    
    /// Label Large
    static let labelLarge = Font.custom("Inter-Medium", size: 14)
    
    /// Label Medium
    static let labelMedium = Font.custom("Inter-Medium", size: 12)
    
    /// Label Small
    static let labelSmall = Font.custom("Inter-Medium", size: 11)
}

// MARK: - Text Style Extension

extension Text {
    /// Applique un style typographique
    func arStyle(_ style: Font, color: Color = ARColors.textPrimary) -> some View {
        self
            .font(style)
            .foregroundColor(color)
    }
}









