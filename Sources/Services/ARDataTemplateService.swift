//
//  ARDataTemplateService.swift
//  ARCodeClone
//
//  Service pour templates de données dynamiques AR
//

import Foundation
import ARKit
import SceneKit

protocol ARDataTemplateServiceProtocol {
    func createIOTDataDisplay(data: ARDataResponse, in scene: SCNScene, at position: SIMD3<Float>) -> SCNNode
    func createLivePricingDisplay(data: ARDataResponse, in scene: SCNScene, at position: SIMD3<Float>) -> SCNNode
    func createMemberCardDisplay(data: ARDataResponse, in scene: SCNScene, at position: SIMD3<Float>) -> SCNNode
    func createGenericDisplay(data: ARDataResponse, template: DataTemplate, in scene: SCNScene, at position: SIMD3<Float>) -> SCNNode
}

enum DataTemplate: String, CaseIterable {
    case iot = "IoT Data"
    case pricing = "Live Pricing"
    case memberCard = "Member Card"
    case generic = "Generic"
    
    var id: String { self.rawValue }
}

final class ARDataTemplateService: ARDataTemplateServiceProtocol {
    
    // MARK: - IoT Data Display
    
    func createIOTDataDisplay(data: ARDataResponse, in scene: SCNScene, at position: SIMD3<Float>) -> SCNNode {
        let containerNode = SCNNode()
        containerNode.name = "iotDataDisplay_\(UUID().uuidString)"
        containerNode.simdPosition = position
        
        // Créer panel background
        let panel = createPanel(width: 0.4, height: 0.3, color: UIColor(white: 0.1, alpha: 0.9))
        containerNode.addChildNode(panel)
        
        // Créer titre
        let titleNode = createText3D(text: "IoT Data", size: 0.03, color: .white)
        titleNode.position = SCNVector3(0, 0.12, 0.001)
        containerNode.addChildNode(titleNode)
        
        // Créer données (température, humidité, etc.)
        var yOffset: Float = 0.08
        for (key, value) in data.data.sorted(by: { $0.key < $1.key }) {
            let labelText = "\(key): \(formatValue(value))"
            let labelNode = createText3D(text: labelText, size: 0.02, color: .cyan)
            labelNode.position = SCNVector3(-0.15, yOffset, 0.001)
            containerNode.addChildNode(labelNode)
            yOffset -= 0.04
        }
        
        // Timestamp
        let timestampText = formatDate(data.timestamp)
        let timestampNode = createText3D(text: timestampText, size: 0.015, color: .gray)
        timestampNode.position = SCNVector3(0, -0.14, 0.001)
        containerNode.addChildNode(timestampNode)
        
        scene.rootNode.addChildNode(containerNode)
        return containerNode
    }
    
    // MARK: - Live Pricing Display
    
    func createLivePricingDisplay(data: ARDataResponse, in scene: SCNScene, at position: SIMD3<Float>) -> SCNNode {
        let containerNode = SCNNode()
        containerNode.name = "pricingDisplay_\(UUID().uuidString)"
        containerNode.simdPosition = position
        
        // Panel principal
        let panel = createPanel(width: 0.5, height: 0.4, color: UIColor(white: 0.1, alpha: 0.95))
        containerNode.addChildNode(panel)
        
        // Titre produit
        if let productName = data.data["product_name"] as? String ?? data.data["name"] as? String {
            let titleNode = createText3D(text: productName, size: 0.04, color: .white)
            titleNode.position = SCNVector3(0, 0.16, 0.001)
            containerNode.addChildNode(titleNode)
        }
        
        // Prix principal
        if let price = data.data["price"] as? Double ?? data.data["price"] as? String,
           let priceString = formatPrice(price) {
            let priceNode = createText3D(text: priceString, size: 0.06, color: .green)
            priceNode.position = SCNVector3(0, 0.08, 0.001)
            containerNode.addChildNode(priceNode)
        }
        
        // Variation prix
        if let change = data.data["price_change"] as? Double ?? data.data["change"] as? Double,
           let changePercent = data.data["change_percent"] as? Double ?? data.data["change_percent"] as? String {
            let changeColor: UIColor = change >= 0 ? .green : .red
            let changeText = change >= 0 ? "+\(changePercent)" : "\(changePercent)"
            let changeNode = createText3D(text: changeText, size: 0.025, color: changeColor)
            changeNode.position = SCNVector3(0, -0.02, 0.001)
            containerNode.addChildNode(changeNode)
        }
        
        // Devise
        if let currency = data.data["currency"] as? String {
            let currencyNode = createText3D(text: currency, size: 0.02, color: .gray)
            currencyNode.position = SCNVector3(0, -0.08, 0.001)
            containerNode.addChildNode(currencyNode)
        }
        
        // Timestamp
        let timestampText = "Updated: \(formatDate(data.timestamp))"
        let timestampNode = createText3D(text: timestampText, size: 0.015, color: .gray)
        timestampNode.position = SCNVector3(0, -0.16, 0.001)
        containerNode.addChildNode(timestampNode)
        
        scene.rootNode.addChildNode(containerNode)
        return containerNode
    }
    
    // MARK: - Member Card Display
    
    func createMemberCardDisplay(data: ARDataResponse, in scene: SCNScene, at position: SIMD3<Float>) -> SCNNode {
        let containerNode = SCNNode()
        containerNode.name = "memberCard_\(UUID().uuidString)"
        containerNode.simdPosition = position
        
        // Carte style (comme une carte de membre physique)
        let cardWidth: Float = 0.35
        let cardHeight: Float = 0.22
        let card = createPanel(width: cardWidth, height: cardHeight, color: UIColor(red: 0.1, green: 0.2, blue: 0.4, alpha: 0.95))
        card.cornerRadius = 0.02
        containerNode.addChildNode(card)
        
        // Nom membre
        if let name = data.data["name"] as? String ?? data.data["member_name"] as? String {
            let nameNode = createText3D(text: name, size: 0.03, color: .white)
            nameNode.position = SCNVector3(-0.12, 0.08, 0.001)
            containerNode.addChildNode(nameNode)
        }
        
        // ID membre
        if let memberId = data.data["member_id"] as? String ?? data.data["id"] as? String {
            let idNode = createText3D(text: "ID: \(memberId)", size: 0.02, color: .gray)
            idNode.position = SCNVector3(-0.12, 0.03, 0.001)
            containerNode.addChildNode(idNode)
        }
        
        // Statut
        if let status = data.data["status"] as? String {
            let statusColor: UIColor = status.lowercased() == "active" ? .green : .orange
            let statusNode = createText3D(text: status.uppercased(), size: 0.025, color: statusColor)
            statusNode.position = SCNVector3(-0.12, -0.03, 0.001)
            containerNode.addChildNode(statusNode)
        }
        
        // Points/Récompenses
        if let points = data.data["points"] as? Int ?? data.data["points"] as? String {
            let pointsNode = createText3D(text: "Points: \(points)", size: 0.02, color: .yellow)
            pointsNode.position = SCNVector3(-0.12, -0.08, 0.001)
            containerNode.addChildNode(pointsNode)
        }
        
        scene.rootNode.addChildNode(containerNode)
        return containerNode
    }
    
    // MARK: - Generic Display
    
    func createGenericDisplay(data: ARDataResponse, template: DataTemplate, in scene: SCNScene, at position: SIMD3<Float>) -> SCNNode {
        switch template {
        case .iot:
            return createIOTDataDisplay(data: data, in: scene, at: position)
        case .pricing:
            return createLivePricingDisplay(data: data, in: scene, at: position)
        case .memberCard:
            return createMemberCardDisplay(data: data, in: scene, at: position)
        case .generic:
            return createGenericDisplayPanel(data: data, in: scene, at: position)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createPanel(width: Float, height: Float, color: UIColor, cornerRadius: Float = 0.01) -> SCNNode {
        let panel = SCNPlane(width: CGFloat(width), height: CGFloat(height))
        let material = SCNMaterial()
        material.diffuse.contents = color
        material.lightingModel = .constant
        panel.materials = [material]
        
        // Corner radius (simplifié avec rounded corners)
        // Pour vrai rounded corners, utiliser SCNShape avec UIBezierPath
        
        let node = SCNNode(geometry: panel)
        node.eulerAngles.x = -.pi / 2 // Horizontal
        
        return node
    }
    
    private func createText3D(text: String, size: Float, color: UIColor) -> SCNNode {
        let textGeometry = SCNText(string: text, extrusionDepth: 0.005)
        textGeometry.font = UIFont.systemFont(ofSize: CGFloat(size * 100))
        textGeometry.containerFrame = CGRect(x: 0, y: 0, width: 1, height: 0.5)
        textGeometry.isWrapped = true
        
        let material = SCNMaterial()
        material.diffuse.contents = color
        material.lightingModel = .constant
        textGeometry.materials = [material]
        
        let node = SCNNode(geometry: textGeometry)
        node.scale = SCNVector3(size, size, size)
        
        return node
    }
    
    private func formatValue(_ value: Any) -> String {
        if let doubleValue = value as? Double {
            return String(format: "%.2f", doubleValue)
        } else if let intValue = value as? Int {
            return "\(intValue)"
        } else if let stringValue = value as? String {
            return stringValue
        } else if let boolValue = value as? Bool {
            return boolValue ? "Yes" : "No"
        }
        return "\(value)"
    }
    
    private func formatPrice(_ price: Any) -> String? {
        if let doublePrice = price as? Double {
            return String(format: "%.2f", doublePrice)
        } else if let stringPrice = price as? String {
            return stringPrice
        }
        return nil
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    private func createGenericDisplayPanel(data: ARDataResponse, in scene: SCNScene, at position: SIMD3<Float>) -> SCNNode {
        let containerNode = SCNNode()
        containerNode.name = "genericDisplay_\(UUID().uuidString)"
        containerNode.simdPosition = position
        
        let panel = createPanel(width: 0.4, height: 0.3, color: UIColor(white: 0.1, alpha: 0.9))
        containerNode.addChildNode(panel)
        
        var yOffset: Float = 0.12
        for (key, value) in data.data.sorted(by: { $0.key < $1.key }) {
            let labelText = "\(key): \(formatValue(value))"
            let labelNode = createText3D(text: labelText, size: 0.02, color: .white)
            labelNode.position = SCNVector3(-0.15, yOffset, 0.001)
            containerNode.addChildNode(labelNode)
            yOffset -= 0.04
        }
        
        scene.rootNode.addChildNode(containerNode)
        return containerNode
    }
}

extension SCNPlane {
    var cornerRadius: Float {
        get { 0 }
        set {
            // Note: SCNPlane ne supporte pas directement cornerRadius
            // Pour arrondir les coins, utiliser SCNShape avec UIBezierPath rounded rect
        }
    }
}









