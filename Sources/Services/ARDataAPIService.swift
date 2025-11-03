//
//  ARDataAPIService.swift
//  ARCodeClone
//
//  Service pour récupérer données dynamiques depuis API REST
//

import Foundation
import Combine

protocol ARDataAPIServiceProtocol {
    func fetchData(endpoint: String, parameters: [String: Any]?, completion: @escaping (Result<ARDataResponse, Error>) -> Void)
    func subscribeToUpdates(endpoint: String, interval: TimeInterval) -> AnyPublisher<ARDataResponse, Never>
    func registerWebhook(url: String, events: [String], completion: @escaping (Result<String, Error>) -> Void)
}

struct ARDataResponse: Codable {
    let data: [String: Any]
    let timestamp: Date
    let source: String?
    
    enum CodingKeys: String, CodingKey {
        case data, timestamp, source
    }
    
    init(data: [String: Any], timestamp: Date = Date(), source: String? = nil) {
        self.data = data
        self.timestamp = timestamp
        self.source = source
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        source = try container.decodeIfPresent(String.self, forKey: .source)
        
        // Decoder data comme dictionnaire générique
        let dataContainer = try container.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: .data)
        var decodedData: [String: Any] = [:]
        
        for key in dataContainer.allKeys {
            if let value = try? dataContainer.decode(String.self, forKey: key) {
                decodedData[key.stringValue] = value
            } else if let value = try? dataContainer.decode(Int.self, forKey: key) {
                decodedData[key.stringValue] = value
            } else if let value = try? dataContainer.decode(Double.self, forKey: key) {
                decodedData[key.stringValue] = value
            } else if let value = try? dataContainer.decode(Bool.self, forKey: key) {
                decodedData[key.stringValue] = value
            }
        }
        
        self.data = decodedData
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(source, forKey: .source)
        
        var dataContainer = container.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: .data)
        for (key, value) in data {
            let codingKey = DynamicCodingKeys(stringValue: key)!
            if let stringValue = value as? String {
                try dataContainer.encode(stringValue, forKey: codingKey)
            } else if let intValue = value as? Int {
                try dataContainer.encode(intValue, forKey: codingKey)
            } else if let doubleValue = value as? Double {
                try dataContainer.encode(doubleValue, forKey: codingKey)
            } else if let boolValue = value as? Bool {
                try dataContainer.encode(boolValue, forKey: codingKey)
            }
        }
    }
}

struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = "\(intValue)"
    }
}

enum ARDataAPIError: LocalizedError {
    case invalidEndpoint
    case networkError(Error)
    case apiError(String)
    case unauthorized
    case rateLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .invalidEndpoint:
            return "Endpoint invalide"
        case .networkError(let error):
            return "Erreur réseau: \(error.localizedDescription)"
        case .apiError(let message):
            return "Erreur API: \(message)"
        case .unauthorized:
            return "Non autorisé"
        case .rateLimitExceeded:
            return "Limite de requêtes dépassée"
        }
    }
}

final class ARDataAPIService: ARDataAPIServiceProtocol {
    private let networkService: NetworkServiceProtocol
    private let authService: AuthenticationServiceProtocol
    private let baseURL: String
    
    init(
        networkService: NetworkServiceProtocol,
        authService: AuthenticationServiceProtocol,
        baseURL: String = "https://api.ar-code.com"
    ) {
        self.networkService = networkService
        self.authService = authService
        self.baseURL = baseURL
    }
    
    // MARK: - Data Fetching
    
    func fetchData(endpoint: String, parameters: [String: Any]?, completion: @escaping (Result<ARDataResponse, Error>) -> Void) {
        // Vérifier authentification
        guard let token = authService.getCurrentToken() else {
            completion(.failure(ARDataAPIError.unauthorized))
            return
        }
        
        // Construire URL
        let fullEndpoint = endpoint.hasPrefix("/") ? endpoint : "/\(endpoint)"
        
        Task {
            do {
                // Créer endpoint custom
                let customEndpoint = APIEndpoint(rawValue: fullEndpoint) ?? .getARCode
                
                let headers = [
                    "Authorization": "\(token.tokenType) \(token.accessToken)",
                    "Content-Type": "application/json"
                ]
                
                let response: [String: Any] = try await networkService.request(
                    customEndpoint,
                    method: .get,
                    parameters: parameters,
                    headers: headers
                )
                
                // Parser response
                let dataResponse = ARDataResponse(
                    data: response,
                    timestamp: Date(),
                    source: endpoint
                )
                
                DispatchQueue.main.async {
                    completion(.success(dataResponse))
                }
                
            } catch {
                DispatchQueue.main.async {
                    if let networkError = error as? NetworkError,
                       case .httpError(let statusCode) = networkError,
                       statusCode == 401 {
                        completion(.failure(ARDataAPIError.unauthorized))
                    } else if case .httpError(let statusCode) = networkError as? NetworkError,
                              statusCode == 429 {
                        completion(.failure(ARDataAPIError.rateLimitExceeded))
                    } else {
                        completion(.failure(ARDataAPIError.networkError(error)))
                    }
                }
            }
        }
    }
    
    // MARK: - Polling Subscription
    
    func subscribeToUpdates(endpoint: String, interval: TimeInterval) -> AnyPublisher<ARDataResponse, Never> {
        let publisher = PassthroughSubject<ARDataResponse, Never>()
        
        // Polling périodique
        let timer = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchData(endpoint: endpoint, parameters: nil) { result in
                    switch result {
                    case .success(let response):
                        publisher.send(response)
                    case .failure:
                        // Ignorer erreurs temporaires
                        break
                    }
                }
            }
        
        // Fetch immédiat
        fetchData(endpoint: endpoint, parameters: nil) { result in
            if case .success(let response) = result {
                publisher.send(response)
            }
        }
        
        return publisher
            .handleEvents(receiveCancel: { timer.cancel() })
            .eraseToAnyPublisher()
    }
    
    // MARK: - Webhook Registration
    
    func registerWebhook(url: String, events: [String], completion: @escaping (Result<String, Error>) -> Void) {
        guard let token = authService.getCurrentToken() else {
            completion(.failure(ARDataAPIError.unauthorized))
            return
        }
        
        Task {
            do {
                let body: [String: Any] = [
                    "url": url,
                    "events": events,
                    "secret": UUID().uuidString // Pour validation signature
                ]
                
                let headers = [
                    "Authorization": "\(token.tokenType) \(token.accessToken)",
                    "Content-Type": "application/json"
                ]
                
                let response: [String: Any] = try await networkService.request(
                    APIEndpoint(rawValue: "/api/v1/webhooks/register") ?? .createARCode,
                    method: .post,
                    parameters: body,
                    headers: headers
                )
                
                guard let webhookId = response["webhook_id"] as? String else {
                    completion(.failure(ARDataAPIError.apiError("Invalid response")))
                    return
                }
                
                DispatchQueue.main.async {
                    completion(.success(webhookId))
                }
                
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(ARDataAPIError.networkError(error)))
                }
            }
        }
    }
}









