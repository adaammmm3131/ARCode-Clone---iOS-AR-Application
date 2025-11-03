//
//  NetworkService.swift
//  ARCodeClone
//
//  Implémentation du service réseau avec URLSession
//

import Foundation

final class NetworkService: NetworkServiceProtocol {
    private let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder
    private let maxRetries: Int
    private let retryDelay: TimeInterval
    
    init(
        baseURL: String = "https://api.ar-code.com",
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 1.0
    ) {
        self.baseURL = baseURL
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        
        // Configuration avec certificate pinning
        let delegate = NetworkSessionDelegate()
        self.session = URLSession(
            configuration: configuration,
            delegate: delegate,
            delegateQueue: nil
        )
        
        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }
    
    func request<T: Decodable>(
        _ endpoint: APIEndpoint,
        method: HTTPMethod,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        pathParameters: [String: String]? = nil
    ) async throws -> T {
        var urlString = baseURL + endpoint.path(replacing: pathParameters ?? [:])
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // Headers par défaut
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Headers personnalisés
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Paramètres pour GET
        if method == .get, let parameters = parameters {
            var components = URLComponents(string: urlString)
            components?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
            if let url = components?.url {
                request.url = url
            }
        }
        
        // Body pour POST/PUT/PATCH
        if method != .get, let parameters = parameters {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        }
        
        // Retry logic
        var lastError: Error?
        for attempt in 0...maxRetries {
            do {
                let (data, response) = try await session.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                guard 200...299 ~= httpResponse.statusCode else {
                    // Ne pas retry sur erreurs 4xx (client errors)
                    if 400...499 ~= httpResponse.statusCode {
                        throw NetworkError.httpError(statusCode: httpResponse.statusCode)
                    }
                    // Retry sur erreurs 5xx (server errors)
                    throw NetworkError.httpError(statusCode: httpResponse.statusCode)
                }
                
                return try decoder.decode(T.self, from: data)
            } catch {
                lastError = error
                
                // Ne pas retry si c'est la dernière tentative ou erreur de décodage
                if attempt == maxRetries || error is DecodingError {
                    break
                }
                
                // Attendre avant retry (exponential backoff)
                let delay = retryDelay * pow(2.0, Double(attempt))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        throw lastError ?? NetworkError.invalidResponse
    }
    
    func upload(
        _ endpoint: APIEndpoint,
        data: Data,
        fileName: String,
        progressHandler: @escaping (Double) -> Void,
        pathParameters: [String: String]? = nil
    ) async throws -> UploadResponse {
        var urlString = baseURL + endpoint.path(replacing: pathParameters ?? [:])
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        // Créer requête multipart
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Construire le body multipart
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        // Upload avec retry logic
        var lastError: Error?
        for attempt in 0...maxRetries {
            do {
                // Utiliser URLSession avec delegate pour progress tracking
                let progressDelegate = UploadProgressDelegate(progressHandler: progressHandler)
                let uploadSession = URLSession(
                    configuration: .default,
                    delegate: progressDelegate,
                    delegateQueue: .main
                )
                
                let (uploadData, response) = try await uploadSession.upload(
                    for: request,
                    from: body
                )
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                guard 200...299 ~= httpResponse.statusCode else {
                    if 400...499 ~= httpResponse.statusCode {
                        throw NetworkError.httpError(statusCode: httpResponse.statusCode)
                    }
                    throw NetworkError.httpError(statusCode: httpResponse.statusCode)
                }
                
                return try decoder.decode(UploadResponse.self, from: uploadData)
            } catch {
                lastError = error
                if attempt == maxRetries || error is DecodingError {
                    break
                }
                let delay = retryDelay * pow(2.0, Double(attempt))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        throw lastError ?? NetworkError.invalidResponse
    }
    
    func uploadVideo(
        _ videoURL: URL,
        endpoint: APIEndpoint,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> UploadResponse {
        // Déléguer à VideoUploadService qui a la logique complète
        // Cette méthode est pour compatibilité protocol
        throw NetworkError.notImplemented
    }
}

// MARK: - Upload Progress Delegate

class UploadProgressDelegate: NSObject, URLSessionTaskDelegate {
    let progressHandler: (Double) -> Void
    
    init(progressHandler: @escaping (Double) -> Void) {
        self.progressHandler = progressHandler
    }
    
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        progressHandler(min(progress, 1.0))
    }
}

/// Erreurs réseau
enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError
    case notImplemented
}

