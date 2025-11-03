//
//  AICodeViewModel.swift
//  ARCodeClone
//
//  ViewModel pour AI Code feature
//

import Foundation
import SwiftUI
import Combine
import UIKit

final class AICodeViewModel: BaseViewModel, ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var analysisResult: AIAnalysisResult?
    @Published var isAnalyzing: Bool = false
    @Published var analysisError: String?
    @Published var extractedText: [TextRegion] = []
    @Published var segmentedPerson: UIImage?
    @Published var isProcessingOCR: Bool = false
    @Published var isProcessingSegmentation: Bool = false
    @Published var customPrompt: String = ""
    @Published var context: String = ""
    @Published var isVoiceEnabled: Bool = false
    
    private let aiAnalysisService: AIAnalysisServiceProtocol
    private let ocrService: OCRServiceProtocol
    private let segmentationService: SegmentationServiceProtocol
    private let voiceSynthesisService = VoiceSynthesisService()
    
    init(
        aiAnalysisService: AIAnalysisServiceProtocol,
        ocrService: OCRServiceProtocol,
        segmentationService: SegmentationServiceProtocol
    ) {
        self.aiAnalysisService = aiAnalysisService
        self.ocrService = ocrService
        self.segmentationService = segmentationService
        super.init()
    }
    
    // MARK: - Image Analysis
    
    func analyzeImage(_ image: UIImage) {
        guard !isAnalyzing else { return }
        
        isAnalyzing = true
        analysisError = nil
        analysisResult = nil
        
        let prompt = customPrompt.isEmpty ? nil : customPrompt
        let contextString = context.isEmpty ? nil : context
        
        aiAnalysisService.analyzeImage(image, prompt: prompt, context: contextString) { [weak self] result in
            DispatchQueue.main.async {
                self?.isAnalyzing = false
                
                switch result {
                case .success(let result):
                    self?.analysisResult = result
                    
                    // Synthèse vocale si activée
                    if self?.isVoiceEnabled == true {
                        self?.synthesizeVoice(result.responseText)
                    }
                    
                case .failure(let error):
                    self?.analysisError = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - OCR Processing
    
    func processOCR(_ image: UIImage) {
        guard !isProcessingOCR else { return }
        
        isProcessingOCR = true
        extractedText = []
        
        ocrService.extractTextRegions(in: image) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessingOCR = false
                
                switch result {
                case .success(let regions):
                    self?.extractedText = regions
                    
                case .failure(let error):
                    self?.analysisError = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Segmentation Processing
    
    func processSegmentation(_ image: UIImage) {
        guard !isProcessingSegmentation else { return }
        
        isProcessingSegmentation = true
        segmentedPerson = nil
        
        segmentationService.segmentPerson(in: image) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessingSegmentation = false
                
                switch result {
                case .success(let segmentedImage):
                    self?.segmentedPerson = segmentedImage
                    
                case .failure(let error):
                    self?.analysisError = error.localizedDescription
                }
            }
        }
    }
    
    func removeBackground(from image: UIImage) {
        guard !isProcessingSegmentation else { return }
        
        isProcessingSegmentation = true
        segmentedPerson = nil
        
        segmentationService.removeBackground(from: image) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessingSegmentation = false
                
                switch result {
                case .success(let imageWithoutBackground):
                    self?.segmentedPerson = imageWithoutBackground
                    
                case .failure(let error):
                    self?.analysisError = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Voice Synthesis
    
    func synthesizeVoice(_ text: String) {
        // Utiliser langue détectée ou par défaut
        let language = extractedText.first?.language ?? "en-US"
        voiceSynthesisService.speak(text, language: language) {
            // Completion handler
        }
    }
    
    // MARK: - Reset
    
    func reset() {
        selectedImage = nil
        analysisResult = nil
        extractedText = []
        segmentedPerson = nil
        customPrompt = ""
        context = ""
        analysisError = nil
    }
}










