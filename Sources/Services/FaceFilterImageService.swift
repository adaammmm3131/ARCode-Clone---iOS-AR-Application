//
//  FaceFilterImageService.swift
//  ARCodeClone
//
//  Service pour validation et compression images face filter
//

import UIKit
import CoreImage

protocol FaceFilterImageServiceProtocol {
    func validateImage(_ image: UIImage) -> ImageValidationResult
    func compressImage(_ image: UIImage, maxSizeMB: Double) -> UIImage?
    func prepareImageForAR(_ image: UIImage) -> UIImage?
}

struct ImageValidationResult {
    let isValid: Bool
    let width: Int
    let height: Int
    let fileSizeMB: Double?
    let hasTransparency: Bool
    let format: ImageFormat
    let errorMessage: String?
}

enum ImageFormat {
    case png
    case jpeg
    case unknown
}

final class FaceFilterImageService: FaceFilterImageServiceProtocol {
    private let maxWidth: Int = 2048
    private let maxHeight: Int = 2048
    private let maxFileSizeMB: Double = 5.0
    private let minWidth: Int = 64
    private let minHeight: Int = 64
    
    func validateImage(_ image: UIImage) -> ImageValidationResult {
        let width = Int(image.size.width * image.scale)
        let height = Int(image.size.height * image.scale)
        
        // Vérifier dimensions
        if width < minWidth || height < minHeight {
            return ImageValidationResult(
                isValid: false,
                width: width,
                height: height,
                fileSizeMB: nil,
                hasTransparency: checkTransparency(image),
                format: detectFormat(image),
                errorMessage: "Image trop petite (min: \(minWidth)x\(minHeight)px)"
            )
        }
        
        if width > maxWidth || height > maxHeight {
            return ImageValidationResult(
                isValid: false,
                width: width,
                height: height,
                fileSizeMB: nil,
                hasTransparency: checkTransparency(image),
                format: detectFormat(image),
                errorMessage: "Image trop grande (max: \(maxWidth)x\(maxHeight)px)"
            )
        }
        
        // Vérifier taille fichier
        if let data = image.pngData() {
            let fileSizeMB = Double(data.count) / (1024 * 1024)
            if fileSizeMB > maxFileSizeMB {
                return ImageValidationResult(
                    isValid: false,
                    width: width,
                    height: height,
                    fileSizeMB: fileSizeMB,
                    hasTransparency: checkTransparency(image),
                    format: detectFormat(image),
                    errorMessage: "Fichier trop volumineux (\(String(format: "%.2f", fileSizeMB))MB, max: \(maxFileSizeMB)MB)"
                )
            }
            
            return ImageValidationResult(
                isValid: true,
                width: width,
                height: height,
                fileSizeMB: fileSizeMB,
                hasTransparency: checkTransparency(image),
                format: detectFormat(image),
                errorMessage: nil
            )
        }
        
        return ImageValidationResult(
            isValid: false,
            width: width,
            height: height,
            fileSizeMB: nil,
            hasTransparency: false,
            format: .unknown,
            errorMessage: "Impossible de valider l'image"
        )
    }
    
    func compressImage(_ image: UIImage, maxSizeMB: Double) -> UIImage? {
        guard let data = image.pngData() else { return nil }
        let currentSizeMB = Double(data.count) / (1024 * 1024)
        
        if currentSizeMB <= maxSizeMB {
            return image // Pas besoin de compression
        }
        
        // Compression progressive
        var quality: CGFloat = 0.9
        var compressedImage: UIImage?
        
        repeat {
            if let jpegData = image.jpegData(compressionQuality: quality) {
                let sizeMB = Double(jpegData.count) / (1024 * 1024)
                
                if sizeMB <= maxSizeMB {
                    compressedImage = UIImage(data: jpegData)
                    break
                }
                
                quality -= 0.1
                if quality < 0.1 { break }
            }
        } while quality >= 0.1
        
        // Si JPEG ne suffit pas, réduire résolution
        if compressedImage == nil {
            let scale = sqrt(maxSizeMB / currentSizeMB)
            let newSize = CGSize(
                width: image.size.width * scale,
                height: image.size.height * scale
            )
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            compressedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        
        return compressedImage
    }
    
    func prepareImageForAR(_ image: UIImage) -> UIImage? {
        // Normaliser orientation
        guard let cgImage = image.cgImage else { return nil }
        
        // Créer image orientée correctement
        let orientedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: .up)
        
        // Optimiser pour AR (taille appropriée)
        let targetSize = CGSize(width: 512, height: 512) // Taille optimale pour AR
        
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        orientedImage.draw(in: CGRect(origin: .zero, size: targetSize))
        let optimizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return optimizedImage
    }
    
    // MARK: - Private Helpers
    
    private func checkTransparency(_ image: UIImage) -> Bool {
        guard let cgImage = image.cgImage,
              let dataProvider = cgImage.dataProvider,
              let pixelData = dataProvider.data else {
            return false
        }
        
        let data = CFDataGetBytePtr(pixelData)
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let hasAlpha = cgImage.alphaInfo != .none &&
                      cgImage.alphaInfo != .noneSkipFirst &&
                      cgImage.alphaInfo != .noneSkipLast
        
        if !hasAlpha { return false }
        
        // Vérifier pixels transparents
        let width = cgImage.width
        let height = cgImage.height
        
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = (y * width + x) * bytesPerPixel
                let alpha = data?[pixelIndex + 3] ?? 255
                if alpha < 255 {
                    return true
                }
            }
        }
        
        return false
    }
    
    private func detectFormat(_ image: UIImage) -> ImageFormat {
        guard let data = image.pngData() else { return .unknown }
        
        // Détecter format depuis data
        if data.count > 8 {
            let signature = data.prefix(8)
            if signature.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
                return .png
            } else if signature.starts(with: [0xFF, 0xD8, 0xFF]) {
                return .jpeg
            }
        }
        
        return .unknown
    }
}










