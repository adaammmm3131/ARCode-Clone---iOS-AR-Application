//
//  ARPhotoFrameImageService.swift
//  ARCodeClone
//
//  Service pour upload et validation images photo frame
//

import Foundation
import UIKit

protocol ARPhotoFrameImageServiceProtocol {
    func validateImage(_ image: UIImage) -> ImageValidationResult
    func calculateAspectRatio(_ image: UIImage) -> Float
    func resizeImage(_ image: UIImage, to aspectRatio: AspectRatio, maxSize: CGSize) -> UIImage?
    func cropImage(_ image: UIImage, to aspectRatio: AspectRatio) -> UIImage?
}

enum AspectRatio: String, CaseIterable, Identifiable {
    case square = "1:1"
    case portrait4_3 = "4:3"
    case portrait3_2 = "3:2"
    case portrait16_9 = "16:9"
    case landscape4_3 = "4:3"
    case landscape3_2 = "3:2"
    case landscape16_9 = "16:9"
    case original = "Original"
    
    var id: String { self.rawValue }
    
    var ratio: Float? {
        switch self {
        case .square:
            return 1.0
        case .portrait4_3:
            return 3.0 / 4.0 // Portrait: hauteur > largeur
        case .landscape4_3:
            return 4.0 / 3.0 // Landscape: largeur > hauteur
        case .portrait3_2:
            return 2.0 / 3.0
        case .landscape3_2:
            return 3.0 / 2.0
        case .portrait16_9:
            return 9.0 / 16.0
        case .landscape16_9:
            return 16.0 / 9.0
        case .original:
            return nil // Garder ratio original
        }
    }
    
    var isPortrait: Bool {
        switch self {
        case .portrait4_3, .portrait3_2, .portrait16_9:
            return true
        default:
            return false
        }
    }
}

struct ImageValidationResult {
    let isValid: Bool
    let format: String?
    let resolution: CGSize?
    let aspectRatio: Float?
    let fileSize: Int64?
    let errorMessage: String?
}

enum ARPhotoFrameImageError: LocalizedError {
    case invalidFormat
    case resolutionTooLow
    case invalidAspectRatio
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Format image non supporté (JPG/PNG requis)"
        case .resolutionTooLow:
            return "Résolution trop faible (min 512x512px)"
        case .invalidAspectRatio:
            return "Ratio d'aspect invalide"
        }
    }
}

final class ARPhotoFrameImageService: ARPhotoFrameImageServiceProtocol {
    
    // MARK: - Image Validation
    
    func validateImage(_ image: UIImage) -> ImageValidationResult {
        let size = image.size
        let aspectRatio = Float(size.width / size.height)
        
        // Vérifier résolution minimale
        let minResolution: CGFloat = 512
        guard size.width >= minResolution && size.height >= minResolution else {
            return ImageValidationResult(
                isValid: false,
                format: nil,
                resolution: size,
                aspectRatio: aspectRatio,
                fileSize: nil,
                errorMessage: "Résolution trop faible (min 512x512px)"
            )
        }
        
        return ImageValidationResult(
            isValid: true,
            format: "UIImage",
            resolution: size,
            aspectRatio: aspectRatio,
            fileSize: nil,
            errorMessage: nil
        )
    }
    
    // MARK: - Aspect Ratio Calculation
    
    func calculateAspectRatio(_ image: UIImage) -> Float {
        let size = image.size
        return Float(size.width / size.height)
    }
    
    // MARK: - Image Resize
    
    func resizeImage(_ image: UIImage, to aspectRatio: AspectRatio, maxSize: CGSize) -> UIImage? {
        guard let targetRatio = aspectRatio.ratio else {
            // Garder ratio original
            return resizeImageMaintainingAspectRatio(image, maxSize: maxSize)
        }
        
        let originalSize = image.size
        let originalRatio = Float(originalSize.width / originalSize.height)
        
        var newSize: CGSize
        
        if aspectRatio.isPortrait {
            // Portrait: hauteur fixe
            newSize.height = min(maxSize.height, originalSize.height)
            newSize.width = CGFloat(targetRatio) * newSize.height
        } else {
            // Landscape ou square: largeur fixe
            newSize.width = min(maxSize.width, originalSize.width)
            newSize.height = newSize.width / CGFloat(targetRatio)
        }
        
        // Vérifier que la nouvelle taille ne dépasse pas l'originale
        newSize.width = min(newSize.width, originalSize.width)
        newSize.height = min(newSize.height, originalSize.height)
        
        // Redimensionner
        UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    // MARK: - Image Crop
    
    func cropImage(_ image: UIImage, to aspectRatio: AspectRatio) -> UIImage? {
        guard let targetRatio = aspectRatio.ratio else {
            return image // Garder original
        }
        
        let originalSize = image.size
        let originalRatio = Float(originalSize.width / originalSize.height)
        let targetRatioFloat = CGFloat(targetRatio)
        
        var cropRect: CGRect
        
        if originalRatio > targetRatioFloat {
            // Image plus large: crop largeur
            let newWidth = originalSize.height * targetRatioFloat
            let x = (originalSize.width - newWidth) / 2
            cropRect = CGRect(x: x, y: 0, width: newWidth, height: originalSize.height)
        } else {
            // Image plus haute: crop hauteur
            let newHeight = originalSize.width / targetRatioFloat
            let y = (originalSize.height - newHeight) / 2
            cropRect = CGRect(x: 0, y: y, width: originalSize.width, height: newHeight)
        }
        
        // Crop
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    // MARK: - Helper Methods
    
    private func resizeImageMaintainingAspectRatio(_ image: UIImage, maxSize: CGSize) -> UIImage? {
        let originalSize = image.size
        let ratio = min(maxSize.width / originalSize.width, maxSize.height / originalSize.height)
        let newSize = CGSize(width: originalSize.width * ratio, height: originalSize.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

