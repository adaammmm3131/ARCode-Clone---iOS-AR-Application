//
//  ARPortalTransitionService.swift
//  ARCodeClone
//
//  Service pour transition smooth réalité → 360° et traversée portal
//

import Foundation
import ARKit
import SceneKit
import UIKit

protocol ARPortalTransitionServiceProtocol {
    func createPortalEffect(portalNode: SCNNode, scene: SCNScene)
    func animateTransition(to immersive: Bool, duration: TimeInterval, completion: @escaping () -> Void)
    func createHotspot(at position: SIMD3<Float>, in scene: SCNScene, action: @escaping () -> Void) -> SCNNode
}

enum PortalTransitionState {
    case reality
    case transitioning
    case immersive
}

final class ARPortalTransitionService: ARPortalTransitionServiceProtocol {
    private var transitionState: PortalTransitionState = .reality
    private var hotspotNodes: [UUID: SCNNode] = [:]
    
    // MARK: - Portal Effect Creation
    
    func createPortalEffect(portalNode: SCNNode, scene: SCNScene) {
        // Créer effet visuel de portal (ex: distorsion, bordure, animation)
        
        // Optionnel: Ajouter bordure portal
        let portalFrame = createPortalFrame(radius: 1.0)
        portalFrame.simdPosition = portalNode.simdPosition
        scene.rootNode.addChildNode(portalFrame)
        
        // Optionnel: Animation portal (pulsation, rotation)
        let pulseAction = SCNAction.sequence([
            SCNAction.scale(to: 1.1, duration: 1.0),
            SCNAction.scale(to: 1.0, duration: 1.0)
        ])
        let repeatAction = SCNAction.repeatForever(pulseAction)
        portalNode.runAction(repeatAction, forKey: "portalPulse")
    }
    
    // MARK: - Transition Animation
    
    func animateTransition(to immersive: Bool, duration: TimeInterval, completion: @escaping () -> Void) {
        transitionState = .transitioning
        
        // Animation fade pour transition smooth
        let fadeAction = SCNAction.fadeOut(duration: duration / 2)
        
        // Après fade, changer état et fade in
        DispatchQueue.main.asyncAfter(deadline: .now() + duration / 2) { [weak self] in
            self?.transitionState = immersive ? .immersive : .reality
            
            // Fade in nouvelle scène
            let fadeInAction = SCNAction.fadeIn(duration: duration / 2)
            
            // Complétion
            DispatchQueue.main.asyncAfter(deadline: .now() + duration / 2) {
                completion()
            }
        }
    }
    
    // MARK: - Hotspot Creation
    
    func createHotspot(at position: SIMD3<Float>, in scene: SCNScene, action: @escaping () -> Void) -> SCNNode {
        // Créer hotspot interactif (icône, bouton 3D)
        let hotspotSphere = SCNSphere(radius: 0.05) // 5cm radius
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.systemBlue.withAlphaComponent(0.7)
        material.emission.contents = UIColor.systemBlue
        material.emission.intensity = 0.5
        
        hotspotSphere.materials = [material]
        
        let hotspotNode = SCNNode(geometry: hotspotSphere)
        hotspotNode.simdPosition = position
        hotspotNode.name = "hotspot_\(UUID().uuidString)"
        
        // Animation pulse
        let pulseAction = SCNAction.sequence([
            SCNAction.scale(to: 1.3, duration: 0.5),
            SCNAction.scale(to: 1.0, duration: 0.5)
        ])
        let repeatAction = SCNAction.repeatForever(pulseAction)
        hotspotNode.runAction(repeatAction)
        
        // Enregistrer pour interaction
        let id = UUID()
        hotspotNodes[id] = hotspotNode
        
        scene.rootNode.addChildNode(hotspotNode)
        
        return hotspotNode
    }
    
    // MARK: - Helper Methods
    
    private func createPortalFrame(radius: Float) -> SCNNode {
        // Créer frame/anneau pour portal
        let torus = SCNTorus(ringRadius: CGFloat(radius), pipeRadius: 0.05)
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white
        material.emission.contents = UIColor.cyan
        material.emission.intensity = 0.8
        
        torus.materials = [material]
        
        let frameNode = SCNNode(geometry: torus)
        frameNode.name = "portalFrame"
        
        return frameNode
    }
    
    func getTransitionState() -> PortalTransitionState {
        return transitionState
    }
    
    func removeHotspot(_ hotspotId: UUID) {
        hotspotNodes[hotspotId]?.removeFromParentNode()
        hotspotNodes.removeValue(forKey: hotspotId)
    }
}










