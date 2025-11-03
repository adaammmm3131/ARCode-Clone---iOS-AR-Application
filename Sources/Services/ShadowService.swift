//
//  ShadowService.swift
//  ARCodeClone
//
//  Service pour les ombres dynamiques avec light probes
//

import ARKit
import SceneKit

final class ShadowService {
    private var shadowNodes: [UUID: SCNNode] = [:]
    
    /// Crée une lumière directionnelle avec ombres
    func createDirectionalLight(
        direction: SIMD3<Float>,
        color: UIColor = .white,
        intensity: CGFloat = 1000.0,
        castsShadow: Bool = true
    ) -> SCNNode {
        let light = SCNLight()
        light.type = .directional
        light.color = color
        light.intensity = intensity
        light.castsShadow = castsShadow
        
        // Configuration des ombres
        if castsShadow {
            light.shadowMode = .deferred
            light.shadowColor = UIColor.black.withAlphaComponent(0.3)
            light.shadowRadius = 5.0
            light.shadowSampleCount = 16
            light.shadowMapSize = CGSize(width: 2048, height: 2048)
        }
        
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(
            direction.x,
            direction.y,
            direction.z
        )
        
        // Orienter la lumière dans la direction spécifiée
        lightNode.look(at: SCNVector3(0, 0, 0))
        
        return lightNode
    }
    
    /// Crée une lumière basée sur ARLightEstimate avec ombres
    func createLightFromEstimate(_ lightEstimate: ARLightEstimate) -> SCNNode {
        let ambientIntensity = CGFloat(lightEstimate.ambientIntensity) / 1000.0
        let colorTemperature = CGFloat(lightEstimate.ambientColorTemperature)
        
        // Créer une lumière directionnelle estimée depuis l'éclairage ambiant
        let light = SCNLight()
        light.type = .directional
        light.intensity = ambientIntensity * 1000.0
        
        // Couleur basée sur la température
        let color = colorFromTemperature(colorTemperature)
        light.color = color
        
        // Activer les ombres
        light.castsShadow = true
        light.shadowMode = .deferred
        light.shadowRadius = 5.0
        light.shadowSampleCount = 16
        
        let lightNode = SCNNode()
        lightNode.light = light
        
        // Direction par défaut (peut être ajustée selon l'environnement)
        lightNode.position = SCNVector3(1, 3, 1)
        lightNode.look(at: SCNVector3(0, 0, 0))
        
        return lightNode
    }
    
    /// Configure une scène pour recevoir des ombres
    func configureSceneForShadows(_ scene: SCNScene) {
        // Activer le rendu des ombres
        scene.rootNode.castsShadow = true
        
        // Configurer le background pour les ombres
        scene.background.contents = UIColor.clear
        
        // Optimiser le rendu des ombres
        scene.rootNode.categoryBitMask = 1
    }
    
    /// Configure un nœud pour recevoir des ombres
    func configureNodeForShadows(_ node: SCNNode, receivesShadow: Bool = true) {
        node.castsShadow = true
        
        // Matériau pour recevoir les ombres
        if let geometry = node.geometry,
           let material = geometry.firstMaterial {
            material.lightingModel = .physicallyBased
            material.writesToDepthBuffer = receivesShadow
            material.readsFromDepthBuffer = receivesShadow
        }
    }
    
    /// Convertit une température de couleur en UIColor
    private func colorFromTemperature(_ temperature: CGFloat) -> UIColor {
        let temp = temperature / 100.0
        
        var red: CGFloat = 1.0
        var green: CGFloat = 1.0
        var blue: CGFloat = 1.0
        
        if temp <= 66 {
            red = 1.0
            green = max(0.0, min(1.0, 0.3900815787690196 * log(temp) - 0.631841443788627 * 0.5))
            blue = max(0.0, min(1.0, 0.543206789110196 * log(temp - 10) - 1.19625408914))
        } else {
            red = max(0.0, min(1.0, 1.292936186062745 * pow(temp - 60, -0.1332047592)))
            green = max(0.0, min(1.0, 1.129890860895294 * pow(temp - 60, -0.0755148492)))
            blue = 1.0
        }
        
        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
}













