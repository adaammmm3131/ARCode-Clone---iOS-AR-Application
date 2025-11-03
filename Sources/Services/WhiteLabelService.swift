//
//  WhiteLabelService.swift
//  ARCodeClone
//
//  Service pour gestion white label
//

import Foundation
import UIKit

protocol WhiteLabelServiceProtocol {
    func getWhiteLabelConfig(completion: @escaping (Result<WhiteLabelConfig?, Error>) -> Void)
    func updateWhiteLabelConfig(_ config: WhiteLabelConfig, completion: @escaping (Result<WhiteLabelConfig, Error>) -> Void)
    func loadCustomLogo(from url: String, completion: @escaping (Result<UIImage, Error>) -> Void)
    func applyColorScheme(_ colors: WhiteLabelSettings) -> ColorScheme
    func validateCustomDomain(_ domain: String, completion: @escaping (Result<Bool, Error>) -> Void)
}

final class WhiteLabelService: WhiteLabelServiceProtocol {
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    func getWhiteLabelConfig(completion: @escaping (Result<WhiteLabelConfig?, Error>) -> Void) {
        Task {
            do {
                let config: WhiteLabelConfig? = try await networkService.request(
                    .getWhiteLabelConfig,
                    method: .get,
                    parameters: nil,
                    headers: nil
                )
                DispatchQueue.main.async {
                    completion(.success(config))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func updateWhiteLabelConfig(_ config: WhiteLabelConfig, completion: @escaping (Result<WhiteLabelConfig, Error>) -> Void) {
        let parameters: [String: Any] = [
            "settings": try! JSONEncoder().encode(config.settings),
            "is_active": config.isActive
        ]
        
        Task {
            do {
                let updated: WhiteLabelConfig = try await networkService.request(
                    .updateWhiteLabelConfig,
                    method: .put,
                    parameters: parameters,
                    headers: nil,
                    pathParameters: ["id": config.id]
                )
                DispatchQueue.main.async {
                    completion(.success(updated))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func loadCustomLogo(from url: String, completion: @escaping (Result<UIImage, Error>) -> Void) {
        guard let urlObject = URL(string: url) else {
            completion(.failure(NSError(domain: "WhiteLabelService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: urlObject)
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        completion(.success(image))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "WhiteLabelService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func applyColorScheme(_ settings: WhiteLabelSettings) -> ColorScheme {
        // Créer ColorScheme personnalisé depuis settings
        // Note: En production, créer un ColorScheme SwiftUI custom
        return ColorScheme.light // Placeholder
    }
    
    func validateCustomDomain(_ domain: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let parameters: [String: Any] = [
            "domain": domain
        ]
        
        Task {
            do {
                let response: DomainValidationResponse = try await networkService.request(
                    .validateCustomDomain,
                    method: .post,
                    parameters: parameters,
                    headers: nil
                )
                DispatchQueue.main.async {
                    completion(.success(response.isValid))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}

struct DomainValidationResponse: Codable {
    let isValid: Bool
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case isValid = "is_valid"
        case message
    }
}

