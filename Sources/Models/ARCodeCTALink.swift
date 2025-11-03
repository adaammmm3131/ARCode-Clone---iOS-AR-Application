//
//  ARCodeCTALink.swift
//  ARCodeClone
//
//  Modèle pour CTA (Call to Action) links dans expérience AR
//

import Foundation

struct ARCodeCTALink: Codable, Identifiable {
    let id: String
    let arCodeId: String
    var buttonText: String
    var buttonStyle: CTAButtonStyle
    var destinationURL: String
    var destinationType: CTADestinationType
    var position: CTAPosition
    var isEnabled: Bool
    var analyticsId: String? // Pour A/B testing
    var variant: String? // Variant A/B (A, B, C, etc.)
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case arCodeId = "ar_code_id"
        case buttonText = "button_text"
        case buttonStyle = "button_style"
        case destinationURL = "destination_url"
        case destinationType = "destination_type"
        case position
        case isEnabled = "is_enabled"
        case analyticsId = "analytics_id"
        case variant
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum CTAButtonStyle: String, Codable, CaseIterable {
    case primary = "primary"      // Bouton principal avec couleur brand
    case secondary = "secondary"  // Bouton secondaire
    case outline = "outline"      // Bouton avec bordure
    case text = "text"            // Bouton texte simple
    case icon = "icon"            // Bouton avec icône uniquement
}

enum CTADestinationType: String, Codable {
    case productPage = "product_page"
    case landingPage = "landing_page"
    case appDownload = "app_download"
    case socialMedia = "social_media"
    case website = "website"
    case deepLink = "deep_link"
    case email = "email"
    case phone = "phone"
}

enum CTAPosition: String, Codable {
    case topLeft = "top_left"
    case topRight = "top_right"
    case topCenter = "top_center"
    case bottomLeft = "bottom_left"
    case bottomRight = "bottom_right"
    case bottomCenter = "bottom_center"
    case center = "center"
    case floating = "floating" // Flottant au-dessus du contenu AR
}

// MARK: - A/B Testing Variant

struct ABTestVariant: Codable {
    let variantId: String
    let variantName: String // "A", "B", "C", etc.
    let buttonText: String
    let buttonStyle: CTAButtonStyle
    let position: CTAPosition
    let weight: Int // Poids pour distribution (ex: 50 pour 50%)
    var conversions: Int
    var clicks: Int
    
    var conversionRate: Double {
        guard clicks > 0 else { return 0.0 }
        return Double(conversions) / Double(clicks) * 100.0
    }
}

struct ABTest: Codable {
    let id: String
    let arCodeId: String
    let name: String
    var isActive: Bool
    var variants: [ABTestVariant]
    var startDate: Date
    var endDate: Date?
    var winnerVariantId: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case arCodeId = "ar_code_id"
        case name
        case isActive = "is_active"
        case variants
        case startDate = "start_date"
        case endDate = "end_date"
        case winnerVariantId = "winner_variant_id"
    }
}







