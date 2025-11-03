//
//  ARLogo3DExtrusionService.swift
//  ARCodeClone
//
//  Service pour conversion SVG → path 2D → extrusion 3D
//

import Foundation
import ARKit
import SceneKit
import UIKit
import CoreGraphics

protocol ARLogo3DExtrusionServiceProtocol {
    func createLogo3D(from svgData: Data, depth: Float, material: SCNMaterial?) -> SCNNode?
    func updateDepth(_ node: SCNNode, newDepth: Float)
    func applyMaterial(_ node: SCNNode, material: SCNMaterial)
    func createPBRMaterial(color: UIColor, metalness: Float, roughness: Float) -> SCNMaterial
}

enum ARLogo3DExtrusionError: LocalizedError {
    case svgParseFailed
    case pathCreationFailed
    case extrusionFailed
    
    var errorDescription: String? {
        switch self {
        case .svgParseFailed:
            return "Échec parsing SVG"
        case .pathCreationFailed:
            return "Échec création path 2D"
        case .extrusionFailed:
            return "Échec extrusion 3D"
        }
    }
}

final class ARLogo3DExtrusionService: ARLogo3DExtrusionServiceProtocol {
    
    // MARK: - Logo 3D Creation
    
    func createLogo3D(from svgData: Data, depth: Float, material: SCNMaterial?) -> SCNNode? {
        // Étape 1: Parser SVG et extraire paths
        guard let paths = parseSVGToPaths(svgData: svgData) else {
            return nil
        }
        
        // Étape 2: Créer node container
        let containerNode = SCNNode()
        containerNode.name = "arLogo_\(UUID().uuidString)"
        
        // Étape 3: Créer extrusion pour chaque path
        for (index, path) in paths.enumerated() {
            if let extrudedNode = createExtrudedNode(path: path, depth: depth, material: material) {
                extrudedNode.name = "logoPath_\(index)"
                containerNode.addChildNode(extrudedNode)
            }
        }
        
        // Étape 4: Centrer et normaliser
        normalizeAndCenter(containerNode)
        
        return containerNode
    }
    
    // MARK: - SVG Parsing
    
    private func parseSVGToPaths(svgData: Data) -> [UIBezierPath]? {
        guard let svgString = String(data: svgData, encoding: .utf8) else {
            return nil
        }
        
        // Parser SVG basique pour extraire paths
        // Format SVG path: d="M 10 10 L 20 20 ..."
        var paths: [UIBezierPath] = []
        
        // Chercher tous les éléments <path d="...">
        let pathPattern = #"<path[^>]*d\s*=\s*["']([^"']+)["']"#
        let regex = try? NSRegularExpression(pattern: pathPattern, options: [])
        let nsString = svgString as NSString
        let matches = regex?.matches(in: svgString, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in matches ?? [] {
            if match.numberOfRanges > 1 {
                let pathData = nsString.substring(with: match.range(at: 1))
                if let bezierPath = parseSVGPathData(pathData) {
                    paths.append(bezierPath)
                }
            }
        }
        
        // Si pas de paths, chercher autres formes (rect, circle, etc.)
        if paths.isEmpty {
            // Parser rectangles
            let rectPattern = #"<rect[^>]*x\s*=\s*["']([\d.]+)["'][^>]*y\s*=\s*["']([\d.]+)["'][^>]*width\s*=\s*["']([\d.]+)["'][^>]*height\s*=\s*["']([\d.]+)["']"#
            let rectRegex = try? NSRegularExpression(pattern: rectPattern, options: [])
            let rectMatches = rectRegex?.matches(in: svgString, options: [], range: NSRange(location: 0, length: nsString.length))
            
            for match in rectMatches ?? [] {
                if match.numberOfRanges >= 5 {
                    let x = CGFloat(Double(nsString.substring(with: match.range(at: 1))) ?? 0)
                    let y = CGFloat(Double(nsString.substring(with: match.range(at: 2))) ?? 0)
                    let width = CGFloat(Double(nsString.substring(with: match.range(at: 3))) ?? 0)
                    let height = CGFloat(Double(nsString.substring(with: match.range(at: 4))) ?? 0)
                    
                    let rect = UIBezierPath(rect: CGRect(x: x, y: y, width: width, height: height))
                    paths.append(rect)
                }
            }
            
            // Parser cercles
            let circlePattern = #"<circle[^>]*cx\s*=\s*["']([\d.]+)["'][^>]*cy\s*=\s*["']([\d.]+)["'][^>]*r\s*=\s*["']([\d.]+)["']"#
            let circleRegex = try? NSRegularExpression(pattern: circlePattern, options: [])
            let circleMatches = circleRegex?.matches(in: svgString, options: [], range: NSRange(location: 0, length: nsString.length))
            
            for match in circleMatches ?? [] {
                if match.numberOfRanges >= 4 {
                    let cx = CGFloat(Double(nsString.substring(with: match.range(at: 1))) ?? 0)
                    let cy = CGFloat(Double(nsString.substring(with: match.range(at: 2))) ?? 0)
                    let r = CGFloat(Double(nsString.substring(with: match.range(at: 3))) ?? 0)
                    
                    let circle = UIBezierPath(arcCenter: CGPoint(x: cx, y: cy), radius: r, startAngle: 0, endAngle: .pi * 2, clockwise: true)
                    paths.append(circle)
                }
            }
        }
        
        return paths.isEmpty ? nil : paths
    }
    
    // MARK: - SVG Path Data Parsing
    
    private func parseSVGPathData(_ pathData: String) -> UIBezierPath? {
        // Parser SVG path commands (M, L, C, Q, Z, etc.)
        // Version simplifiée - utiliser CGPath pour parsing natif si possible
        
        // Pour l'instant, création path basique
        // En production, utiliser une bibliothèque complète ou parser complet
        let path = UIBezierPath()
        
        // Tokeniser path data
        let commands = pathData.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        var index = 0
        
        while index < commands.count {
            let command = commands[index]
            index += 1
            
            switch command.uppercased() {
            case "M": // Move to
                if index + 1 < commands.count {
                    let x = CGFloat(Double(commands[index]) ?? 0)
                    let y = CGFloat(Double(commands[index + 1]) ?? 0)
                    path.move(to: CGPoint(x: x, y: y))
                    index += 2
                }
            case "L": // Line to
                if index + 1 < commands.count {
                    let x = CGFloat(Double(commands[index]) ?? 0)
                    let y = CGFloat(Double(commands[index + 1]) ?? 0)
                    path.addLine(to: CGPoint(x: x, y: y))
                    index += 2
                }
            case "Z", "z": // Close path
                path.close()
            case "C": // Cubic bezier
                if index + 5 < commands.count {
                    let cp1x = CGFloat(Double(commands[index]) ?? 0)
                    let cp1y = CGFloat(Double(commands[index + 1]) ?? 0)
                    let cp2x = CGFloat(Double(commands[index + 2]) ?? 0)
                    let cp2y = CGFloat(Double(commands[index + 3]) ?? 0)
                    let endx = CGFloat(Double(commands[index + 4]) ?? 0)
                    let endy = CGFloat(Double(commands[index + 5]) ?? 0)
                    path.addCurve(to: CGPoint(x: endx, y: endy), controlPoint1: CGPoint(x: cp1x, y: cp1y), controlPoint2: CGPoint(x: cp2x, y: cp2y))
                    index += 6
                }
            case "Q": // Quadratic bezier
                if index + 3 < commands.count {
                    let cpx = CGFloat(Double(commands[index]) ?? 0)
                    let cpy = CGFloat(Double(commands[index + 1]) ?? 0)
                    let endx = CGFloat(Double(commands[index + 2]) ?? 0)
                    let endy = CGFloat(Double(commands[index + 3]) ?? 0)
                    path.addQuadCurve(to: CGPoint(x: endx, y: endy), controlPoint: CGPoint(x: cpx, y: cpy))
                    index += 4
                }
            default:
                // Ignorer commandes non supportées
                break
            }
        }
        
        return path.isEmpty ? nil : path
    }
    
    // MARK: - Extrusion
    
    private func createExtrudedNode(path: UIBezierPath, depth: Float, material: SCNMaterial?) -> SCNNode? {
        // Créer SCNShape avec extrusion
        // Note: SCNShape nécessite un path fermé
        
        guard !path.isEmpty else {
            return nil
        }
        
        // S'assurer que le path est fermé
        if !path.isClosed {
            path.close()
        }
        
        // Créer geometry d'extrusion
        let shape = SCNShape(path: path, extrusionDepth: CGFloat(depth))
        
        // Appliquer matériau
        if let mat = material {
            shape.materials = [mat]
        } else {
            // Matériau par défaut
            let defaultMaterial = createPBRMaterial(color: .white, metalness: 0.5, roughness: 0.5)
            shape.materials = [defaultMaterial]
        }
        
        // Créer node
        let node = SCNNode(geometry: shape)
        
        return node
    }
    
    // MARK: - Normalization
    
    private func normalizeAndCenter(_ node: SCNNode) {
        // Calculer bounding box de tous les enfants
        var minBounds = SIMD3<Float>(Float.infinity, Float.infinity, Float.infinity)
        var maxBounds = SIMD3<Float>(-Float.infinity, -Float.infinity, -Float.infinity)
        
        node.enumerateChildNodes { child, _ in
            if let geometry = child.geometry {
                let (min, max) = geometry.boundingBox
                minBounds = SIMD3<Float>(min(minBounds.x, min.x), min(minBounds.y, min.y), min(minBounds.z, min.z))
                maxBounds = SIMD3<Float>(max(maxBounds.x, max.x), max(maxBounds.y, max.y), max(maxBounds.z, max.z))
            }
        }
        
        // Centrer
        let center = (minBounds + maxBounds) / 2
        node.simdPosition = -center
        
        // Normaliser taille (max dimension = 1 mètre)
        let size = maxBounds - minBounds
        let maxSize = max(size.x, max(size.y, size.z)
        if maxSize > 1.0 {
            let scale = 1.0 / maxSize
            node.simdScale = SIMD3<Float>(scale, scale, scale)
        }
    }
    
    // MARK: - Depth Update
    
    func updateDepth(_ node: SCNNode, newDepth: Float) {
        node.enumerateChildNodes { child, _ in
            if let shape = child.geometry as? SCNShape {
                // Mettre à jour extrusion depth
                // Note: SCNShape ne permet pas de modifier extrusionDepth directement
                // Nécessite recréer geometry
                if let path = shape.path {
                    let newShape = SCNShape(path: path, extrusionDepth: CGFloat(newDepth))
                    newShape.materials = shape.materials
                    child.geometry = newShape
                }
            }
        }
    }
    
    // MARK: - Material Management
    
    func applyMaterial(_ node: SCNNode, material: SCNMaterial) {
        node.enumerateChildNodes { child, _ in
            if let geometry = child.geometry {
                geometry.materials = [material]
            }
        }
    }
    
    // MARK: - PBR Material Creation
    
    func createPBRMaterial(color: UIColor, metalness: Float, roughness: Float) -> SCNMaterial {
        let material = SCNMaterial()
        
        // PBR properties
        material.lightingModel = .physicallyBased
        material.diffuse.contents = color
        material.metalness.contents = metalness
        material.roughness.contents = roughness
        
        // Options supplémentaires
        material.isDoubleSided = false
        
        return material
    }
}









