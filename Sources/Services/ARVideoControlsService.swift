//
//  ARVideoControlsService.swift
//  ARCodeClone
//
//  Service pour contrôles playback vidéo AR (play/pause, volume, progress)
//

import Foundation
import AVFoundation
import Combine

protocol ARVideoControlsServiceProtocol {
    func play(_ player: AVPlayer)
    func pause(_ player: AVPlayer)
    func togglePlayback(_ player: AVPlayer)
    func seek(to time: CMTime, player: AVPlayer)
    func setVolume(_ volume: Float, player: AVPlayer)
    func observeProgress(player: AVPlayer, callback: @escaping (Double, Double) -> Void) -> AnyCancellable
}

final class ARVideoControlsService: ARVideoControlsServiceProtocol {
    private var timeObservers: [UUID: Any] = [:]
    
    // MARK: - Playback Controls
    
    func play(_ player: AVPlayer) {
        player.play()
    }
    
    func pause(_ player: AVPlayer) {
        player.pause()
    }
    
    func togglePlayback(_ player: AVPlayer) {
        if player.timeControlStatus == .playing {
            pause(player)
        } else {
            play(player)
        }
    }
    
    func seek(to time: CMTime, player: AVPlayer) {
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { [weak player] completed in
            if completed {
                // Seek completed
            }
        }
    }
    
    // MARK: - Volume Control
    
    func setVolume(_ volume: Float, player: AVPlayer) {
        // Clamper volume entre 0.0 et 1.0
        let clampedVolume = max(0.0, min(1.0, volume))
        player.volume = clampedVolume
    }
    
    // MARK: - Progress Observation
    
    func observeProgress(player: AVPlayer, callback: @escaping (Double, Double) -> Void) -> AnyCancellable {
        // Observer time changes
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        let timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak player] time in
            guard let player = player,
                  let duration = player.currentItem?.duration else {
                return
            }
            
            let currentTime = time.seconds
            let totalDuration = duration.seconds.isFinite ? duration.seconds : 0
            
            callback(currentTime, totalDuration)
        }
        
        // Retourner Cancellable pour cleanup
        return AnyCancellable {
            player.removeTimeObserver(timeObserver)
        }
    }
    
    // MARK: - Helper Methods
    
    func formatTime(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) / 60 % 60
        let secs = Int(seconds) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
    
    func getCurrentTime(_ player: AVPlayer) -> Double {
        return player.currentTime().seconds
    }
    
    func getDuration(_ player: AVPlayer) -> Double? {
        guard let duration = player.currentItem?.duration,
              duration.isValid && duration.isNumeric else {
            return nil
        }
        return duration.seconds.isFinite ? duration.seconds : nil
    }
}










