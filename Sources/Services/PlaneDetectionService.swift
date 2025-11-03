//
//  PlaneDetectionService.swift
//  ARCodeClone
//
//  Service de détection de plans avec visualisation
//

import ARKit
import SceneKit

final class PlaneDetectionService {
    private var planeNodes: [UUID: SCNNode] = [:]
    private var showDebugVisualization: Bool = false
    
    /// Active/désactive la visualisation debug
    func setDebugVisualization(_ enabled: Bool) {
        showDebugVisualization = enabled
    }
    
    /// Crée un nœud de visualisation pour un plan
    func createPlaneNode(for anchor: ARPlaneAnchor) -> SCNNode? {
        guard showDebugVisualization else { return nil }
        
        // Créer une géométrie plane
        let plane = SCNPlane(
            width: CGFloat(anchor.planeExtent.width),
            height: CGFloat(anchor.planeExtent.height)
        )
        
        // Matériau semi-transparent
        let material = SCNMaterial()
        material.diffuse.contents = planeColor(for: anchor.alignment)
        material.transparency = 0.5
        material.isDoubleSided = true
        plane.materials = [material]
        
        // Créer le nœud
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3(
            anchor.center.x,
            anchor.center.y,
            anchor.center.z
        )
        
        // Rotation selon l'orientation du plan
        if anchor.alignment == .vertical {
            // Plan vertical : rotation de 90° autour de l'axe X
            planeNode.eulerAngles.x = -.pi / 2
        }
        
        // Identifier le nœud
        planeNode.name = "plane_\(anchor.identifier.uuidString)"
        
        return planeNode
    }
    
    /// Met à jour le nœud de visualisation d'un plan
    func updatePlaneNode(_ node: SCNNode, for anchor: ARPlaneAnchor) {
        guard let plane = node.geometry as? SCNPlane else { return }
        
        // Mettre à jour les dimensions
        plane.width = CGFloat(anchor.planeExtent.width)
        plane.height = CGFloat(anchor.planeExtent.height)
        
        // Mettre à jour la position
        node.position = SCNVector3(
            anchor.center.x,
            anchor.center.y,
            anchor.center.z
        )
        
        // Mettre à jour la couleur si nécessaire
        if let material = plane.materials.first {
            material.diffuse.contents = planeColor(for: anchor.alignment)
        }
    }
    
    /// Supprime le nœud de visualisation d'un plan
    func removePlaneNode(for identifier: UUID) {
        planeNodes.removeValue(forKey: identifier)
    }
    
    /// Obtient tous les plans détectés
    func getAllPlanes() -> [SCNNode] {
        return Array(planeNodes.values)
    }
    
    /// Obtient les plans horizontaux
    func getHorizontalPlanes() -> [SCNNode] {
        return planeNodes.values.filter { node in
            guard let name = node.name, name.contains("plane_") else { return false }
            // TODO: Vérifier l'alignement depuis l'anchor original
            return true
        }
    }
    
    /// Obtient les plans verticaux
    func getVerticalPlanes() -> [SCNNode] {
        return planeNodes.values.filter { node in
            guard let name = node.name, name.contains("plane_") else { return false }
            // TODO: Vérifier l'alignement depuis l'anchor original
            return true
        }
    }
    
    /// Couleur du plan selon son alignement
    private func planeColor(for alignment: ARPlaneAnchor.Alignment) -> UIColor {
        switch alignment {
        case .horizontal:
            return UIColor.systemBlue.withAlphaComponent(0.5)
        case .vertical:
            return UIColor.systemGreen.withAlphaComponent(0.5)
        @unknown default:
            return UIColor.systemGray.withAlphaComponent(0.5)
        }
    }
}

// MARK: - ARPlaneAnchor Extensions

extension ARPlaneAnchor {
    /// Type de plan (horizontal ou vertical)
    var planeType: PlaneType {
        switch alignment {
        case .horizontal:
            return .horizontal
        case .vertical:
            return .vertical
        @unknown default:
            return .unknown
        }
    }
}

enum PlaneType {
    case horizontal
    case vertical
    case unknown
}













