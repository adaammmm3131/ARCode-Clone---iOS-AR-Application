//
//  Workspace.swift
//  ARCodeClone
//
//  Modèle pour workspaces multi-utilisateurs
//

import Foundation

struct Workspace: Codable, Identifiable {
    let id: String
    var name: String
    var description: String?
    var ownerId: String
    var createdAt: Date
    var updatedAt: Date
    var settings: WorkspaceSettings
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case ownerId = "owner_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case settings
    }
}

struct WorkspaceSettings: Codable {
    var allowPublicSharing: Bool
    var requireApproval: Bool
    var maxMembers: Int?
    var customDomain: String?
    
    enum CodingKeys: String, CodingKey {
        case allowPublicSharing = "allow_public_sharing"
        case requireApproval = "require_approval"
        case maxMembers = "max_members"
        case customDomain = "custom_domain"
    }
}

struct WorkspaceMember: Codable, Identifiable {
    let id: String
    let workspaceId: String
    let userId: String
    var role: WorkspaceRole
    var joinedAt: Date
    var invitedBy: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case workspaceId = "workspace_id"
        case userId = "user_id"
        case role
        case joinedAt = "joined_at"
        case invitedBy = "invited_by"
    }
}

enum WorkspaceRole: String, Codable, CaseIterable {
    case owner = "owner"        // Propriétaire - contrôle total
    case admin = "admin"        // Administrateur - gestion workspace
    case editor = "editor"      // Éditeur - créer/modifier AR Codes
    case viewer = "viewer"      // Visualiseur - lecture seule
    
    var displayName: String {
        switch self {
        case .owner: return "Propriétaire"
        case .admin: return "Administrateur"
        case .editor: return "Éditeur"
        case .viewer: return "Visualiseur"
        }
    }
    
    var permissions: WorkspacePermissions {
        switch self {
        case .owner:
            return WorkspacePermissions(
                canManageWorkspace: true,
                canInviteMembers: true,
                canRemoveMembers: true,
                canCreateARCode: true,
                canEditARCode: true,
                canDeleteARCode: true,
                canViewAnalytics: true,
                canManageSettings: true
            )
        case .admin:
            return WorkspacePermissions(
                canManageWorkspace: true,
                canInviteMembers: true,
                canRemoveMembers: true,
                canCreateARCode: true,
                canEditARCode: true,
                canDeleteARCode: false,
                canViewAnalytics: true,
                canManageSettings: false
            )
        case .editor:
            return WorkspacePermissions(
                canManageWorkspace: false,
                canInviteMembers: false,
                canRemoveMembers: false,
                canCreateARCode: true,
                canEditARCode: true,
                canDeleteARCode: false,
                canViewAnalytics: true,
                canManageSettings: false
            )
        case .viewer:
            return WorkspacePermissions(
                canManageWorkspace: false,
                canInviteMembers: false,
                canRemoveMembers: false,
                canCreateARCode: false,
                canEditARCode: false,
                canDeleteARCode: false,
                canViewAnalytics: true,
                canManageSettings: false
            )
        }
    }
}

struct WorkspacePermissions: Codable {
    let canManageWorkspace: Bool
    let canInviteMembers: Bool
    let canRemoveMembers: Bool
    let canCreateARCode: Bool
    let canEditARCode: Bool
    let canDeleteARCode: Bool
    let canViewAnalytics: Bool
    let canManageSettings: Bool
}

struct WorkspaceComment: Codable, Identifiable {
    let id: String
    let workspaceId: String
    let arCodeId: String?
    let userId: String
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var isResolved: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case workspaceId = "workspace_id"
        case arCodeId = "ar_code_id"
        case userId = "user_id"
        case content
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isResolved = "is_resolved"
    }
}

struct ARCodeVersion: Codable, Identifiable {
    let id: String
    let arCodeId: String
    var versionNumber: Int
    var assetURL: String?
    var metadata: [String: Any]
    var createdBy: String
    var createdAt: Date
    var changelog: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case arCodeId = "ar_code_id"
        case versionNumber = "version_number"
        case assetURL = "asset_url"
        case metadata
        case createdBy = "created_by"
        case createdAt = "created_at"
        case changelog
    }
}







