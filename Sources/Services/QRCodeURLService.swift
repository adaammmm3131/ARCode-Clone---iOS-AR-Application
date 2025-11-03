//
//  QRCodeURLService.swift
//  ARCodeClone
//
//  Service pour création URL shortener et metadata
//

import Foundation

protocol QRCodeURLServiceProtocol {
    func createShortURL(arCodeId: String, contentType: String, assetId: String?, params: [String: Any]?) -> String
    func parseShortURL(url: String) -> QRCodeMetadata?
    func generateUniqueID() -> String
}

struct QRCodeMetadata {
    let arCodeId: String
    let contentType: String
    let assetId: String?
    let params: [String: Any]
}

enum QRCodeURLError: LocalizedError {
    case invalidURL
    case parsingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalide"
        case .parsingFailed:
            return "Échec parsing URL"
        }
    }
}

final class QRCodeURLService: QRCodeURLServiceProtocol {
    private let baseURL: String
    
    init(baseURL: String = "https://ar-code.com") {
        self.baseURL = baseURL
    }
    
    // MARK: - Short URL Generation
    
    func createShortURL(
        arCodeId: String,
        contentType: String,
        assetId: String?,
        params: [String: Any]? = nil
    ) -> String {
        // Générer unique ID court (base64 encodé UUID sans padding)
        let uniqueId = generateUniqueID()
        
        // Construire URL: https://ar-code.com/a/[UNIQUE_ID]
        var url = "\(baseURL)/a/\(uniqueId)"
        
        // Encoder metadata dans query parameters
        var queryItems: [String] = []
        
        queryItems.append("id=\(arCodeId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? arCodeId)")
        queryItems.append("type=\(contentType.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? contentType)")
        
        if let assetId = assetId {
            queryItems.append("asset=\(assetId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? assetId)")
        }
        
        // Ajouter params additionnels
        if let params = params {
            for (key, value) in params {
                let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
                let encodedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "\(value)"
                queryItems.append("\(encodedKey)=\(encodedValue)")
            }
        }
        
        if !queryItems.isEmpty {
            url += "?" + queryItems.joined(separator: "&")
        }
        
        return url
    }
    
    // MARK: - URL Parsing
    
    func parseShortURL(url: String) -> QRCodeMetadata? {
        guard let urlComponents = URLComponents(string: url) else {
            return nil
        }
        
        // Extraire unique ID depuis path
        let pathComponents = urlComponents.path.components(separatedBy: "/")
        guard pathComponents.count >= 2, pathComponents[pathComponents.count - 2] == "a" else {
            return nil
        }
        
        let uniqueId = pathComponents.last ?? ""
        
        // Parser query parameters
        guard let queryItems = urlComponents.queryItems else {
            return nil
        }
        
        var arCodeId: String?
        var contentType: String?
        var assetId: String?
        var params: [String: Any] = [:]
        
        for item in queryItems {
            switch item.name {
            case "id":
                arCodeId = item.value
            case "type":
                contentType = item.value
            case "asset":
                assetId = item.value
            default:
                params[item.name] = item.value ?? ""
            }
        }
        
        guard let id = arCodeId, let type = contentType else {
            return nil
        }
        
        return QRCodeMetadata(
            arCodeId: id,
            contentType: type,
            assetId: assetId,
            params: params
        )
    }
    
    // MARK: - Unique ID Generation
    
    func generateUniqueID() -> String {
        // Générer UUID et encoder en base64 URL-safe sans padding
        let uuid = UUID()
        
        // Convertir UUID en Data (16 bytes)
        var uuidBytes = [UInt8](repeating: 0, count: 16)
        (uuid as NSUUID).getBytes(&uuidBytes)
        let uuidData = Data(uuidBytes)
        
        // Encoder en base64 et retirer padding
        let base64String = uuidData.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        
        // Prendre 12 premiers caractères pour URL courte
        return String(base64String.prefix(12))
    }
}

