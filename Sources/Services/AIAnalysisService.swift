//
//  AIAnalysisService.swift
//  ARCodeClone
//
//  Service d'analyse d'images avec Ollama Vision Models
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif
import AVFoundation

protocol AIAnalysisServiceProtocol {
    #if canImport(UIKit)
    func analyzeImage(_ image: UIImage, prompt: String?, context: String?, completion: @escaping (Result<AIAnalysisResult, Error>) -> Void)
    #endif
    func synthesizeVoice(from text: String, language: String, completion: @escaping (Result<Data, Error>) -> Void)
}

struct AIAnalysisResult {
    let responseText: String
    let detectedObjects: [String]
    let sceneContext: [String: Any]
    let processingTime: Double
    let model: String
    let timestamp: Date
}

enum AIAnalysisError: LocalizedError {
    case imageConversionFailed
    case networkError(Error)
    case apiError(String)
    case voiceSynthesisFailed
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Échec de la conversion de l'image"
        case .networkError(let error):
            return "Erreur réseau: \(error.localizedDescription)"
        case .apiError(let message):
            return "Erreur API: \(message)"
        case .voiceSynthesisFailed:
            return "Échec de la synthèse vocale"
        }
    }
}

final class AIAnalysisService: AIAnalysisServiceProtocol {
    private let networkService: NetworkServiceProtocol
    private let baseURL: String
    
    init(networkService: NetworkServiceProtocol, baseURL: String = "http://localhost:5001") {
        self.networkService = networkService
        self.baseURL = baseURL
    }
    
    // MARK: - Image Analysis
    
    #if canImport(UIKit)
    func analyzeImage(_ image: UIImage, prompt: String?, context: String?, completion: @escaping (Result<AIAnalysisResult, Error>) -> Void) {
        // Convertir image en base64
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(AIAnalysisError.imageConversionFailed))
            return
        }
        
        let base64String = imageData.base64EncodedString()
        let imageBase64 = "data:image/jpeg;base64,\(base64String)"
        
        // Construire prompt par défaut si non fourni
        let defaultPrompt = "Describe this image in detail. Identify all objects, people, text, and context. Provide a comprehensive analysis."
        let finalPrompt = prompt ?? defaultPrompt
        
        // Préparer body JSON
        var body: [String: Any] = [
            "image": imageBase64,
            "prompt": finalPrompt,
            "cache": true
        ]
        
        if let context = context {
            body["context"] = context
        }
        
        // Appel API Ollama
        Task {
            do {
                // Utiliser endpoint AI analyze
                let endpoint = APIEndpoint.aiAnalyze
                let response: OllamaAnalysisResponse = try await networkService.request(
                    endpoint,
                    method: .post,
                    parameters: body,
                    headers: ["Content-Type": "application/json"]
                )
                
                // Convertir réponse en AIAnalysisResult
                let result = AIAnalysisResult(
                    responseText: response.responseText,
                    detectedObjects: response.detectedObjects,
                    sceneContext: response.sceneContext,
                    processingTime: response.processingTime,
                    model: response.model,
                    timestamp: Date()
                )
                
                DispatchQueue.main.async {
                    completion(.success(result))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(AIAnalysisError.networkError(error)))
                }
            }
        }
    }
    #endif
    
    // MARK: - Voice Synthesis
    
    func synthesizeVoice(from text: String, language: String, completion: @escaping (Result<Data, Error>) -> Void) {
        // Utiliser AVSpeechSynthesizer pour synthèse vocale locale
        let synthesizer = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string: text)
        
        // Configurer langue et voix
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.5 // Vitesse moyenne
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        // Capturer audio (nécessite configuration spéciale)
        // Pour l'instant, utiliser synthèse native iOS
        // TODO: Implémenter capture audio si nécessaire
        
        synthesizer.speak(utterance)
        
        // Pour l'instant, retourner données texte comme placeholder
        // En production, utiliser AVAudioEngine pour capturer audio
        completion(.success(text.data(using: .utf8)!))
    }
}

// MARK: - API Response Models

struct OllamaAnalysisResponse: Codable {
    let responseText: String
    let detectedObjects: [String]
    let sceneContext: [String: String] // Simplified from Any
    let processingTime: Double
    let model: String
    let timestamp: String
    
    enum CodingKeys: String, CodingKey {
        case responseText = "response_text"
        case detectedObjects = "detected_objects"
        case sceneContext = "scene_context"
        case processingTime = "processing_time"
        case model
        case timestamp
    }
}

// MARK: - Voice Synthesis Service

final class VoiceSynthesisService {
    private let synthesizer = AVSpeechSynthesizer()
    
    func speak(_ text: String, language: String = "en-US", completion: @escaping () -> Void) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        // Utiliser delegate pour détecter fin de synthèse
        let delegate = SpeechDelegate(completion: completion)
        synthesizer.delegate = delegate
        
        synthesizer.speak(utterance)
    }
    
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

private class SpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
    let completion: () -> Void
    
    init(completion: @escaping () -> Void) {
        self.completion = completion
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        completion()
    }
}










