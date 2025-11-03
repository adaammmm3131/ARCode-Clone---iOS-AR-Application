//
//  QRCodeDeepLinkingService.swift
//  ARCodeClone
//
//  Service pour deep linking et redirection automatique
//

import Foundation
import UIKit

protocol QRCodeDeepLinkingServiceProtocol {
    func handleQRCodeURL(_ url: String) -> DeepLinkResult
    func openInApp(url: String) -> Bool
    func openInBrowser(url: String)
    func canHandleURL(_ url: String) -> Bool
}

struct DeepLinkResult {
    let arCodeId: String?
    let contentType: String?
    let assetId: String?
    let params: [String: Any]
    let shouldOpenInApp: Bool
    let shouldOpenAR: Bool
}

enum DeepLinkingError: LocalizedError {
    case invalidURL
    case unsupportedScheme
    case parsingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalide"
        case .unsupportedScheme:
            return "Schéma URL non supporté"
        case .parsingFailed:
            return "Échec parsing URL"
        }
    }
}

final class QRCodeDeepLinkingService: QRCodeDeepLinkingServiceProtocol {
    private let urlService: QRCodeURLServiceProtocol
    private let appScheme: String
    
    init(
        urlService: QRCodeURLServiceProtocol,
        appScheme: String = "ar-code"
    ) {
        self.urlService = urlService
        self.appScheme = appScheme
    }
    
    // MARK: - URL Handling
    
    func handleQRCodeURL(_ url: String) -> DeepLinkResult {
        // Vérifier si URL est de notre domaine
        if url.contains("ar-code.com") || url.contains("/a/") {
            // Parser metadata depuis URL
            if let metadata = urlService.parseShortURL(url: url) {
                return DeepLinkResult(
                    arCodeId: metadata.arCodeId,
                    contentType: metadata.contentType,
                    assetId: metadata.assetId,
                    params: metadata.params,
                    shouldOpenInApp: true,
                    shouldOpenAR: true
                )
            }
        }
        
        // URL externe - ouvrir dans browser
        return DeepLinkResult(
            arCodeId: nil,
            contentType: nil,
            assetId: nil,
            params: [:],
            shouldOpenInApp: false,
            shouldOpenAR: false
        )
    }
    
    func openInApp(url: String) -> Bool {
        guard let urlComponents = URLComponents(string: url) else {
            return false
        }
        
        // Vérifier si URL peut être ouverte dans l'app
        guard canHandleURL(url) else {
            return false
        }
        
        // Créer URL avec app scheme
        var appURLComponents = urlComponents
        appURLComponents.scheme = appScheme
        
        guard let appURL = appURLComponents.url else {
            return false
        }
        
        // Ouvrir dans app
        if UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL, options: [:], completionHandler: nil)
            return true
        }
        
        return false
    }
    
    func openInBrowser(url: String) {
        guard let urlObject = URL(string: url) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(urlObject) {
            UIApplication.shared.open(urlObject, options: [:], completionHandler: nil)
        }
    }
    
    func canHandleURL(_ url: String) -> Bool {
        // Vérifier si URL est de notre domaine ou utilise notre scheme
        return url.contains("ar-code.com") ||
               url.contains("ar-code://") ||
               url.hasPrefix(appScheme + "://")
    }
}









