//
//  QRCodeGenerationService.swift
//  ARCodeClone
//
//  Service pour génération QR codes avec CoreImage CIQRCodeGenerator
//

import Foundation
import CoreImage
import UIKit

protocol QRCodeGenerationServiceProtocol {
    func generateQRCode(
        data: String,
        size: CGSize,
        correctionLevel: QRCodeErrorCorrection,
        logo: UIImage?,
        foregroundColor: UIColor,
        backgroundColor: UIColor,
        cornerRadius: CGFloat,
        completion: @escaping (Result<UIImage, Error>) -> Void
    )
    func estimateQRCodeVersion(dataSize: Int) -> Int
}

enum QRCodeErrorCorrection: String {
    case low = "L"      // ~7% recovery
    case medium = "M"   // ~15% recovery
    case quartile = "Q" // ~25% recovery
    case high = "H"     // ~30% recovery (niveau H requis)
    
    var ciFilterValue: String {
        return self.rawValue
    }
}

enum QRCodeGenerationError: LocalizedError {
    case dataTooLarge
    case invalidSize
    case generationFailed
    case logoIntegrationFailed
    
    var errorDescription: String? {
        switch self {
        case .dataTooLarge:
            return "Données trop volumineuses pour QR code (max version 40)"
        case .invalidSize:
            return "Taille d'image invalide"
        case .generationFailed:
            return "Échec génération QR code"
        case .logoIntegrationFailed:
            return "Échec intégration logo"
        }
    }
}

final class QRCodeGenerationService: QRCodeGenerationServiceProtocol {
    private let context: CIContext
    
    init() {
        // Utiliser GPU si disponible
        self.context = CIContext(options: [.useSoftwareRenderer: false])
    }
    
    // MARK: - QR Code Generation
    
    func generateQRCode(
        data: String,
        size: CGSize,
        correctionLevel: QRCodeErrorCorrection = .high,
        logo: UIImage? = nil,
        foregroundColor: UIColor = .black,
        backgroundColor: UIColor = .white,
        cornerRadius: CGFloat = 0,
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) {
        // Valider taille
        guard size.width > 0 && size.height > 0 else {
            completion(.failure(QRCodeGenerationError.invalidSize))
            return
        }
        
        // Estimer version nécessaire
        let estimatedVersion = estimateQRCodeVersion(dataSize: data.utf8.count)
        guard estimatedVersion <= 40 else {
            completion(.failure(QRCodeGenerationError.dataTooLarge))
            return
        }
        
        // Générer QR code avec CoreImage
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            completion(.failure(QRCodeGenerationError.generationFailed))
            return
        }
        
        // Configuration filtre
        filter.setValue(data.data(using: .utf8), forKey: "inputMessage")
        filter.setValue(correctionLevel.ciFilterValue, forKey: "inputCorrectionLevel")
        
        // Générer image QR code
        guard let qrCodeImage = filter.outputImage else {
            completion(.failure(QRCodeGenerationError.generationFailed))
            return
        }
        
        // Scale up pour résolution haute (1024x1024px minimum)
        let scaleX = size.width / qrCodeImage.extent.width
        let scaleY = size.height / qrCodeImage.extent.height
        let scaledImage = qrCodeImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        // Appliquer couleurs
        let coloredImage = applyColors(
            to: scaledImage,
            foregroundColor: foregroundColor,
            backgroundColor: backgroundColor
        )
        
        // Appliquer coins arrondis si demandé
        let roundedImage = cornerRadius > 0
            ? applyCornerRadius(to: coloredImage, radius: cornerRadius)
            : coloredImage
        
        // Intégrer logo si fourni
        let finalImage = logo != nil
            ? integrateLogo(roundedImage, logo: logo!, size: size)
            : roundedImage
        
        // Convertir CIImage en UIImage
        guard let cgImage = context.createCGImage(finalImage, from: finalImage.extent) else {
            completion(.failure(QRCodeGenerationError.generationFailed))
            return
        }
        
        let qrCodeUIImage = UIImage(cgImage: cgImage)
        completion(.success(qrCodeUIImage))
    }
    
    // MARK: - Version Estimation
    
    func estimateQRCodeVersion(dataSize: Int) -> Int {
        // Estimation version QR code selon taille données
        // Version 10-40 supportées
        // Capacité selon error correction level H (~30%)
        
        // Capacités approximatives version H (bytes):
        let capacities: [Int: Int] = [
            10: 324, 11: 370, 12: 417, 13: 465, 14: 523, 15: 586,
            16: 652, 17: 722, 18: 796, 19: 871, 20: 991,
            21: 1085, 22: 1156, 23: 1258, 24: 1364, 25: 1474,
            26: 1588, 27: 1706, 28: 1828, 29: 1921, 30: 2051,
            31: 2185, 32: 2323, 33: 2465, 34: 2611, 35: 2761,
            36: 2876, 37: 3034, 38: 3196, 39: 3362, 40: 3532
        ]
        
        // Trouver version minimale qui peut contenir les données
        for version in 10...40 {
            if let capacity = capacities[version], capacity >= dataSize {
                return version
            }
        }
        
        return 40 // Max version
    }
    
    // MARK: - Color Application
    
    private func applyColors(
        to image: CIImage,
        foregroundColor: UIColor,
        backgroundColor: UIColor
    ) -> CIImage {
        // Créer filtre de couleur
        guard let colorFilter = CIFilter(name: "CIFalseColor") else {
            return image
        }
        
        // Convertir couleurs en CIColor
        let fgColor = CIColor(color: foregroundColor)
        let bgColor = CIColor(color: backgroundColor)
        
        colorFilter.setValue(image, forKey: kCIInputImageKey)
        colorFilter.setValue(fgColor, forKey: "inputColor0")
        colorFilter.setValue(bgColor, forKey: "inputColor1")
        
        return colorFilter.outputImage ?? image
    }
    
    // MARK: - Corner Radius
    
    private func applyCornerRadius(to image: CIImage, radius: CGFloat) -> CIImage {
        guard let roundedFilter = CIFilter(name: "CIRoundedRectangleGenerator") else {
            return image
        }
        
        let extent = image.extent
        let radiusInImageSpace = radius * (extent.width / 1024) // Scale radius
        
        roundedFilter.setValue(CIVector(x: extent.minX + radiusInImageSpace, y: extent.minY + radiusInImageSpace, z: extent.width - radiusInImageSpace * 2, w: extent.height - radiusInImageSpace * 2), forKey: "inputExtent")
        roundedFilter.setValue(radiusInImageSpace, forKey: "inputRadius")
        roundedFilter.setValue(CIColor.white, forKey: "inputColor")
        
        guard let mask = roundedFilter.outputImage else {
            return image
        }
        
        // Appliquer masque pour coins arrondis
        guard let blendFilter = CIFilter(name: "CIBlendWithMask") else {
            return image
        }
        
        blendFilter.setValue(image, forKey: kCIInputImageKey)
        blendFilter.setValue(mask, forKey: kCIInputMaskImageKey)
        
        return blendFilter.outputImage ?? image
    }
    
    // MARK: - Logo Integration
    
    private func integrateLogo(_ qrCodeImage: CIImage, logo: UIImage, size: CGSize) -> CIImage {
        // Convertir logo en CIImage
        guard let logoCIImage = CIImage(image: logo) else {
            return qrCodeImage
        }
        
        // Calculer taille logo (15-20% de la taille QR code recommandé)
        let logoSize = min(size.width, size.height) * 0.18
        let logoRect = CGRect(
            x: (size.width - logoSize) / 2,
            y: (size.height - logoSize) / 2,
            width: logoSize,
            height: logoSize
        )
        
        // Redimensionner logo
        let scaleX = logoSize / logoCIImage.extent.width
        let scaleY = logoSize / logoCIImage.extent.height
        let scaledLogo = logoCIImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        // Déplacer logo au centre
        let centeredLogo = scaledLogo.transformed(by: CGAffineTransform(
            translationX: logoRect.origin.x,
            y: logoRect.origin.y
        ))
        
        // Compositer logo sur QR code
        guard let compositeFilter = CIFilter(name: "CISourceOverCompositing") else {
            return qrCodeImage
        }
        
        compositeFilter.setValue(centeredLogo, forKey: kCIInputImageKey)
        compositeFilter.setValue(qrCodeImage, forKey: kCIInputBackgroundImageKey)
        
        return compositeFilter.outputImage ?? qrCodeImage
    }
}









