//
//  WhiteLabelSettings.swift
//  ARCodeClone
//
//  Modèle pour white label settings
//

import Foundation

struct WhiteLabelSettings: Codable {
    var customDomain: String? // ex: ar.votresite.com
    var logoURL: String? // URL du logo personnalisé
    var primaryColor: String? // Hex color
    var secondaryColor: String? // Hex color
    var accentColor: String? // Hex color
    var companyName: String?
    var supportEmail: String?
    var customLoadingScreenURL: String?
    var emailTemplatesCustom: Bool
    
    enum CodingKeys: String, CodingKey {
        case customDomain = "custom_domain"
        case logoURL = "logo_url"
        case primaryColor = "primary_color"
        case secondaryColor = "secondary_color"
        case accentColor = "accent_color"
        case companyName = "company_name"
        case supportEmail = "support_email"
        case customLoadingScreenURL = "custom_loading_screen_url"
        case emailTemplatesCustom = "email_templates_custom"
    }
}

struct WhiteLabelConfig: Codable {
    let id: String
    let userId: String // Workspace owner
    var settings: WhiteLabelSettings
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case settings
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}







