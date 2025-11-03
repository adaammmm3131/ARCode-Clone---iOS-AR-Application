//
//  ARVideoViewModel.swift
//  ARCodeClone
//
//  ViewModel pour AR Video Player
//

import Foundation
import SwiftUI
import Combine
import ARKit
import SceneKit
import AVFoundation

final class ARVideoViewModel: BaseViewModel, ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var currentTime: Double = 0.0
    @Published var duration: Double = 0.0
    @Published var volume: Float = 1.0
    @Published var progress: Double = 0.0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var videoNode: SCNNode?
    @Published var selectedVideoURL: URL?
    
    private let arService: ARServiceProtocol
    private let videoPlayerService: ARVideoPlayerServiceProtocol
    private let controlsService: ARVideoControlsServiceProtocol
    private let gestureService: ARVideoGestureServiceProtocol
    private let formatService: ARVideoFormatServiceProtocol
    
    private var currentPlayer: AVPlayer?
    private var progressCancellable: AnyCancellable?
    private var videoNodeId: UUID?
    
    init(
        arService: ARServiceProtocol,
        videoPlayerService: ARVideoPlayerServiceProtocol,
        controlsService: ARVideoControlsServiceProtocol,
        gestureService: ARVideoGestureServiceProtocol,
        formatService: ARVideoFormatServiceProtocol
    ) {
        self.arService = arService
        self.videoPlayerService = videoPlayerService
        self.controlsService = controlsService
        self.gestureService = gestureService
        self.formatService = formatService
        super.init()
        
        // Observer notifications pour gestes
        setupGestureObservers()
    }
    
    private func setupGestureObservers() {
        NotificationCenter.default.addObserver(
            forName: .arVideoTogglePlayback,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.togglePlayback()
        }
    }
    
    // MARK: - Video Loading
    
    func loadVideo(url: URL, in scene: SCNScene, placement: VideoPlacement) {
        isLoading = true
        errorMessage = nil
        selectedVideoURL = url
        
        // Valider vidéo
        let validation = formatService.validateVideo(url: url)
        guard validation.isValid else {
            errorMessage = validation.errorMessage ?? "Vidéo invalide"
            isLoading = false
            return
        }
        
        // Charger vidéo
        videoPlayerService.loadVideo(url: url) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let player):
                    self?.currentPlayer = player
                    
                    // Obtenir infos vidéo
                    if let resolution = validation.resolution {
                        let videoNode = self?.videoPlayerService.createVideoNode(
                            player: player,
                            size: resolution
                        )
                        
                        if let videoNode = videoNode {
                            // Placer vidéo
                            switch placement {
                            case .floating(let position):
                                self?.videoPlayerService.placeVideoNodeFloating(
                                    videoNode,
                                    at: position,
                                    in: scene
                                )
                            case .onPlane(let planeAnchor):
                                self?.videoPlayerService.placeVideoNode(
                                    videoNode,
                                    on: planeAnchor,
                                    in: scene
                                )
                            }
                            
                            self?.videoNode = videoNode
                            
                            // Enregistrer pour cleanup
                            if let service = self?.videoPlayerService as? ARVideoPlayerService {
                                let nodeId = service.registerVideoNode(videoNode, player: player)
                                self?.videoNodeId = nodeId
                            }
                            
                            // Observer progression
                            self?.observeProgress(player: player)
                            
                            // Observer duration
                            self?.updateDuration(player: player)
                        }
                    }
                    
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Playback Controls
    
    func togglePlayback() {
        guard let player = currentPlayer else { return }
        controlsService.togglePlayback(player)
        isPlaying = player.timeControlStatus == .playing
    }
    
    func play() {
        guard let player = currentPlayer else { return }
        controlsService.play(player)
        isPlaying = true
    }
    
    func pause() {
        guard let player = currentPlayer else { return }
        controlsService.pause(player)
        isPlaying = false
    }
    
    func seek(to progress: Double) {
        guard let player = currentPlayer,
              let duration = player.currentItem?.duration else { return }
        
        let time = CMTimeMultiplyByFloat64(duration, multiplier: Float64(progress))
        controlsService.seek(to: time, player: player)
    }
    
    // MARK: - Volume Control
    
    func setVolume(_ volume: Float) {
        guard let player = currentPlayer else { return }
        controlsService.setVolume(volume, player: player)
        self.volume = volume
    }
    
    // MARK: - Gesture Setup
    
    func setupGestures(on view: UIView, scene: SCNScene) {
        guard let videoNode = videoNode else { return }
        gestureService.setupGestures(on: view, scene: scene, videoNode: videoNode)
    }
    
    func removeGestures(from view: UIView) {
        gestureService.removeGestures(from: view)
    }
    
    // MARK: - Helper Methods
    
    private func observeProgress(player: AVPlayer) {
        // Nettoyer observer précédent
        progressCancellable?.cancel()
        
        progressCancellable = controlsService.observeProgress(player: player) { [weak self] currentTime, totalDuration in
            DispatchQueue.main.async {
                self?.currentTime = currentTime
                self?.duration = totalDuration
                self?.progress = totalDuration > 0 ? currentTime / totalDuration : 0
                
                // Mettre à jour isPlaying
                self?.isPlaying = player.timeControlStatus == .playing
            }
        }
    }
    
    private func updateDuration(player: AVPlayer) {
        if let duration = controlsService.getDuration(player) {
            self.duration = duration
        }
    }
    
    func cleanup() {
        progressCancellable?.cancel()
        currentPlayer?.pause()
        currentPlayer = nil
        videoNode = nil
        
        if let nodeId = videoNodeId,
           let service = videoPlayerService as? ARVideoPlayerService {
            service.removeVideoNode(nodeId)
        }
    }
}

// MARK: - Video Placement

enum VideoPlacement {
    case floating(position: SIMD3<Float>)
    case onPlane(planeAnchor: ARPlaneAnchor)
}

