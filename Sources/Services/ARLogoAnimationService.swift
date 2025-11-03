//
//  ARLogoAnimationService.swift
//  ARCodeClone
//
//  Service pour animations logo AR (rotation 360° loop)
//

import Foundation
import ARKit
import SceneKit

protocol ARLogoAnimationServiceProtocol {
    func startRotationAnimation(node: SCNNode, speed: Float, easing: AnimationEasing)
    func stopRotationAnimation(node: SCNNode)
    func setRotationSpeed(node: SCNNode, speed: Float)
    func exportWithAnimation(_ node: SCNNode, includeAnimation: Bool) -> SCNNode
}

enum AnimationEasing: String, CaseIterable {
    case linear = "Linear"
    case easeIn = "Ease In"
    case easeOut = "Ease Out"
    case easeInOut = "Ease In Out"
    
    var timingFunction: CAMediaTimingFunction {
        switch self {
        case .linear:
            return CAMediaTimingFunction(name: .linear)
        case .easeIn:
            return CAMediaTimingFunction(name: .easeIn)
        case .easeOut:
            return CAMediaTimingFunction(name: .easeOut)
        case .easeInOut:
            return CAMediaTimingFunction(name: .easeInOut)
        }
    }
}

final class ARLogoAnimationService: ARLogoAnimationServiceProtocol {
    private var animatedNodes: [UUID: SCNNode] = [:]
    
    // MARK: - Rotation Animation
    
    func startRotationAnimation(node: SCNNode, speed: Float, easing: AnimationEasing) {
        // Arrêter animation existante si présente
        stopRotationAnimation(node: node)
        
        // Durée basée sur speed (1.0 = 10 secondes pour 360°, plus rapide = moins de secondes)
        let duration = Double(10.0 / max(speed, 0.1))
        
        // Créer action de rotation Y-axis
        let rotateAction = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: duration)
        
        // Appliquer easing
        let easingAction: SCNAction
        switch easing {
        case .linear:
            easingAction = rotateAction
        case .easeIn:
            easingAction = rotateAction.easeIn(easeType: .easeIn)
        case .easeOut:
            easingAction = rotateAction.easeOut(easeType: .easeOut)
        case .easeInOut:
            easingAction = rotateAction.easeInOut(easeType: .easeInOut)
        }
        
        // Répéter infiniment
        let repeatAction = SCNAction.repeatForever(easingAction)
        
        // Exécuter action
        node.runAction(repeatAction, forKey: "rotationAnimation")
        
        // Enregistrer node animé
        if let nodeId = getNodeId(node) {
            animatedNodes[nodeId] = node
        }
    }
    
    func stopRotationAnimation(node: SCNNode) {
        node.removeAction(forKey: "rotationAnimation")
        
        // Retirer de liste animés
        if let nodeId = getNodeId(node) {
            animatedNodes.removeValue(forKey: nodeId)
        }
    }
    
    func setRotationSpeed(node: SCNNode, speed: Float) {
        // Arrêter animation actuelle
        stopRotationAnimation(node: node)
        
        // Démarrer nouvelle animation avec nouvelle vitesse
        // Utiliser easing par défaut (easeInOut)
        startRotationAnimation(node: node, speed: speed, easing: .easeInOut)
    }
    
    // MARK: - Export
    
    func exportWithAnimation(_ node: SCNNode, includeAnimation: Bool) -> SCNNode {
        if includeAnimation {
            // Créer copie avec animation
            let exportedNode = node.clone()
            
            // Copier animation si présente
            if node.hasActions && includeAnimation {
                // Les actions seront copiées avec clone()
                // S'assurer que l'animation est active
            }
            
            return exportedNode
        } else {
            // Créer copie sans animation
            let exportedNode = node.clone()
            exportedNode.removeAllActions()
            return exportedNode
        }
    }
    
    // MARK: - Helper Methods
    
    private func getNodeId(_ node: SCNNode) -> UUID? {
        // Extraire UUID depuis node name ou créer un
        if let name = node.name,
           name.contains("arLogo_"),
           let idString = name.components(separatedBy: "_").last,
           let uuid = UUID(uuidString: idString) {
            return uuid
        }
        
        // Créer nouvel ID si nécessaire
        let newId = UUID()
        if node.name == nil {
            node.name = "arLogo_\(newId.uuidString)"
        }
        return newId
    }
    
    // MARK: - Advanced Animation Options
    
    func createBounceAnimation(node: SCNNode, height: Float, duration: Double) {
        let bounceUp = SCNAction.moveBy(x: 0, y: CGFloat(height), z: 0, duration: duration / 2)
        let bounceDown = SCNAction.moveBy(x: 0, y: -CGFloat(height), z: 0, duration: duration / 2)
        let bounce = SCNAction.sequence([bounceUp, bounceDown])
        let repeatBounce = SCNAction.repeatForever(bounce)
        
        node.runAction(repeatBounce, forKey: "bounceAnimation")
    }
    
    func createPulseAnimation(node: SCNNode, scale: Float, duration: Double) {
        let scaleUp = SCNAction.scale(to: CGFloat(scale), duration: duration / 2)
        let scaleDown = SCNAction.scale(to: 1.0, duration: duration / 2)
        let pulse = SCNAction.sequence([scaleUp, scaleDown])
        let repeatPulse = SCNAction.repeatForever(pulse)
        
        node.runAction(repeatPulse, forKey: "pulseAnimation")
    }
    
    func removeAllAnimations(node: SCNNode) {
        node.removeAllActions()
        
        if let nodeId = getNodeId(node) {
            animatedNodes.removeValue(forKey: nodeId)
        }
    }
}









