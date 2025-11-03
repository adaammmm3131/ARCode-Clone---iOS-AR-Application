//
//  ARVideoFormatService.swift
//  ARCodeClone
//
//  Service pour validation formats vidéo, compression, streaming adaptive bitrate
//

import Foundation
import AVFoundation
import UIKit

protocol ARVideoFormatServiceProtocol {
    func validateVideo(url: URL) -> VideoValidationResult
    func compressVideo(url: URL, quality: VideoQuality, completion: @escaping (Result<URL, Error>) -> Void)
    func getVideoInfo(url: URL, completion: @escaping (Result<VideoInfo, Error>) -> Void)
}

enum VideoQuality {
    case low       // 480p, ~1 Mbps
    case medium    // 720p, ~2.5 Mbps
    case high      // 1080p, ~5 Mbps
    case ultra     // 4K, ~15 Mbps (si supporté)
    
    var resolution: CGSize {
        switch self {
        case .low: return CGSize(width: 854, height: 480)
        case .medium: return CGSize(width: 1280, height: 720)
        case .high: return CGSize(width: 1920, height: 1080)
        case .ultra: return CGSize(width: 3840, height: 2160)
        }
    }
    
    var bitrate: Int {
        switch self {
        case .low: return 1_000_000
        case .medium: return 2_500_000
        case .high: return 5_000_000
        case .ultra: return 15_000_000
        }
    }
}

struct VideoValidationResult {
    let isValid: Bool
    let format: String?
    let codec: String?
    let resolution: CGSize?
    let duration: Double?
    let fileSize: Int64?
    let errorMessage: String?
}

struct VideoInfo {
    let resolution: CGSize
    let duration: Double
    let bitrate: Double
    let codec: String
    let frameRate: Double
    let fileSize: Int64
}

enum ARVideoFormatError: LocalizedError {
    case invalidURL
    case loadFailed(Error)
    case compressionFailed
    case unsupportedCodec
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL vidéo invalide"
        case .loadFailed(let error):
            return "Échec chargement: \(error.localizedDescription)"
        case .compressionFailed:
            return "Échec compression vidéo"
        case .unsupportedCodec:
            return "Codec non supporté"
        }
    }
}

final class ARVideoFormatService: ARVideoFormatServiceProtocol {
    
    // MARK: - Video Validation
    
    func validateVideo(url: URL) -> VideoValidationResult {
        let asset = AVAsset(url: url)
        
        // Vérifier si asset est lisible
        var isValid = false
        var format: String?
        var codec: String?
        var resolution: CGSize?
        var duration: Double?
        var fileSize: Int64?
        var errorMessage: String?
        
        // Synchronous check (blocking)
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            defer { semaphore.signal() }
            
            do {
                // Vérifier tracks vidéo
                let videoTracks = try await asset.loadTracks(withMediaType: .video)
                
                guard let videoTrack = videoTracks.first else {
                    errorMessage = "Aucune piste vidéo trouvée"
                    return
                }
                
                // Obtenir infos
                let naturalSize = try await videoTrack.load(.naturalSize)
                let formatDescriptions = try await videoTrack.load(.formatDescriptions)
                let timeRange = try await videoTrack.load(.timeRange)
                
                resolution = naturalSize
                duration = timeRange.duration.seconds
                
                if let formatDesc = formatDescriptions.first as? CMFormatDescription {
                    let codecType = CMFormatDescriptionGetMediaSubType(formatDesc)
                    codec = getCodecName(codecType)
                    
                    // Vérifier support codec
                    isValid = codecType == kCMVideoCodecType_H264 || 
                              codecType == kCMVideoCodecType_HEVC ||
                              codecType == kCMVideoCodecType_MPEG4Video
                }
                
                // File size
                if url.isFileURL {
                    let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
                    fileSize = attributes?[.size] as? Int64
                }
                
                // Format container
                if url.pathExtension.lowercased() == "mp4" {
                    format = "MP4"
                } else if url.pathExtension.lowercased() == "mov" {
                    format = "MOV"
                } else {
                    format = url.pathExtension.uppercased()
                }
                
            } catch {
                errorMessage = error.localizedDescription
                isValid = false
            }
        }
        
        semaphore.wait()
        
        return VideoValidationResult(
            isValid: isValid,
            format: format,
            codec: codec,
            resolution: resolution,
            duration: duration,
            fileSize: fileSize,
            errorMessage: errorMessage
        )
    }
    
    // MARK: - Video Compression
    
    func compressVideo(url: URL, quality: VideoQuality, completion: @escaping (Result<URL, Error>) -> Void) {
        let asset = AVAsset(url: url)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: getExportPreset(for: quality)) else {
            completion(.failure(ARVideoFormatError.compressionFailed))
            return
        }
        
        // Output URL
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        
        // Supprimer fichier existant si nécessaire
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(at: outputURL)
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        // Configuration bitrate si possible
        // Note: AVAssetExportSession ne permet pas contrôle direct bitrate
        // Utiliser AVAssetWriter pour contrôle fin
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                completion(.success(outputURL))
            case .failed:
                completion(.failure(exportSession.error ?? ARVideoFormatError.compressionFailed))
            case .cancelled:
                completion(.failure(ARVideoFormatError.compressionFailed))
            default:
                completion(.failure(ARVideoFormatError.compressionFailed))
            }
        }
    }
    
    // MARK: - Video Info
    
    func getVideoInfo(url: URL, completion: @escaping (Result<VideoInfo, Error>) -> Void) {
        let asset = AVAsset(url: url)
        
        Task {
            do {
                let videoTracks = try await asset.loadTracks(withMediaType: .video)
                
                guard let videoTrack = videoTracks.first else {
                    completion(.failure(ARVideoFormatError.loadFailed(NSError(domain: "ARVideoFormat", code: -1))))
                    return
                }
                
                let naturalSize = try await videoTrack.load(.naturalSize)
                let timeRange = try await videoTrack.load(.timeRange)
                let formatDescriptions = try await videoTrack.load(.formatDescriptions)
                let estimatedDataRate = try await videoTrack.load(.estimatedDataRate)
                let nominalFrameRate = try await videoTrack.load(.nominalFrameRate)
                
                let codecType = (formatDescriptions.first as? CMFormatDescription).map { CMFormatDescriptionGetMediaSubType($0) } ?? 0
                let codec = getCodecName(codecType)
                
                let fileSize: Int64 = url.isFileURL ? (try? FileManager.default.attributesOfItem(atPath: url.path)?[.size] as? Int64) ?? 0 : 0
                
                let info = VideoInfo(
                    resolution: naturalSize,
                    duration: timeRange.duration.seconds,
                    bitrate: estimatedDataRate,
                    codec: codec,
                    frameRate: Double(nominalFrameRate),
                    fileSize: fileSize
                )
                
                DispatchQueue.main.async {
                    completion(.success(info))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getExportPreset(for quality: VideoQuality) -> String {
        switch quality {
        case .low:
            return AVAssetExportPresetMediumQuality
        case .medium:
            return AVAssetExportPresetHighestQuality
        case .high:
            return AVAssetExportPreset1920x1080
        case .ultra:
            return AVAssetExportPreset3840x2160
        }
    }
    
    private func getCodecName(_ codecType: FourCharCode) -> String {
        switch codecType {
        case kCMVideoCodecType_H264:
            return "H.264"
        case kCMVideoCodecType_HEVC:
            return "H.265 (HEVC)"
        case kCMVideoCodecType_MPEG4Video:
            return "MPEG-4"
        default:
            return "Unknown"
        }
    }
}










