//
//  ARColors.swift
//  ARCodeClone
//
//  Palette de couleurs du design system AR Code
//

import SwiftUI

/// Palette de couleurs principale AR Code
struct ARColors {
    // MARK: - Primary Colors
    
    /// Primary: #6C5CE7 (Violet principal)
    static let primary = Color(hex: 0x6C5CE7)
    
    /// Primary Dark: Version sombre du primary
    static let primaryDark = Color(hex: 0x5A4BC7)
    
    /// Primary Light: Version claire du primary
    static let primaryLight = Color(hex: 0x8B7FF0)
    
    // MARK: - Secondary Colors
    
    /// Secondary: #00B894 (Turquoise/vert)
    static let secondary = Color(hex: 0x00B894)
    
    /// Secondary Dark: Version sombre du secondary
    static let secondaryDark = Color(hex: 0x009A7A)
    
    /// Secondary Light: Version claire du secondary
    static let secondaryLight = Color(hex: 0x00D4B0)
    
    // MARK: - Accent Colors
    
    /// Accent: #FD79A8 (Rose)
    static let accent = Color(hex: 0xFD79A8)
    
    /// Success: #00B894 (vert de succès)
    static let success = Color(hex: 0x00B894)
    
    /// Warning: #FDCB6E (jaune/orange)
    static let warning = Color(hex: 0xFDCB6E)
    
    /// Error: #E17055 (rouge/orange)
    static let error = Color(hex: 0xE17055)
    
    /// Info: #74B9FF (bleu)
    static let info = Color(hex: 0x74B9FF)
    
    // MARK: - Neutral Colors
    
    /// Background: Fond principal
    static let background = Color(hex: 0xFFFFFF)
    
    /// Background Dark: Fond sombre (pour dark mode)
    static let backgroundDark = Color(hex: 0x1A1A1A)
    
    /// Surface: Surface de carte/panneau
    static let surface = Color(hex: 0xFFFFFF)
    
    /// Surface Dark: Surface sombre
    static let surfaceDark = Color(hex: 0x2D2D2D)
    
    /// Text Primary: Texte principal
    static let textPrimary = Color(hex: 0x2D3436)
    
    /// Text Secondary: Texte secondaire
    static let textSecondary = Color(hex: 0x636E72)
    
    /// Text Disabled: Texte désactivé
    static let textDisabled = Color(hex: 0xB2BEC3)
    
    /// Border: Bordure
    static let border = Color(hex: 0xDFE6E9)
    
    /// Divider: Séparateur
    static let divider = Color(hex: 0xE0E0E0)
    
    // MARK: - Gradient Colors
    
    /// Primary Gradient
    static let primaryGradient = LinearGradient(
        colors: [primary, primaryLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Secondary Gradient
    static let secondaryGradient = LinearGradient(
        colors: [secondary, secondaryLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Accent Gradient
    static let accentGradient = LinearGradient(
        colors: [accent, Color(hex: 0xFF9FCC)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Color Extension

extension Color {
    /// Initialiseur depuis hex
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 08) & 0xFF) / 255,
            blue: Double((hex >> 00) & 0xFF) / 255,
            opacity: alpha
        )
    }
    
    /// Hex string
    var hexString: String {
        let components = UIColor(self).cgColor.components
        let r: CGFloat = components?[0] ?? 0.0
        let g: CGFloat = components?[1] ?? 0.0
        let b: CGFloat = components?[2] ?? 0.0
        
        return String(format: "#%02lX%02lX%02lX",
                     lroundf(Float(r * 255)),
                     lroundf(Float(g * 255)),
                     lroundf(Float(b * 255)))
    }
}









