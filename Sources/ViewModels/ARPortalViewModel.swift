//
//  ARPortalViewModel.swift
//  ARCodeClone
//
//  ViewModel pour AR Portal
//

import Foundation
import SwiftUI
import Combine
import ARKit
import SceneKit
import UIKit
import CoreMotion

final class ARPortalViewModel: BaseViewModel, ObservableObject {
    @Published var portalNode: SCNNode?
    @Published var isImmersive: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedMediaURL: URL?
    @Published var useGyroscope: Bool = true
    @Published var transitionState: PortalTransitionState = .reality
    
    private let arService: ARServiceProtocol
    private let portalService: ARPortalServiceProtocol
    private let controlsService: ARPortalControlsServiceProtocol
    private let formatService: ARPortalFormatServiceProtocol
    private let transitionService: ARPortalTransitionServiceProtocol
    
    private var portalId: UUID?
    private var cameraNode: SCNNode?
    
    init(
        arService: ARServiceProtocol,
        portalService: ARPortalServiceProtocol,
        controlsService: ARPortalControlsServiceProtocol,
        formatService: ARPortalFormatServiceProtocol,
        transitionService: ARPortalTransitionServiceProtocol
    ) {
        self.arService = arService
        self.portalService = portalService
        self.controlsService = controlsService
        self.formatService = formatService
        self.transitionService = transitionService
        super.init()
    }
    
    // MARK: - Portal Loading
    
    func loadPortal(url: URL, in scene: SCNScene, at position: SIMD3<Float>) {
        isLoading = true
        errorMessage = nil
        selectedMediaURL = url
        
        // Valider format
        let validation = formatService.validateEquirectangularImage(url: url)
        guard validation.isValid else {
            errorMessage = validation.errorMessage ?? "Format invalide"
            isLoading = false
            return
        }
        
        // Créer sphère portal
        let portal = portalService.createPortalSphere(radius: 10.0)
        
        // Charger texture
        portalService.loadEquirectangularTexture(url: url) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let texture):
                    // Appliquer texture
                    self?.portalService.applyTextureToSphere(texture, sphere: portal)
                    
                    // Placer portal
                    self?.portalService.placePortal(portal, at: position, in: scene)
                    self?.portalNode = portal
                    
                    // Créer effet portal
                    self?.transitionService.createPortalEffect(portalNode: portal, scene: scene)
                    
                    // Enregistrer
                    if let service = self?.portalService as? ARPortalService {
                        let id = service.registerPortal(portal)
                        self?.portalId = id
                    }
                    
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Immersion Controls
    
    func enterImmersiveMode() {
        guard !isImmersive else { return }
        
        transitionService.animateTransition(to: true, duration: 1.0) { [weak self] in
            self?.isImmersive = true
            self?.transitionState = .immersive
        }
    }
    
    func exitImmersiveMode() {
        guard isImmersive else { return }
        
        transitionService.animateTransition(to: false, duration: 1.0) { [weak self] in
            self?.isImmersive = false
            self?.transitionState = .reality
        }
    }
    
    // MARK: - Controls Setup
    
    func setupControls(on view: UIView, cameraNode: SCNNode) {
        self.cameraNode = cameraNode
        
        // Setup touch controls
        controlsService.setupTouchControls(on: view, cameraNode: cameraNode)
        
        // Setup gyroscope si activé
        if useGyroscope {
            controlsService.startGyroscopeTracking { [weak self] rotationMatrix in
                guard let self = self,
                      let cameraNode = self.cameraNode else { return }
                
                // Convertir rotation matrix en Euler angles
                let eulerAngles = self.controlsService.rotationMatrixToEulerAngles(rotationMatrix)
                cameraNode.eulerAngles = eulerAngles
            }
        }
    }
    
    func removeControls(from view: UIView) {
        controlsService.removeTouchControls(from: view)
        controlsService.stopGyroscopeTracking()
        cameraNode = nil
    }
    
    // MARK: - Hotspot Management
    
    func addHotspot(at position: SIMD3<Float>, in scene: SCNScene, action: @escaping () -> Void) {
        transitionService.createHotspot(at: position, in: scene, action: action)
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        if let portalId = portalId,
           let service = portalService as? ARPortalService {
            service.removePortal(portalId)
        }
        portalNode = nil
        cameraNode = nil
    }
}

