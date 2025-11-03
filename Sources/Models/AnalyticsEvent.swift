//
//  AnalyticsEvent.swift
//  ARCodeClone
//
//  Modèle événement analytics
//

import Foundation

struct AnalyticsEventModel: Codable {
    let id: String
    let codeId: String
    let eventType: EventType
    let timestamp: Date
    let location: Location?
    let device: DeviceInfo
    let metadata: [String: String]
    
    enum EventType: String, Codable {
        case qrScan = "qr_scan"
        case placement = "placement"
        case interaction = "interaction"
        case screenshot = "screenshot"
        case conversion = "conversion"
    }
}

struct Location: Codable {
    let latitude: Double
    let longitude: Double
    let city: String?
    let country: String?
}

struct DeviceInfo: Codable {
    let os: String
    let osVersion: String
    let model: String
    let browser: String?
}













