//
//  ARLogoUploadService.swift
//  ARCodeClone
//
//  Service pour upload et validation fichiers SVG
//

import Foundation
import UIKit

protocol ARLogoUploadServiceProtocol {
    func validateSVG(url: URL) -> SVGValidationResult
    func validateSVG(data: Data) -> SVGValidationResult
    func loadSVGPreview(url: URL, completion: @escaping (Result<UIImage, Error>) -> Void)
    func extractDimensions(from svgData: Data) -> CGSize?
}

struct SVGValidationResult {
    let isValid: Bool
    let format: String?
    let fileSize: Int64?
    let dimensions: CGSize?
    let errorMessage: String?
}

enum ARLogoUploadError: LocalizedError {
    case invalidFormat
    case fileTooLarge
    case invalidSVG
    case parseError(Error)
    case dimensionsNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Format SVG invalide"
        case .fileTooLarge:
            return "Fichier trop volumineux (max 5MB)"
        case .invalidSVG:
            return "Fichier SVG invalide ou corrompu"
        case .parseError(let error):
            return "Erreur parsing SVG: \(error.localizedDescription)"
        case .dimensionsNotFound:
            return "Dimensions SVG non trouvées"
        }
    }
}

final class ARLogoUploadService: ARLogoUploadServiceProtocol {
    private let maxFileSize: Int64 = 5 * 1024 * 1024 // 5MB
    
    // MARK: - SVG Validation
    
    func validateSVG(url: URL) -> SVGValidationResult {
        // Vérifier extension
        guard url.pathExtension.lowercased() == "svg" else {
            return SVGValidationResult(
                isValid: false,
                format: nil,
                fileSize: nil,
                dimensions: nil,
                errorMessage: "Format non supporté (SVG requis)"
            )
        }
        
        // Vérifier taille fichier
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? Int64 else {
            return SVGValidationResult(
                isValid: false,
                format: nil,
                fileSize: nil,
                dimensions: nil,
                errorMessage: "Impossible de lire les attributs du fichier"
            )
        }
        
        if fileSize > maxFileSize {
            return SVGValidationResult(
                isValid: false,
                format: "svg",
                fileSize: fileSize,
                dimensions: nil,
                errorMessage: "Fichier trop volumineux (max 5MB)"
            )
        }
        
        // Lire contenu
        guard let data = try? Data(contentsOf: url) else {
            return SVGValidationResult(
                isValid: false,
                format: "svg",
                fileSize: fileSize,
                dimensions: nil,
                errorMessage: "Impossible de lire le fichier"
            )
        }
        
        // Valider structure SVG basique
        let svgString = String(data: data, encoding: .utf8) ?? ""
        guard svgString.contains("<svg") else {
            return SVGValidationResult(
                isValid: false,
                format: "svg",
                fileSize: fileSize,
                dimensions: nil,
                errorMessage: "Structure SVG invalide"
            )
        }
        
        // Extraire dimensions
        let dimensions = extractDimensions(from: data)
        
        return SVGValidationResult(
            isValid: true,
            format: "svg",
            fileSize: fileSize,
            dimensions: dimensions,
            errorMessage: nil
        )
    }
    
    func validateSVG(data: Data) -> SVGValidationResult {
        // Vérifier taille
        let fileSize = Int64(data.count)
        if fileSize > maxFileSize {
            return SVGValidationResult(
                isValid: false,
                format: "svg",
                fileSize: fileSize,
                dimensions: nil,
                errorMessage: "Fichier trop volumineux (max 5MB)"
            )
        }
        
        // Valider structure SVG
        let svgString = String(data: data, encoding: .utf8) ?? ""
        guard svgString.contains("<svg") else {
            return SVGValidationResult(
                isValid: false,
                format: "svg",
                fileSize: fileSize,
                dimensions: nil,
                errorMessage: "Structure SVG invalide"
            )
        }
        
        // Extraire dimensions
        let dimensions = extractDimensions(from: data)
        
        return SVGValidationResult(
            isValid: true,
            format: "svg",
            fileSize: fileSize,
            dimensions: dimensions,
            errorMessage: nil
        )
    }
    
    // MARK: - SVG Preview
    
    func loadSVGPreview(url: URL, completion: @escaping (Result<UIImage, Error>) -> Void) {
        guard let data = try? Data(contentsOf: url) else {
            completion(.failure(ARLogoUploadError.invalidSVG))
            return
        }
        
        loadSVGPreview(data: data, completion: completion)
    }
    
    private func loadSVGPreview(data: Data, completion: @escaping (Result<UIImage, Error>) -> Void) {
        // Convertir SVG en UIImage pour preview
        // Note: iOS natif ne supporte pas directement SVG rendering
        // Solutions possibles:
        // 1. Utiliser WKWebView pour render SVG
        // 2. Utiliser bibliothèque externe (SwiftSVG, SVGKit)
        // 3. Parser SVG manuellement et créer UIBezierPath
        
        // Pour l'instant, utilisons une approche simplifiée avec WKWebView
        DispatchQueue.main.async {
            self.renderSVGToImage(data: data, completion: completion)
        }
    }
    
    private func renderSVGToImage(data: Data, completion: @escaping (Result<UIImage, Error>) -> Void) {
        guard let svgString = String(data: data, encoding: .utf8) else {
            completion(.failure(ARLogoUploadError.invalidSVG))
            return
        }
        
        // Créer image depuis SVG string
        // Utiliser WKWebView pour rendering SVG → UIImage
        let webView = WebViewRenderer()
        webView.renderSVG(svgString) { result in
            completion(result)
        }
    }
    
    // MARK: - Dimensions Extraction
    
    func extractDimensions(from svgData: Data) -> CGSize? {
        guard let svgString = String(data: svgData, encoding: .utf8) else {
            return nil
        }
        
        // Parser dimensions depuis attributs SVG
        // Format: <svg width="100" height="100" ...> ou viewBox="0 0 100 100"
        
        var width: CGFloat?
        var height: CGFloat?
        
        // Chercher width
        if let widthRange = svgString.range(of: #"width\s*=\s*["']([\d.]+)"#, options: .regularExpression) {
            let widthString = String(svgString[widthRange])
            if let valueRange = widthString.range(of: #"[\d.]+"#, options: .regularExpression) {
                width = CGFloat(Double(String(widthString[valueRange])) ?? 0)
            }
        }
        
        // Chercher height
        if let heightRange = svgString.range(of: #"height\s*=\s*["']([\d.]+)"#, options: .regularExpression) {
            let heightString = String(svgString[heightRange])
            if let valueRange = heightString.range(of: #"[\d.]+"#, options: .regularExpression) {
                height = CGFloat(Double(String(heightString[valueRange])) ?? 0)
            }
        }
        
        // Si pas de width/height, chercher viewBox
        if width == nil || height == nil {
            if let viewBoxRange = svgString.range(of: #"viewBox\s*=\s*["']([^"']+)"#, options: .regularExpression) {
                let viewBoxString = String(svgString[viewBoxRange])
                let components = viewBoxString.components(separatedBy: CharacterSet.whitespaces.union(.punctuationCharacters)).filter { !$0.isEmpty }
                if components.count >= 4 {
                    width = CGFloat(Double(components[2]) ?? 0)
                    height = CGFloat(Double(components[3]) ?? 0)
                }
            }
        }
        
        if let w = width, let h = height, w > 0 && h > 0 {
            return CGSize(width: w, height: h)
        }
        
        return nil
    }
}

// MARK: - WebView Renderer Helper

import WebKit

private class WebViewRenderer {
    func renderSVG(_ svgString: String, completion: @escaping (Result<UIImage, Error>) -> Void) {
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 512, height: 512))
        webView.isOpaque = false
        webView.backgroundColor = .clear
        
        // Créer HTML avec SVG
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    margin: 0;
                    padding: 0;
                    background: transparent;
                }
                svg {
                    width: 100%;
                    height: 100%;
                }
            </style>
        </head>
        <body>
            \(svgString)
        </body>
        </html>
        """
        
        webView.loadHTMLString(html, baseURL: nil)
        
        // Attendre chargement
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            webView.takeSnapshot(with: nil) { image, error in
                if let image = image {
                    completion(.success(image))
                } else if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.failure(ARLogoUploadError.invalidSVG))
                }
            }
        }
    }
}









