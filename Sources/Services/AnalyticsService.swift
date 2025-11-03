//
//  AnalyticsService.swift
//  ARCodeClone
//
//  Service analytics complet avec Umami, location tracking, retargeting
//

import Foundation
import CoreLocation
import UIKit

final class AnalyticsService: AnalyticsServiceProtocol {
    private let networkService: NetworkServiceProtocol
    private let sessionId: String
    private var sessionStartTime: Date
    private let locationManager: CLLocationManager?
    private var lastKnownLocation: CLLocation?
    
    private let umamiWebsiteId: String
    private let apiBaseURL: String
    
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
        self.sessionId = UUID().uuidString
        self.sessionStartTime = Date()
        
        // Umami config (from Info.plist or env)
        self.umamiWebsiteId = Bundle.main.object(forInfoDictionaryKey: "UmamiWebsiteId") as? String ?? ""
        self.apiBaseURL = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String ?? "https://api.ar-code.com"
        
        // Location manager (optional)
        self.locationManager = CLLocationManager()
        self.locationManager?.desiredAccuracy = kCLLocationAccuracyKilometer
        self.locationManager?.requestWhenInUseAuthorization()
        self.locationManager?.startUpdatingLocation()
        
        // Track session start
        trackSessionStart()
    }
    
    // MARK: - Session Tracking
    
    private func trackSessionStart() {
        let event = AnalyticsEvent(
            name: "session_start",
            parameters: [
                "session_id": sessionId,
                "timestamp": ISO8601DateFormatter().string(from: sessionStartTime)
            ],
            timestamp: sessionStartTime
        )
        trackEvent(event)
    }
    
    // MARK: - Event Tracking
    
    func trackEvent(_ event: AnalyticsEvent) {
        // Track to backend API
        Task {
            await sendEventToBackend(event)
        }
        
        // Track to Umami (web-based)
        trackToUmami(event)
        
        // Track to retargeting pixels
        trackToRetargetingPixels(event)
    }
    
    func trackQRScan(codeId: String, metadata: [String: Any]) {
        var params: [String: Any] = [
            "code_id": codeId,
            "event_type": "qr_scan"
        ]
        params.merge(metadata) { (_, new) in new }
        
        let event = AnalyticsEvent(
            name: "qr_scan",
            parameters: params,
            timestamp: Date()
        )
        trackEvent(event)
    }
    
    func trackARPlacement(codeId: String, position: SIMD3<Float>) {
        let event = AnalyticsEvent(
            name: "placement",
            parameters: [
                "code_id": codeId,
                "event_type": "placement",
                "position_x": position.x,
                "position_y": position.y,
                "position_z": position.z
            ],
            timestamp: Date()
        )
        trackEvent(event)
    }
    
    func trackInteraction(codeId: String, interactionType: String) {
        let event = AnalyticsEvent(
            name: "interaction",
            parameters: [
                "code_id": codeId,
                "event_type": "interaction",
                "interaction_type": interactionType
            ],
            timestamp: Date()
        )
        trackEvent(event)
    }
    
    func trackConversion(codeId: String, value: Double?) {
        var params: [String: Any] = [
            "code_id": codeId,
            "event_type": "conversion"
        ]
        
        if let value = value {
            params["value"] = value
        }
        
        let event = AnalyticsEvent(
            name: "conversion",
            parameters: params,
            timestamp: Date()
        )
        trackEvent(event)
    }
    
    func trackScreenshot(codeId: String) {
        let event = AnalyticsEvent(
            name: "screenshot",
            parameters: [
                "code_id": codeId,
                "event_type": "screenshot"
            ],
            timestamp: Date()
        )
        trackEvent(event)
    }
    
    // MARK: - Backend API
    
    private func sendEventToBackend(_ event: AnalyticsEvent) async {
        do {
            let deviceInfo = getDeviceInfo()
            let location = await getLocation()
            
            let payload: [String: Any] = [
                "event_type": event.name,
                "ar_code_id": event.parameters["code_id"] as? String,
                "event_data": event.parameters,
                "device_type": "ios",
                "browser": nil,
                "session_id": sessionId,
                "location": location != nil ? [
                    "latitude": location!.coordinate.latitude,
                    "longitude": location!.coordinate.longitude
                ] : nil
            ]
            
            _ = try await networkService.request(
                .analyticsTrack,  // TODO: Add to APIEndpoint enum
                method: .post,
                parameters: payload,
                headers: nil
            )
        } catch {
            print("Error sending event to backend: \(error)")
        }
    }
    
    // MARK: - Umami Tracking
    
    private func trackToUmami(_ event: AnalyticsEvent) {
        guard !umamiWebsiteId.isEmpty else { return }
        
        let deviceInfo = getDeviceInfo()
        let url = "/ar/\(event.parameters["code_id"] as? String ?? "")"
        
        // Generate visitor ID
        let visitorId = generateVisitorId()
        
        // Prepare Umami payload
        let payload: [String: Any] = [
            "website": umamiWebsiteId,
            "hostname": "ar-code.com",
            "url": url,
            "referrer": "",
            "visitor_id": visitorId,
            "session_id": sessionId,
            "event_name": event.name,
            "event_data": event.parameters
        ]
        
        // Send to Umami (async)
        Task {
            do {
                var request = URLRequest(url: URL(string: "\(apiBaseURL)/analytics/umami")!)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONSerialization.data(withJSONObject: payload)
                
                let (_, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    print("Event tracked to Umami: \(event.name)")
                }
            } catch {
                print("Error tracking to Umami: \(error)")
            }
        }
    }
    
    // MARK: - Retargeting Pixels
    
    private func trackToRetargetingPixels(_ event: AnalyticsEvent) {
        // Only track conversions and important events
        guard event.name == "conversion" || event.name == "qr_scan" else { return }
        
        // Facebook Pixel
        trackFacebookPixel(event)
        
        // Google Ads Pixel
        trackGoogleAdsPixel(event)
        
        // LinkedIn Insight Tag
        trackLinkedInPixel(event)
        
        // Twitter Pixel
        trackTwitterPixel(event)
    }
    
    private func trackFacebookPixel(_ event: AnalyticsEvent) {
        // Facebook Pixel ID from Info.plist
        guard let pixelId = Bundle.main.object(forInfoDictionaryKey: "FacebookPixelId") as? String,
              !pixelId.isEmpty else { return }
        
        // In real implementation, use Facebook SDK or pixel code
        // For now, log or send to backend for server-side tracking
        print("Facebook Pixel: \(event.name) for pixel \(pixelId)")
    }
    
    private func trackGoogleAdsPixel(_ event: AnalyticsEvent) {
        guard let conversionId = Bundle.main.object(forInfoDictionaryKey: "GoogleAdsConversionId") as? String,
              !conversionId.isEmpty else { return }
        
        print("Google Ads Pixel: \(event.name) for conversion \(conversionId)")
    }
    
    private func trackLinkedInPixel(_ event: AnalyticsEvent) {
        guard let partnerId = Bundle.main.object(forInfoDictionaryKey: "LinkedInPartnerId") as? String,
              !partnerId.isEmpty else { return }
        
        print("LinkedIn Insight: \(event.name) for partner \(partnerId)")
    }
    
    private func trackTwitterPixel(_ event: AnalyticsEvent) {
        guard let pixelId = Bundle.main.object(forInfoDictionaryKey: "TwitterPixelId") as? String,
              !pixelId.isEmpty else { return }
        
        print("Twitter Pixel: \(event.name) for pixel \(pixelId)")
    }
    
    // MARK: - Helpers
    
    private func getDeviceInfo() -> [String: String] {
        let device = UIDevice.current
        return [
            "os": "iOS",
            "os_version": device.systemVersion,
            "model": device.model,
            "device_name": device.name
        ]
    }
    
    private func getLocation() async -> CLLocation? {
        guard let locationManager = locationManager else { return nil }
        
        return await withCheckedContinuation { continuation in
            if let location = locationManager.location {
                continuation.resume(returning: location)
            } else {
                continuation.resume(returning: nil)
            }
        }
    }
    
    private func generateVisitorId() -> String {
        // Generate consistent visitor ID (store in Keychain for persistence)
        let key = "umami_visitor_id"
        
        if let stored = KeychainService.load(key: key) {
            return stored
        }
        
        let visitorId = UUID().uuidString
        KeychainService.save(token: visitorId, key: key)
        return visitorId
    }
}

// MARK: - Keychain Helper

class KeychainService {
    static func save(token: String, key: String) {
        let data = token.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }
}









