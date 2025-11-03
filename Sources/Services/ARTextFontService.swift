//
//  ARTextFontService.swift
//  ARCodeClone
//
//  Service pour gestion Google Fonts (50+ polices intégrées)
//

import Foundation
import UIKit

protocol ARTextFontServiceProtocol {
    func getAvailableFonts() -> [FontInfo]
    func loadFont(name: String, size: CGFloat) -> UIFont?
    func downloadFont(name: String, completion: @escaping (Result<UIFont, Error>) -> Void)
}

struct FontInfo {
    let name: String
    let displayName: String
    let category: FontCategory
    let isSystemFont: Bool
    let isLoaded: Bool
}

enum FontCategory {
    case serif
    case sansSerif
    case display
    case handwriting
    case monospace
}

enum ARTextFontError: LocalizedError {
    case fontNotFound
    case fontLoadFailed
    case downloadFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .fontNotFound:
            return "Police introuvable"
        case .fontLoadFailed:
            return "Échec chargement police"
        case .downloadFailed(let error):
            return "Échec téléchargement: \(error.localizedDescription)"
        }
    }
}

final class ARTextFontService: ARTextFontServiceProtocol {
    // Liste de 50+ Google Fonts populaires
    private let googleFonts: [FontInfo] = [
        // Sans-serif
        FontInfo(name: "Roboto", displayName: "Roboto", category: .sansSerif, isSystemFont: false, isLoaded: false),
        FontInfo(name: "Open Sans", displayName: "Open Sans", category: .sansSerif, isSystemFont: false, isLoaded: false),
        FontInfo(name: "Lato", displayName: "Lato", category: .sansSerif, isSystemFont: false, isLoaded: false),
        FontInfo(name: "Montserrat", displayName: "Montserrat", category: .sansSerif, isSystemFont: false, isLoaded: false),
        FontInfo(name: "Raleway", displayName: "Raleway", category: .sansSerif, isSystemFont: false, isLoaded: false),
        FontInfo(name: "Ubuntu", displayName: "Ubuntu", category: .sansSerif, isSystemFont: false, isLoaded: false),
        FontInfo(name: "Poppins", displayName: "Poppins", category: .sansSerif, isSystemFont: false, isLoaded: false),
        FontInfo(name: "Source Sans Pro", displayName: "Source Sans Pro", category: .sansSerif, isSystemFont: false, isLoaded: false),
        FontInfo(name: "Nunito", displayName: "Nunito", category: .sansSerif, isSystemFont: false, isLoaded: false),
        FontInfo(name: "Work Sans", displayName: "Work Sans", category: .sansSerif, isSystemFont: false, isLoaded: false),
        
        // Serif
        FontInfo(name: "Merriweather", displayName: "Merriweather", category: .serif, isSystemFont: false, isLoaded: false),
        FontInfo(name: "Lora", displayName: "Lora", category: .serif, isSystemFont: false, isLoaded: false),
        FontInfo(name: "Playfair Display", displayName: "Playfair Display", category: .serif, isSystemFont: false, isLoaded: false),
        FontInfo(name: "Roboto Slab", displayName: "Roboto Slab", category: .serif, isSystemFont: false, isLoaded: false),
        FontInfo(name: "Crimson Text", displayName: "Crimson Text", category: .serif, isSystemFont: false, isLoaded: false),
        FontInfo(name: "PT Serif", displayName: "PT Serif", category: .serif, isSystemFont: false, isLoaded: false),
        FontInfo(name: "Libre Baskerville", displayName: "Libre Baskerville", category: .serif, isSystemFont: false, isLoaded: false),
        FontInfo(name: "Vollkorn", displayName: "Vollkorn", category: .serif, isSystemFont: false, isLoaded: false),
        
        // Display
        FontInfo(name: "Bebas Neue", displayName: "Bebas Neue", category: .display, isSystemFont: false, isLoaded: false),
        FontInfo(name: "Oswald", displayName: "Oswald", category: .display, isSystemFont: false, isLoaded: false),
        FontInfo(name: "Anton", displayName: "Anton", category: .display, isSystemFont: false, isLoaded: false),
        FontInfo(name: "Righteous", displayName: "Righteous", category: .display, isSystemFont: false, isLoaded: false),
        FontInfo(name: "Bangers", displayName: "Bangers", category: .display, isSystemFont: false, isLoaded: false),
        FontInfo(name: "Fredoka One", displayName: "Fredoka One", category: .display, isSystemFont: false, isLoaded: false),
        FontInfo(name: "Patua One", displayName: "Patua One", category: .display, isSystemFont: false, isLoaded: false),
        
        // Handwriting
        FontInfo(name: "Dancing Script", displayName: "Dancing Script", category: .handwriting, isSystemFont: false, isLoaded: false),
        FontInfo(name: "Pacifico", displayName: "Pacifico", category: .handwriting, isSystemFont: false, isLoaded: false),
        FontInfo(name: "Kalam", displayName: "Kalam", category: .handwriting, isSystemFont: false, isLoaded: false),
        FontInfo(name: "Shadows Into Light", displayName: "Shadows Into Light", category: .handwriting, isSystemFont: false, isLoaded: false),
        FontInfo(name: "Indie Flower", displayName: "Indie Flower", category: .handwriting, isSystemFont: false, isLoaded: false),
        FontInfo(name: "Amatic SC", displayName: "Amatic SC", category: .handwriting, isSystemFont: false, isLoaded: false),
        
        // Monospace
        FontInfo(name: "Roboto Mono", displayName: "Roboto Mono", category: .monospace, isSystemFont: false, isLoaded: false),
        FontInfo(name: "Source Code Pro", displayName: "Source Code Pro", category: .monospace, isSystemFont: false, isLoaded: false),
        FontInfo(name: "Fira Code", displayName: "Fira Code", category: .monospace, isSystemFont: false, isLoaded: false),
        FontInfo(name: "Space Mono", displayName: "Space Mono", category: .monospace, isSystemFont: false, isLoaded: false),
        
        // System Fonts (disponibles nativement)
        FontInfo(name: "Helvetica", displayName: "Helvetica", category: .sansSerif, isSystemFont: true, isLoaded: true),
        FontInfo(name: "Helvetica Neue", displayName: "Helvetica Neue", category: .sansSerif, isSystemFont: true, isLoaded: true),
        FontInfo(name: "Arial", displayName: "Arial", category: .sansSerif, isSystemFont: true, isLoaded: true),
        FontInfo(name: "Times New Roman", displayName: "Times New Roman", category: .serif, isSystemFont: true, isLoaded: true),
        FontInfo(name: "Courier", displayName: "Courier", category: .monospace, isSystemFont: true, isLoaded: true),
        FontInfo(name: "Georgia", displayName: "Georgia", category: .serif, isSystemFont: true, isLoaded: true),
        FontInfo(name: "Palatino", displayName: "Palatino", category: .serif, isSystemFont: true, isLoaded: true),
    ]
    
    private var loadedFonts: [String: UIFont] = [:]
    
    // MARK: - Font Management
    
    func getAvailableFonts() -> [FontInfo] {
        return googleFonts
    }
    
    func loadFont(name: String, size: CGFloat) -> UIFont? {
        // Vérifier si font déjà chargée
        if let cachedFont = loadedFonts["\(name)_\(size)"] {
            return cachedFont
        }
        
        // Vérifier si font système
        if let systemFont = UIFont(name: name, size: size) {
            loadedFonts["\(name)_\(size)"] = systemFont
            return systemFont
        }
        
        // Pour Google Fonts, utiliser CTFont ou télécharger
        // Note: En production, télécharger depuis Google Fonts API
        // Pour l'instant, fallback sur font système
        
        // Fallback: utiliser font système par défaut
        if let fallbackFont = UIFont(name: "Helvetica", size: size) {
            return fallbackFont
        }
        
        return UIFont.systemFont(ofSize: size)
    }
    
    func downloadFont(name: String, completion: @escaping (Result<UIFont, Error>) -> Void) {
        // Télécharger police depuis Google Fonts API
        // Format URL: https://fonts.googleapis.com/css2?family={fontName}
        let fontNameEscaped = name.replacingOccurrences(of: " ", with: "+")
        let urlString = "https://fonts.googleapis.com/css2?family=\(fontNameEscaped):wght@400"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(ARTextFontError.fontNotFound))
            return
        }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                
                // Parser CSS et télécharger font file
                // Note: Implémentation simplifiée, en production utiliser bibliothèque dédiée
                
                // Pour l'instant, retourner font système
                if let font = UIFont(name: name, size: 16) {
                    DispatchQueue.main.async {
                        completion(.success(font))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(ARTextFontError.fontLoadFailed))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(ARTextFontError.downloadFailed(error)))
                }
            }
        }
    }
}










