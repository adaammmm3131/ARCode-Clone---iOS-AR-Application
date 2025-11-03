//
//  AnalyticsServiceProtocol.swift
//  ARCodeClone
//
//  Protocol pour le service analytics
//

import Foundation

/// Protocol pour les opérations analytics
protocol AnalyticsServiceProtocol {
    func trackEvent(_ event: AnalyticsEvent)
    func trackQRScan(codeId: String, metadata: [String: Any])
    func trackARPlacement(codeId: String, position: SIMD3<Float>)
    func trackInteraction(codeId: String, interactionType: String)
    func trackConversion(codeId: String, value: Double?)
}

/// Types d'événements analytics
struct AnalyticsEvent {
    let name: String
    let parameters: [String: Any]
    let timestamp: Date
}











