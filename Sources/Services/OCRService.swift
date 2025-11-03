//
//  OCRService.swift
//  ARCodeClone
//
//  Service OCR utilisant Vision framework pour détection et reconnaissance de texte
//

import Foundation
import Vision
import UIKit
import CoreML

protocol OCRServiceProtocol {
    func detectText(in image: UIImage, completion: @escaping (Result<[VNTextObservation], Error>) -> Void)
    func recognizeText(in image: UIImage, completion: @escaping (Result<[String], Error>) -> Void)
    func extractTextRegions(in image: UIImage, completion: @escaping (Result<[TextRegion], Error>) -> Void)
    func detectLanguage(in text: String) -> String?
}

struct TextRegion {
    let text: String
    let boundingBox: CGRect
    let confidence: Float
    let language: String?
}

enum OCRError: LocalizedError {
    case imageConversionFailed
    case noTextDetected
    case recognitionFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Échec de la conversion de l'image"
        case .noTextDetected:
            return "Aucun texte détecté dans l'image"
        case .recognitionFailed(let error):
            return "Échec de la reconnaissance de texte: \(error.localizedDescription)"
        }
    }
}

final class OCRService: OCRServiceProtocol {
    private let textDetectionRequest: VNDetectTextRectanglesRequest
    private let textRecognitionRequest: VNRecognizeTextRequest
    
    init() {
        // Configuration détection texte
        textDetectionRequest = VNDetectTextRectanglesRequest()
        textDetectionRequest.reportCharacterBoxes = true
        
        // Configuration reconnaissance texte
        textRecognitionRequest = VNRecognizeTextRequest()
        textRecognitionRequest.recognitionLevel = .accurate
        textRecognitionRequest.usesLanguageCorrection = true
        textRecognitionRequest.recognitionLanguages = ["en-US", "fr-FR", "es-ES", "de-DE", "it-IT", "pt-BR"]
    }
    
    // MARK: - Text Detection
    
    func detectText(in image: UIImage, completion: @escaping (Result<[VNTextObservation], Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(OCRError.imageConversionFailed))
            return
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        textDetectionRequest.completionHandler = { request, error in
            if let error = error {
                completion(.failure(OCRError.recognitionFailed(error)))
                return
            }
            
            guard let observations = request.results as? [VNTextObservation] else {
                completion(.failure(OCRError.noTextDetected))
                return
            }
            
            completion(.success(observations))
        }
        
        do {
            try handler.perform([textDetectionRequest])
        } catch {
            completion(.failure(OCRError.recognitionFailed(error)))
        }
    }
    
    // MARK: - Text Recognition
    
    func recognizeText(in image: UIImage, completion: @escaping (Result<[String], Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(OCRError.imageConversionFailed))
            return
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        textRecognitionRequest.completionHandler = { request, error in
            if let error = error {
                completion(.failure(OCRError.recognitionFailed(error)))
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(.failure(OCRError.noTextDetected))
                return
            }
            
            let recognizedStrings = observations.compactMap { observation -> String? in
                observation.topCandidates(1).first?.string
            }
            
            if recognizedStrings.isEmpty {
                completion(.failure(OCRError.noTextDetected))
            } else {
                completion(.success(recognizedStrings))
            }
        }
        
        do {
            try handler.perform([textRecognitionRequest])
        } catch {
            completion(.failure(OCRError.recognitionFailed(error)))
        }
    }
    
    // MARK: - Extract Text Regions
    
    func extractTextRegions(in image: UIImage, completion: @escaping (Result<[TextRegion], Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(OCRError.imageConversionFailed))
            return
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // Créer requête combinée pour détection + reconnaissance
        let combinedRequest = VNRecognizeTextRequest { request, error in
            if let error = error {
                completion(.failure(OCRError.recognitionFailed(error)))
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(.failure(OCRError.noTextDetected))
                return
            }
            
            let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
            let textRegions = observations.compactMap { observation -> TextRegion? in
                guard let topCandidate = observation.topCandidates(1).first else {
                    return nil
                }
                
                // Convertir boundingBox de coordonnées normalisées (0-1) vers coordonnées image
                let boundingBox = VNImageRectForNormalizedRect(
                    observation.boundingBox,
                    Int(imageSize.width),
                    Int(imageSize.height)
                )
                
                // Détecter langue du texte (approximation)
                let detectedLanguage = self.detectLanguage(in: topCandidate.string)
                
                return TextRegion(
                    text: topCandidate.string,
                    boundingBox: boundingBox,
                    confidence: topCandidate.confidence,
                    language: detectedLanguage
                )
            }
            
            if textRegions.isEmpty {
                completion(.failure(OCRError.noTextDetected))
            } else {
                completion(.success(textRegions))
            }
        }
        
        combinedRequest.recognitionLevel = .accurate
        combinedRequest.usesLanguageCorrection = true
        combinedRequest.recognitionLanguages = ["en-US", "fr-FR", "es-ES", "de-DE", "it-IT", "pt-BR"]
        
        do {
            try handler.perform([combinedRequest])
        } catch {
            completion(.failure(OCRError.recognitionFailed(error)))
        }
    }
    
    // MARK: - Language Detection
    
    func detectLanguage(in text: String) -> String? {
        // Utiliser NaturalLanguage framework pour détection langue
        if #available(iOS 12.0, *) {
            let recognizer = NLLanguageRecognizer()
            recognizer.processString(text)
            
            if let dominantLanguage = recognizer.dominantLanguage {
                return dominantLanguage.rawValue
            }
        }
        
        // Fallback: détection basique basée sur caractères
        return detectLanguageBasic(in: text)
    }
    
    private func detectLanguageBasic(in text: String) -> String? {
        // Détection basique basée sur caractères Unicode
        // Langues supportées: EN, FR, ES, DE, IT, PT, ZH, JA, KO, AR, etc.
        
        let textLower = text.lowercased()
        
        // Français
        if textLower.contains("à") || textLower.contains("é") || textLower.contains("è") || textLower.contains("ç") {
            return "fr"
        }
        
        // Espagnol
        if textLower.contains("ñ") || textLower.contains("¿") || textLower.contains("¡") {
            return "es"
        }
        
        // Allemand
        if textLower.contains("ä") || textLower.contains("ö") || textLower.contains("ü") || textLower.contains("ß") {
            return "de"
        }
        
        // Chinois/ Japonais/ Coréen (CJK)
        for char in text {
            let unicodeScalar = char.unicodeScalars.first?.value ?? 0
            if (0x4E00...0x9FFF).contains(unicodeScalar) { // CJK Unified Ideographs
                return "zh"
            } else if (0x3040...0x309F).contains(unicodeScalar) || (0x30A0...0x30FF).contains(unicodeScalar) { // Hiragana/Katakana
                return "ja"
            } else if (0xAC00...0xD7AF).contains(unicodeScalar) { // Hangul
                return "ko"
            }
        }
        
        // Arabe
        if text.range(of: "\\p{Arabic}", options: .regularExpression) != nil {
            return "ar"
        }
        
        // Par défaut: Anglais
        return "en"
    }
}

// MARK: - NaturalLanguage Framework Support

import NaturalLanguage

@available(iOS 12.0, *)
extension OCRService {
    /// Détection langue avancée avec NaturalLanguage
    func detectLanguageAdvanced(in text: String) -> (language: String, confidence: Float)? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        guard let dominantLanguage = recognizer.dominantLanguage else {
            return nil
        }
        
        // Obtenir confidence pour la langue dominante
        let hypotheses = recognizer.languageHypotheses(withMaximum: 1)
        let confidence = hypotheses[dominantLanguage] ?? 0.0
        
        return (language: dominantLanguage.rawValue, confidence: confidence)
    }
    
    /// Obtenir toutes les hypothèses de langue avec confidences
    func detectLanguageHypotheses(in text: String, maxCount: Int = 3) -> [(language: String, confidence: Float)] {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        let hypotheses = recognizer.languageHypotheses(withMaximum: maxCount)
        
        return hypotheses.map { (language: $0.key.rawValue, confidence: $0.value) }
            .sorted { $0.confidence > $1.confidence }
    }
}










