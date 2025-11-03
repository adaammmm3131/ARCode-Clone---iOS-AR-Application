//
//  AuthenticationService.swift
//  ARCodeClone
//
//  Service pour authentification OAuth 2.0
//

import Foundation
import AuthenticationServices
import Security
import UIKit

protocol AuthenticationServiceProtocol {
    func authenticate(completion: @escaping (Result<AuthToken, Error>) -> Void)
    func refreshToken(completion: @escaping (Result<AuthToken, Error>) -> Void)
    func logout()
    func getCurrentToken() -> AuthToken?
    func isAuthenticated() -> Bool
}

struct AuthToken: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: TimeInterval
    let tokenType: String
    let expiresAt: Date
    
    init(accessToken: String, refreshToken: String?, expiresIn: TimeInterval, tokenType: String = "Bearer") {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.tokenType = tokenType
        self.expiresAt = Date().addingTimeInterval(expiresIn)
    }
    
    var isExpired: Bool {
        return Date() >= expiresAt
    }
}

enum AuthenticationError: LocalizedError {
    case authenticationCancelled
    case invalidCredentials
    case tokenRefreshFailed
    case networkError(Error)
    case invalidToken
    
    var errorDescription: String? {
        switch self {
        case .authenticationCancelled:
            return "Authentification annulée"
        case .invalidCredentials:
            return "Identifiants invalides"
        case .tokenRefreshFailed:
            return "Échec rafraîchissement token"
        case .networkError(let error):
            return "Erreur réseau: \(error.localizedDescription)"
        case .invalidToken:
            return "Token invalide"
        }
    }
}

final class AuthenticationService: NSObject, AuthenticationServiceProtocol {
    private let networkService: NetworkServiceProtocol
    // KeychainService est maintenant dans Sources/Services/KeychainService.swift
    private let baseURL: String
    private let clientId: String
    private let clientSecret: String
    private let redirectURI: String
    
    private var currentToken: AuthToken?
    
    init(
        networkService: NetworkServiceProtocol,
        baseURL: String = "https://api.ar-code.com",
        clientId: String,
        clientSecret: String,
        redirectURI: String = "ar-code://oauth/callback"
    ) {
        self.networkService = networkService
        self.baseURL = baseURL
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.redirectURI = redirectURI
        // KeychainService utilisé via méthodes statiques
        super.init()
        
        // Charger token depuis Keychain
        loadTokenFromKeychain()
    }
    
    // MARK: - Authentication
    
    func authenticate(completion: @escaping (Result<AuthToken, Error>) -> Void) {
        // OAuth 2.0 Authorization Code Flow
        // Étape 1: Rediriger vers authorization endpoint
        guard let authURL = URL(string: "\(baseURL)/oauth/authorize?client_id=\(clientId)&redirect_uri=\(redirectURI)&response_type=code&scope=read write") else {
            completion(.failure(AuthenticationError.invalidCredentials))
            return
        }
        
        // Utiliser ASWebAuthenticationSession pour OAuth
        let session = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: "ar-code"
        ) { [weak self] callbackURL, error in
            guard let self = self else { return }
            
            if let error = error {
                if let authError = error as? ASWebAuthenticationSessionError,
                   authError.code == .canceledLogin {
                    completion(.failure(AuthenticationError.authenticationCancelled))
                } else {
                    completion(.failure(AuthenticationError.networkError(error)))
                }
                return
            }
            
            guard let callbackURL = callbackURL,
                  let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                  let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
                completion(.failure(AuthenticationError.invalidCredentials))
                return
            }
            
            // Étape 2: Échanger code contre token
            self.exchangeCodeForToken(code: code, completion: completion)
        }
        
        session.presentationContextProvider = self
        session.start()
    }
    
    // MARK: - Token Exchange
    
    private func exchangeCodeForToken(code: String, completion: @escaping (Result<AuthToken, Error>) -> Void) {
        Task {
            do {
                let body: [String: Any] = [
                    "grant_type": "authorization_code",
                    "code": code,
                    "client_id": clientId,
                    "client_secret": clientSecret,
                    "redirect_uri": redirectURI
                ]
                
                // Note: Nécessite endpoint OAuth token
                let response: [String: Any] = try await networkService.request(
                    APIEndpoint(rawValue: "/oauth/token") ?? .createARCode,
                    method: .post,
                    parameters: body,
                    headers: ["Content-Type": "application/json"]
                )
                
                guard let accessToken = response["access_token"] as? String,
                      let expiresIn = response["expires_in"] as? TimeInterval else {
                    completion(.failure(AuthenticationError.invalidToken))
                    return
                }
                
                let refreshToken = response["refresh_token"] as? String
                let tokenType = response["token_type"] as? String ?? "Bearer"
                
                let token = AuthToken(
                    accessToken: accessToken,
                    refreshToken: refreshToken,
                    expiresIn: expiresIn,
                    tokenType: tokenType
                )
                
                // Sauvegarder token
                self.saveToken(token)
                
                DispatchQueue.main.async {
                    completion(.success(token))
                }
                
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(AuthenticationError.networkError(error)))
                }
            }
        }
    }
    
    // MARK: - Token Refresh
    
    func refreshToken(completion: @escaping (Result<AuthToken, Error>) -> Void) {
        guard let token = currentToken,
              let refreshToken = token.refreshToken else {
            completion(.failure(AuthenticationError.tokenRefreshFailed))
            return
        }
        
        Task {
            do {
                let body: [String: Any] = [
                    "grant_type": "refresh_token",
                    "refresh_token": refreshToken,
                    "client_id": clientId,
                    "client_secret": clientSecret
                ]
                
                let response: [String: Any] = try await networkService.request(
                    APIEndpoint(rawValue: "/oauth/token") ?? .createARCode,
                    method: .post,
                    parameters: body,
                    headers: ["Content-Type": "application/json"]
                )
                
                guard let accessToken = response["access_token"] as? String,
                      let expiresIn = response["expires_in"] as? TimeInterval else {
                    completion(.failure(AuthenticationError.invalidToken))
                    return
                }
                
                let newRefreshToken = response["refresh_token"] as? String ?? refreshToken
                let tokenType = response["token_type"] as? String ?? "Bearer"
                
                let newToken = AuthToken(
                    accessToken: accessToken,
                    refreshToken: newRefreshToken,
                    expiresIn: expiresIn,
                    tokenType: tokenType
                )
                
                self.saveToken(newToken)
                
                DispatchQueue.main.async {
                    completion(.success(newToken))
                }
                
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(AuthenticationError.tokenRefreshFailed))
                }
            }
        }
    }
    
    // MARK: - Token Management
    
    func getCurrentToken() -> AuthToken? {
        // Vérifier expiration et refresh si nécessaire
        if let token = currentToken, token.isExpired {
            // Auto-refresh en arrière-plan
            refreshToken { result in
                // Token sera mis à jour automatiquement
            }
        }
        return currentToken
    }
    
    func isAuthenticated() -> Bool {
        guard let token = currentToken else {
            return false
        }
        return !token.isExpired
    }
    
    func logout() {
        currentToken = nil
        try? KeychainService.delete(key: "access_token")
        try? KeychainService.delete(key: "refresh_token")
        try? KeychainService.delete(key: "token_expires_at")
    }
    
    // MARK: - Keychain Storage
    
    private func saveToken(_ token: AuthToken) {
        currentToken = token
        
        // Save access token
        try? KeychainService.save(token: token.accessToken, key: "access_token")
        
        // Save refresh token if available
        if let refreshToken = token.refreshToken {
            try? KeychainService.save(token: refreshToken, key: "refresh_token")
        }
        
        // Save expiration timestamp
        let expiresAt = token.expiresAt.timeIntervalSince1970
        try? KeychainService.save(token: String(expiresAt), key: "token_expires_at")
    }
    
    private func loadTokenFromKeychain() {
        guard let accessToken = try? KeychainService.load(key: "access_token"),
              let refreshToken = try? KeychainService.load(key: "refresh_token") else {
            return
        }
        
        // Load expiration
        let expiresAt: Date
        if let expiresAtString = try? KeychainService.load(key: "token_expires_at"),
           let timestamp = TimeInterval(expiresAtString) {
            expiresAt = Date(timeIntervalSince1970: timestamp)
        } else {
            expiresAt = Date().addingTimeInterval(3600) // Default 1 hour
        }
        
        // Check if expired
        if Date() >= expiresAt {
            // Token expired, will need refresh
            return
        }
        
        // Create token
        let expiresIn = expiresAt.timeIntervalSinceNow
        let token = AuthToken(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn,
            tokenType: "Bearer"
        )
        
        currentToken = token
    }
}

// MARK: - ASWebAuthenticationSessionPresentationContextProviding

extension AuthenticationService: ASWebAuthenticationSessionPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Retourner la window principale
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window available")
        }
        return window
    }
}

// Note: KeychainService est défini dans Sources/Services/KeychainService.swift

