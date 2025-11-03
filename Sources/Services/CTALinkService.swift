//
//  CTALinkService.swift
//  ARCodeClone
//
//  Service pour gestion des CTA links dans AR
//

import Foundation
import UIKit

protocol CTALinkServiceProtocol {
    func getCTALinks(for arCodeId: String, completion: @escaping (Result<[ARCodeCTALink], Error>) -> Void)
    func createCTALink(_ link: ARCodeCTALink, completion: @escaping (Result<ARCodeCTALink, Error>) -> Void)
    func updateCTALink(_ link: ARCodeCTALink, completion: @escaping (Result<ARCodeCTALink, Error>) -> Void)
    func deleteCTALink(id: String, completion: @escaping (Result<Void, Error>) -> Void)
    func trackCTAClick(linkId: String, variant: String?, completion: @escaping (Result<Void, Error>) -> Void)
    func handleCTARedirection(url: String, destinationType: CTADestinationType) -> Bool
}

enum CTALinkError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidDestinationType
    case redirectionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalide"
        case .networkError(let error):
            return "Erreur réseau: \(error.localizedDescription)"
        case .invalidDestinationType:
            return "Type de destination invalide"
        case .redirectionFailed:
            return "Échec de la redirection"
        }
    }
}

final class CTALinkService: CTALinkServiceProtocol {
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    // MARK: - CRUD Operations
    
    func getCTALinks(for arCodeId: String, completion: @escaping (Result<[ARCodeCTALink], Error>) -> Void) {
        Task {
            do {
                let links: [ARCodeCTALink] = try await networkService.request(
                    .getCTALinks,
                    method: .get,
                    parameters: nil,
                    headers: nil,
                    pathParameters: ["ar_code_id": arCodeId]
                )
                DispatchQueue.main.async {
                    completion(.success(links))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func createCTALink(_ link: ARCodeCTALink, completion: @escaping (Result<ARCodeCTALink, Error>) -> Void) {
        let parameters: [String: Any] = [
            "ar_code_id": link.arCodeId,
            "button_text": link.buttonText,
            "button_style": link.buttonStyle.rawValue,
            "destination_url": link.destinationURL,
            "destination_type": link.destinationType.rawValue,
            "position": link.position.rawValue,
            "is_enabled": link.isEnabled,
            "analytics_id": link.analyticsId as Any,
            "variant": link.variant as Any
        ]
        
        Task {
            do {
                let createdLink: ARCodeCTALink = try await networkService.request(
                    .createCTALink,
                    method: .post,
                    parameters: parameters,
                    headers: nil
                )
                DispatchQueue.main.async {
                    completion(.success(createdLink))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func updateCTALink(_ link: ARCodeCTALink, completion: @escaping (Result<ARCodeCTALink, Error>) -> Void) {
        let parameters: [String: Any] = [
            "button_text": link.buttonText,
            "button_style": link.buttonStyle.rawValue,
            "destination_url": link.destinationURL,
            "destination_type": link.destinationType.rawValue,
            "position": link.position.rawValue,
            "is_enabled": link.isEnabled
        ]
        
        Task {
            do {
                let updatedLink: ARCodeCTALink = try await networkService.request(
                    .updateCTALink,
                    method: .put,
                    parameters: parameters,
                    headers: nil,
                    pathParameters: ["id": link.id]
                )
                DispatchQueue.main.async {
                    completion(.success(updatedLink))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func deleteCTALink(id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                let _: EmptyResponse = try await networkService.request(
                    .deleteCTALink,
                    method: .delete,
                    parameters: nil,
                    headers: nil,
                    pathParameters: ["id": id]
                )
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Analytics & Tracking
    
    func trackCTAClick(linkId: String, variant: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        let parameters: [String: Any] = [
            "link_id": linkId,
            "variant": variant as Any,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        Task {
            do {
                let _: EmptyResponse = try await networkService.request(
                    .trackCTAClick,
                    method: .post,
                    parameters: parameters,
                    headers: nil
                )
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Redirection
    
    func handleCTARedirection(url: String, destinationType: CTADestinationType) -> Bool {
        guard let urlObject = URL(string: url) else {
            return false
        }
        
        switch destinationType {
        case .productPage, .landingPage, .website:
            return openURL(urlObject)
            
        case .appDownload:
            // Ouvrir App Store
            if let appStoreURL = URL(string: url) {
                return openURL(appStoreURL)
            }
            return false
            
        case .socialMedia:
            // Ouvrir app social ou browser
            return openURL(urlObject)
            
        case .deepLink:
            // Utiliser deep linking
            return handleDeepLink(url: url)
            
        case .email:
            // Ouvrir mailto:
            if let mailtoURL = URL(string: "mailto:\(url)") {
                return openURL(mailtoURL)
            }
            return false
            
        case .phone:
            // Ouvrir tel:
            if let telURL = URL(string: "tel:\(url)") {
                return openURL(telURL)
            }
            return false
        }
    }
    
    private func openURL(_ url: URL) -> Bool {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            return true
        }
        return false
    }
    
    private func handleDeepLink(url: String) -> Bool {
        // Gérer deep linking (ex: ar-code://ar-code/123)
        if let urlObject = URL(string: url) {
            return openURL(urlObject)
        }
        return false
    }
}

struct EmptyResponse: Codable {}

