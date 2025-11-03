//
//  User.swift
//  ARCodeClone
//
//  Modèle utilisateur
//

import Foundation

struct User: Codable, Identifiable {
    let id: String
    var email: String
    var name: String?
    var createdAt: Date
    var updatedAt: Date
    var preferences: UserPreferences
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case preferences
    }
}

struct UserPreferences: Codable {
    var theme: String // "light" | "dark" | "system"
    var language: String // ISO 639-1 code
    var notificationsEnabled: Bool
    var analyticsEnabled: Bool
}













