//
//  ARVideoPlayerService.swift
//  ARCodeClone
//
//  Service pour lecture vidéo en AR avec AVPlayer, placement 3D, contrôles
//

import Foundation
import ARKit
import SceneKit
import AVFoundation
import UIKit
import SpriteKit

protocol ARVideoPlayerServiceProtocol {
    func loadVideo(url: URL, completion: @escaping (Result<AVPlayer, Error>) -> Void)
    func createVideoNode(player: AVPlayer, size: CGSize) -> SCNNode
    func placeVideoNode(_ node: SCNNode, on plane: ARPlaneAnchor, in scene: SCNScene)
    func placeVideoNodeFloating(_ node: SCNNode, at position: SIMD3<Float>, in scene: SCNScene)
}

enum ARVideoPlayerError: LocalizedError {
    case invalidVideoURL
    case videoLoadFailed(Error)
    case playerCreationFailed
    case unsupportedFormat
    
    var errorDescription: String? {
        switch self {
        case .invalidVideoURL:
            return "URL vidéo invalide"
        case .videoLoadFailed(let error):
            return "Échec chargement vidéo: \(error.localizedDescription)"
        case .playerCreationFailed:
            return "Échec création lecteur vidéo"
        case .unsupportedFormat:
            return "Format vidéo non supporté"
        }
    }
}

final class ARVideoPlayerService: ARVideoPlayerServiceProtocol {
    private var videoNodes: [UUID: SCNNode] = [:]
    private var videoPlayers: [UUID: AVPlayer] = [:]
    
    // MARK: - Video Loading
    
    func loadVideo(url: URL, completion: @escaping (Result<AVPlayer, Error>) -> Void) {
        // Valider URL
        guard url.scheme == "http" || url.scheme == "https" || url.isFileURL else {
            completion(.failure(ARVideoPlayerError.invalidVideoURL))
            return
        }
        
        // Créer AVAsset pour validation
        let asset = AVAsset(url: url)
        
        // Vérifier format supporté
        Task {
            do {
                // Charger métadonnées
                let tracks = try await asset.loadTracks(withMediaType: .video)
                
                guard let videoTrack = tracks.first else {
                    completion(.failure(ARVideoPlayerError.unsupportedFormat))
                    return
                }
                
                // Vérifier codec
                let formatDescriptions = try await videoTrack.load(.formatDescriptions)
                let formatDescription = formatDescriptions.first as! CMFormatDescription
                let codecType = CMFormatDescriptionGetMediaSubType(formatDescription)
                
                // Support H.264 (avc1) et H.265 (hev1, hvc1)
                guard codecType == kCMVideoCodecType_H264 || 
                      codecType == kCMVideoCodecType_HEVC else {
                    // Avertir mais continuer (AVPlayer peut décoder)
                    print("⚠️ Codec non standard détecté: \(codecType)")
                }
                
                // Créer AVPlayer
                let player = AVPlayer(url: url)
                
                // Configuration player
                player.allowsExternalPlayback = false
                player.actionAtItemEnd = .pause
                
                DispatchQueue.main.async {
                    completion(.success(player))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(ARVideoPlayerError.videoLoadFailed(error)))
                }
            }
        }
    }
    
    // MARK: - Video Node Creation
    
    func createVideoNode(player: AVPlayer, size: CGSize) -> SCNNode {
        // Créer géométrie plane pour vidéo
        let videoPlane = SCNPlane(width: size.width, height: size.height)
        
        // Créer SKScene pour AVPlayerLayer
        let skScene = SKScene(size: size)
        skScene.backgroundColor = .black
        
        // Créer SKVideoNode pour AVPlayer
        let videoSKNode = SKVideoNode(avPlayer: player)
        videoSKNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        videoSKNode.size = size
        videoSKNode.yScale = -1.0 // Inverser verticalement pour AR
        
        skScene.addChild(videoSKNode)
        
        // Appliquer SKScene comme texture
        let material = SCNMaterial()
        material.diffuse.contents = skScene
        material.isDoubleSided = true
        videoPlane.materials = [material]
        
        // Créer node
        let videoNode = SCNNode(geometry: videoPlane)
        videoNode.name = "videoNode_\(UUID().uuidString)"
        
        return videoNode
    }
    
    // MARK: - Placement Methods
    
    func placeVideoNode(_ node: SCNNode, on plane: ARPlaneAnchor, in scene: SCNScene) {
        // Positionner vidéo sur plan détecté
        let position = SIMD3<Float>(plane.center.x, plane.center.y, plane.center.z)
        node.simdPosition = position
        
        // Orientation selon type plan
        if plane.alignment == .vertical {
            // Plan vertical: vidéo face à la caméra
            node.simdRotation = simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(1, 0, 0))
        }
        // Plan horizontal: vidéo horizontale (par défaut)
        
        scene.rootNode.addChildNode(node)
    }
    
    func placeVideoNodeFloating(_ node: SCNNode, at position: SIMD3<Float>, in scene: SCNScene) {
        // Positionner vidéo flottante dans l'espace 3D
        node.simdPosition = position
        
        // Orientation par défaut (face à la caméra)
        // Peut être ajustée avec gestures
        
        scene.rootNode.addChildNode(node)
    }
    
    // MARK: - Helper Methods
    
    func registerVideoNode(_ node: SCNNode, player: AVPlayer) -> UUID {
        let id = UUID()
        videoNodes[id] = node
        videoPlayers[id] = player
        return id
    }
    
    func getPlayer(for nodeId: UUID) -> AVPlayer? {
        return videoPlayers[nodeId]
    }
    
    func removeVideoNode(_ nodeId: UUID) {
        videoNodes[nodeId]?.removeFromParentNode()
        videoNodes.removeValue(forKey: nodeId)
        videoPlayers[nodeId]?.pause()
        videoPlayers.removeValue(forKey: nodeId)
    }
}

