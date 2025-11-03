//
//  ARPortalFormatService.swift
//  ARCodeClone
//
//  Service pour validation formats AR Portal (equirectangular, 360°, stéréo)
//

import Foundation
import UIKit
import AVFoundation

protocol ARPortalFormatServiceProtocol {
    func validateEquirectangularImage(url: URL) -> PortalFormatValidationResult
    func validate360Video(url: URL) -> PortalFormatValidationResult
    func loadGoogleStreetViewFormat(url: URL, completion: @escaping (Result<[UIImage], Error>) -> Void)
    func validateStereo360(url: URL) -> PortalFormatValidationResult
}

enum PortalFormatType {
    case equirectangularImage
    case equirectangularVideo
    case googleStreetView
    case stereo360
    case unknown
}

struct PortalFormatValidationResult {
    let isValid: Bool
    let formatType: PortalFormatType
    let resolution: CGSize?
    let aspectRatio: Float?
    let errorMessage: String?
    
    // Pour vidéo
    let duration: Double?
    let frameRate: Double?
    
    // Pour stéréo
    let isStereo: Bool?
}

enum ARPortalFormatError: LocalizedError {
    case invalidURL
    case loadFailed(Error)
    case invalidAspectRatio
    case resolutionTooHigh
    case formatNotSupported
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalide"
        case .loadFailed(let error):
            return "Échec chargement: \(error.localizedDescription)"
        case .invalidAspectRatio:
            return "Ratio d'aspect invalide (2:1 requis pour equirectangular)"
        case .resolutionTooHigh:
            return "Résolution trop élevée (max 8K)"
        case .formatNotSupported:
            return "Format non supporté"
        }
    }
}

final class ARPortalFormatService: ARPortalFormatServiceProtocol {
    private let maxResolution: CGSize = CGSize(width: 8192, height: 4096) // 8K equirectangular (2:1)
    
    // MARK: - Equirectangular Image Validation
    
    func validateEquirectangularImage(url: URL) -> PortalFormatValidationResult {
        // Charger image
        guard let image = loadImage(url: url) else {
            return PortalFormatValidationResult(
                isValid: false,
                formatType: .unknown,
                resolution: nil,
                aspectRatio: nil,
                errorMessage: "Impossible de charger l'image",
                duration: nil,
                frameRate: nil,
                isStereo: nil
            )
        }
        
        let size = image.size
        let aspectRatio = Float(size.width / size.height)
        
        // Vérifier ratio d'aspect 2:1 pour equirectangular
        let expectedAspectRatio: Float = 2.0
        let aspectRatioTolerance: Float = 0.1
        
        guard abs(aspectRatio - expectedAspectRatio) < aspectRatioTolerance else {
            return PortalFormatValidationResult(
                isValid: false,
                formatType: .equirectangularImage,
                resolution: size,
                aspectRatio: aspectRatio,
                errorMessage: "Ratio d'aspect invalide (2:1 requis, obtenu: \(String(format: "%.2f", aspectRatio)))",
                duration: nil,
                frameRate: nil,
                isStereo: nil
            )
        }
        
        // Vérifier résolution max
        if size.width > maxResolution.width || size.height > maxResolution.height {
            return PortalFormatValidationResult(
                isValid: false,
                formatType: .equirectangularImage,
                resolution: size,
                aspectRatio: aspectRatio,
                errorMessage: "Résolution trop élevée (max 8K: 8192x4096)",
                duration: nil,
                frameRate: nil,
                isStereo: nil
            )
        }
        
        return PortalFormatValidationResult(
            isValid: true,
            formatType: .equirectangularImage,
            resolution: size,
            aspectRatio: aspectRatio,
            errorMessage: nil,
            duration: nil,
            frameRate: nil,
            isStereo: nil
        )
    }
    
    // MARK: - 360 Video Validation
    
    func validate360Video(url: URL) -> PortalFormatValidationResult {
        let asset = AVAsset(url: url)
        
        // Vérifier format via tracks
        var isValid = false
        var resolution: CGSize?
        var duration: Double?
        var frameRate: Double?
        var errorMessage: String?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            defer { semaphore.signal() }
            
            do {
                let videoTracks = try await asset.loadTracks(withMediaType: .video)
                
                guard let videoTrack = videoTracks.first else {
                    errorMessage = "Aucune piste vidéo trouvée"
                    return
                }
                
                let naturalSize = try await videoTrack.load(.naturalSize)
                let timeRange = try await videoTrack.load(.timeRange)
                let nominalFrameRate = try await videoTrack.load(.nominalFrameRate)
                
                resolution = naturalSize
                duration = timeRange.duration.seconds
                frameRate = Double(nominalFrameRate)
                
                // Vérifier aspect ratio 2:1
                let aspectRatio = Float(naturalSize.width / naturalSize.height)
                if abs(aspectRatio - 2.0) < 0.1 {
                    isValid = true
                } else {
                    errorMessage = "Ratio d'aspect invalide pour vidéo 360°"
                }
                
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        
        semaphore.wait()
        
        return PortalFormatValidationResult(
            isValid: isValid,
            formatType: .equirectangularVideo,
            resolution: resolution,
            aspectRatio: resolution.map { Float($0.width / $0.height) },
            errorMessage: errorMessage,
            duration: duration,
            frameRate: frameRate,
            isStereo: nil
        )
    }
    
    // MARK: - Google Street View Format
    
    func loadGoogleStreetViewFormat(url: URL, completion: @escaping (Result<[UIImage], Error>) -> Void) {
        // Google Street View utilise format avec tiles ou image unique equirectangular
        // Pour l'instant, traiter comme image equirectangular standard
        if let image = loadImage(url: url) {
            completion(.success([image]))
        } else {
            completion(.failure(ARPortalFormatError.loadFailed(NSError(domain: "ARPortalFormat", code: -1))))
        }
    }
    
    // MARK: - Stereo 360 Validation
    
    func validateStereo360(url: URL) -> PortalFormatValidationResult {
        // Détecter format stéréo (deux vues côte à côte ou haut/bas)
        // Pour l'instant, validation basique
        
        if url.pathExtension.lowercased() == "jpg" || url.pathExtension.lowercased() == "png" {
            // Image stéréo
            if let image = loadImage(url: url) {
                let size = image.size
                let aspectRatio = Float(size.width / size.height)
                
                // Format stéréo: 2:1 (side-by-side) ou 1:2 (top-bottom)
                let isStereo = aspectRatio == 4.0 || aspectRatio == 0.5
                
                return PortalFormatValidationResult(
                    isValid: isStereo,
                    formatType: .stereo360,
                    resolution: size,
                    aspectRatio: aspectRatio,
                    errorMessage: isStereo ? nil : "Format stéréo invalide",
                    duration: nil,
                    frameRate: nil,
                    isStereo: isStereo
                )
            }
        } else if url.pathExtension.lowercased() == "mp4" || url.pathExtension.lowercased() == "mov" {
            // Vidéo stéréo 360
            return validate360Video(url: url) // Utiliser validation 360° standard pour l'instant
        }
        
        return PortalFormatValidationResult(
            isValid: false,
            formatType: .unknown,
            resolution: nil,
            aspectRatio: nil,
            errorMessage: "Format non supporté",
            duration: nil,
            frameRate: nil,
            isStereo: nil
        )
    }
    
    // MARK: - Helper Methods
    
    private func loadImage(url: URL) -> UIImage? {
        if url.isFileURL {
            return UIImage(contentsOfFile: url.path)
        } else {
            // Synchronous load pour validation (en production, utiliser async)
            guard let data = try? Data(contentsOf: url) else {
                return nil
            }
            return UIImage(data: data)
        }
    }
}










