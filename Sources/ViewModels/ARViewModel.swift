//
//  ARViewModel.swift
//  ARCodeClone
//
//  ViewModel pour la vue AR
//

import Foundation
import ARKit
import Combine

final class ARViewModel: BaseViewModel {
    private let arService: ARServiceProtocol
    private let planeDetectionService: PlaneDetectionService
    
    @Published var isARSessionRunning: Bool = false
    @Published var detectedPlanes: [ARPlaneAnchor] = []
    @Published var showDebugPlanes: Bool = false
    @Published var currentLighting: ARLightEstimate?
    @Published var errorMessage: String?
    
    init(arService: ARServiceProtocol) {
        self.arService = arService
        self.planeDetectionService = PlaneDetectionService()
        super.init()
        
        setupCallbacks()
    }
    
    private func setupCallbacks() {
        // Callback pour les plans détectés
        // Note: L'ARService devrait exposer ces callbacks
        // Pour l'instant, ceci est une structure de base
    }
    
    /// Démarre la session AR avec World Tracking
    func startARSession() {
        guard !isARSessionRunning else { return }
        
        do {
            let config = ARConfigurationFactory.createWorldTracking()
            try arService.startARSession(configuration: config)
            isARSessionRunning = true
        } catch {
            showError(error.localizedDescription)
        }
    }
    
    /// Arrête la session AR
    func stopARSession() {
        guard isARSessionRunning else { return }
        arService.stopARSession()
        isARSessionRunning = false
        detectedPlanes.removeAll()
    }
    
    /// Active/désactive la visualisation debug des plans
    func toggleDebugPlanes() {
        showDebugPlanes.toggle()
        planeDetectionService.setDebugVisualization(showDebugPlanes)
    }
    
    /// Obtient l'estimation de lumière actuelle
    func updateLighting() {
        currentLighting = arService.estimateLighting()
    }
    
    /// Obtient tous les plans détectés
    func refreshDetectedPlanes() {
        detectedPlanes = arService.detectPlanes()
    }
}













