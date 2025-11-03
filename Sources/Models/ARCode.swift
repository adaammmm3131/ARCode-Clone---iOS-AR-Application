//
//  ARCode.swift
//  ARCodeClone
//
//  Modèle AR Code
//

import Foundation

struct ARCode: Codable, Identifiable {
    let id: String
    var title: String
    var description: String?
    var type: ARCodeType
    var qrCodeURL: String
    var assetURL: String?
    var thumbnailURL: String?
    var createdAt: Date
    var updatedAt: Date
    var userId: String
    var isPublic: Bool
    var metadata: ARCodeMetadata
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case type
        case qrCodeURL = "qr_code_url"
        case assetURL = "asset_url"
        case thumbnailURL = "thumbnail_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case userId = "user_id"
        case isPublic = "is_public"
        case metadata
    }
}

enum ARCodeType: String, Codable {
    case objectCapture = "object_capture"
    case faceFilter = "face_filter"
    case aiCode = "ai_code"
    case video = "video"
    case portal = "portal"
    case text = "text"
    case photo = "photo"
    case logo = "logo"
    case splat = "splat"
    case data = "data"
}

struct ARCodeMetadata: Codable {
    var format: String? // "GLB", "USDZ", "MP4", etc.
    var size: Int? // bytes
    var dimensions: Dimensions3D?
    var processingStatus: String? // "pending", "processing", "completed", "failed"
    var processingProgress: Double? // 0.0 - 1.0
}

struct Dimensions3D: Codable {
    var width: Float
    var height: Float
    var depth: Float
}













