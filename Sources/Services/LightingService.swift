//
//  LightingService.swift
//  ARCodeClone
//
//  Service d'estimation et d'application de l'éclairage AR
//

import ARKit
import SceneKit
import RealityKit

final class LightingService {
    private var currentLightEstimate: ARLightEstimate?
    private var environmentProbes: [UUID: AREnvironmentProbeAnchor] = [:]
    
    /// Met à jour l'estimation de lumière depuis une frame AR
    func updateLighting(from frame: ARFrame) {
        currentLightEstimate = frame.lightEstimate
    }
    
    /// Applique l'estimation de lumière à une scène SceneKit
    func applyLighting(to scene: SCNScene, lightEstimate: ARLightEstimate?) {
        guard let lightEstimate = lightEstimate else {
            // Fallback : éclairage par défaut
            scene.lightingEnvironment.intensity = 1.0
            return
        }
        
        // Appliquer l'intensité ambiante
        let ambientIntensity = lightEstimate.ambientIntensity
        scene.lightingEnvironment.intensity = CGFloat(ambientIntensity) / 1000.0
        
        // Appliquer la température de couleur
        let colorTemperature = lightEstimate.ambientColorTemperature
        let color = colorFromTemperature(colorTemperature)
        scene.lightingEnvironment.contents = color
        
        // Mettre à jour l'éclairage automatique
        scene.background.contents = UIColor.black // Fond noir pour AR
    }
    
    /// Applique l'estimation de lumière à un matériau SceneKit
    func applyLighting(to material: SCNMaterial, lightEstimate: ARLightEstimate?) {
        guard let lightEstimate = lightEstimate else { return }
        
        // Ajuster la luminosité du matériau selon l'intensité ambiante
        let ambientIntensity = lightEstimate.ambientIntensity
        let intensityFactor = CGFloat(ambientIntensity) / 1000.0
        
        // Ajuster la propriété lightingModel selon la température
        if material.lightingModel != .physicallyBased {
            material.lightingModel = .physicallyBased
        }
        
        // Modifier la métallicité et la rugosité pour meilleur rendu
        // Ces valeurs peuvent être ajustées selon l'environnement
    }
    
    /// Crée une sonde d'environnement pour IBL (Image-Based Lighting)
    func createEnvironmentProbe(at position: SIMD3<Float>, extent: SIMD3<Float>) -> AREnvironmentProbeAnchor {
        let probe = AREnvironmentProbeAnchor(
            name: "probe_\(UUID().uuidString)",
            transform: simd_float4x4(
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(position.x, position.y, position.z, 1)
            )
        )
        
        probe.extent = extent
        return probe
    }
    
    /// Ajoute une sonde d'environnement à la session AR
    func addEnvironmentProbe(_ probe: AREnvironmentProbeAnchor, to session: ARSession) {
        environmentProbes[probe.identifier] = probe
        session.add(anchor: probe)
    }
    
    /// Applique les probes d'environnement à une scène SceneKit
    func applyEnvironmentProbes(to scene: SCNScene, from anchors: [ARAnchor]) {
        let probes = anchors.compactMap { $0 as? AREnvironmentProbeAnchor }
        
        for probe in probes {
            // Convertir AREnvironmentProbeAnchor en SCNNode pour SceneKit
            let probeNode = SCNNode()
            probeNode.position = SCNVector3(
                probe.transform.columns.3.x,
                probe.transform.columns.3.y,
                probe.transform.columns.3.z
            )
            
            // Créer une light probe pour SceneKit
            let lightProbe = SCNLight()
            lightProbe.type = .probe
            
            // Utiliser les données de la probe ARKit
            if let environmentTexture = probe.environmentTexture {
                // Appliquer la texture d'environnement pour les reflections
                scene.lightingEnvironment.contents = environmentTexture
            }
        }
    }
    
    /// Obtient l'estimation de lumière actuelle
    func getCurrentLightEstimate() -> ARLightEstimate? {
        return currentLightEstimate
    }
    
    /// Convertit une température de couleur (Kelvin) en UIColor
    private func colorFromTemperature(_ temperature: CGFloat) -> UIColor {
        // Algorithme de conversion température → couleur RGB
        // Température typique : 2000K (chaud/rouge) à 10000K (froid/bleu)
        
        let temp = temperature / 100.0
        
        var red: CGFloat = 1.0
        var green: CGFloat = 1.0
        var blue: CGFloat = 1.0
        
        // Calcul simplifié de la température de couleur
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

// MARK: - RealityKit Support

extension LightingService {
    /// Applique l'estimation de lumière à une scène RealityKit
    func applyLighting(to view: ARView, lightEstimate: ARLightEstimate?) {
        guard let lightEstimate = lightEstimate else { return }
        
        // RealityKit applique automatiquement l'éclairage depuis ARFrame
        // Mais on peut ajuster manuellement si nécessaire
        
        let ambientIntensity = lightEstimate.ambientIntensity
        let intensity = Float(ambientIntensity) / 1000.0
        
        // Mettre à jour l'environment lighting de la vue
        // RealityKit gère cela automatiquement via ARFrame
    }
}

// MARK: - Helper Structures

struct LightingInfo {
    let ambientIntensity: CGFloat
    let colorTemperature: CGFloat
    let timestamp: Date
    
    init(from lightEstimate: ARLightEstimate) {
        self.ambientIntensity = CGFloat(lightEstimate.ambientIntensity)
        self.colorTemperature = CGFloat(lightEstimate.ambientColorTemperature)
        self.timestamp = Date()
    }
}













