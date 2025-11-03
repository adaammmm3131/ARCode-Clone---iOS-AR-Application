//
//  ARSplatViewModel.swift
//  ARCodeClone
//
//  ViewModel pour AR Splat
//

import Foundation
import SwiftUI
import Combine
import ARKit
import SceneKit
import AVFoundation

final class ARSplatViewModel: BaseViewModel, ObservableObject {
    @Published var selectedVideoURL: URL?
    @Published var previewFrames: [UIImage] = []
    @Published var processingJobId: String?
    @Published var processingStatus: ProcessingStatus?
    @Published var processingProgress: Float = 0.0
    @Published var processingMessage: String = ""
    @Published var resultSplatURL: URL?
    @Published var currentSplatNode: SCNNode?
    @Published var isLoading: Bool = false
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?
    
    private let uploadService: ARSplatUploadServiceProtocol
    private let processingService: ARSplatProcessingServiceProtocol
    private let viewerService: ARSplatViewerServiceProtocol
    private var progressCancellable: AnyCancellable?
    
    // Exposer pour access depuis View
    var exposedProcessingService: ARSplatProcessingServiceProtocol {
        return processingService
    }
    
    var exposedUploadService: ARSplatUploadServiceProtocol {
        return uploadService
    }
    
    init(
        uploadService: ARSplatUploadServiceProtocol,
        processingService: ARSplatProcessingServiceProtocol,
        viewerService: ARSplatViewerServiceProtocol
    ) {
        self.uploadService = uploadService
        self.processingService = processingService
        self.viewerService = viewerService
        super.init()
    }
    
    // MARK: - Video Selection
    
    func loadVideo(url: URL) {
        isLoading = true
        errorMessage = nil
        selectedVideoURL = url
        
        // Valider vidéo
        let validation = uploadService.validateVideo(url: url)
        guard validation.isValid else {
            errorMessage = validation.errorMessage ?? "Vidéo invalide"
            isLoading = false
            selectedVideoURL = nil
            previewFrames = []
            return
        }
        
        // Extraire frames preview
        uploadService.extractPreviewFrames(from: url, count: 6) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let frames):
                    self?.previewFrames = frames
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Processing
    
    func submitForProcessing() {
        guard let videoURL = selectedVideoURL else {
            errorMessage = "Aucune vidéo sélectionnée"
            return
        }
        
        isProcessing = true
        processingProgress = 0.0
        processingMessage = "Soumission..."
        
        // Soumettre vidéo
        let jobId = processingService.submitVideo(videoURL) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.processingJobId = jobId
                    self?.startProgressMonitoring(jobId: jobId)
                    
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    self?.isProcessing = false
                }
            }
        }
    }
    
    // MARK: - Progress Monitoring
    
    private func startProgressMonitoring(jobId: String) {
        // S'abonner aux updates de progression
        progressCancellable = processingService.subscribeToProgress(jobId: jobId)
            .sink { [weak self] progress in
                DispatchQueue.main.async {
                    self?.processingProgress = progress.progress
                    self?.processingMessage = progress.message
                    
                    // Mettre à jour status
                    self?.processingService.getProcessingStatus(jobId: jobId) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let status):
                                self?.processingStatus = status
                                
                                if status.status == .completed {
                                    self?.isProcessing = false
                                    if let resultURLString = status.resultURL,
                                       let resultURL = URL(string: resultURLString) {
                                        self?.resultSplatURL = resultURL
                                    }
                                } else if status.status == .failed {
                                    self?.isProcessing = false
                                    self?.errorMessage = status.error ?? "Échec traitement"
                                }
                                
                            case .failure:
                                break
                            }
                        }
                    }
                }
            }
    }
    
    // MARK: - Splat Loading
    
    func loadSplatFile(url: URL, in scene: SCNScene, at position: SIMD3<Float>) {
        isLoading = true
        errorMessage = nil
        
        viewerService.loadSplatFile(url: url) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let node):
                    // Placer dans scène
                    self?.viewerService.placeSplatNode(node, at: position, in: scene)
                    
                    // Optimiser performance
                    self?.viewerService.optimizeForPerformance(node, targetFPS: 60)
                    
                    self?.currentSplatNode = node
                    
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        progressCancellable?.cancel()
        progressCancellable = nil
        
        if let node = currentSplatNode {
            node.removeFromParentNode()
        }
        currentSplatNode = nil
    }
}

