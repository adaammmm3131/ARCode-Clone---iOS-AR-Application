//
//  QRCodeDesignService.swift
//  ARCodeClone
//
//  Service pour design avancé QR codes (logo, couleurs, coins)
//

import Foundation
import UIKit
import CoreGraphics

protocol QRCodeDesignServiceProtocol {
    func applyBrandDesign(
        to qrCode: UIImage,
        logo: UIImage?,
        primaryColor: UIColor,
        secondaryColor: UIColor,
        cornerStyle: QRCodeCornerStyle,
        size: CGSize
    ) -> UIImage
    func exportToPNG(_ image: UIImage, resolution: CGFloat) -> Data?
    func exportToSVG(_ qrCodeData: String, logo: UIImage?, colors: QRCodeColors, size: CGSize) -> String?
}

enum QRCodeCornerStyle {
    case square
    case rounded(radius: CGFloat)
    case dot
}

struct QRCodeColors {
    let foreground: UIColor
    let background: UIColor
    let logoBackground: UIColor?
}

final class QRCodeDesignService: QRCodeDesignServiceProtocol {
    
    // MARK: - Brand Design Application
    
    func applyBrandDesign(
        to qrCode: UIImage,
        logo: UIImage?,
        primaryColor: UIColor,
        secondaryColor: UIColor,
        cornerStyle: QRCodeCornerStyle,
        size: CGSize
    ) -> UIImage {
        // Redimensionner à taille cible (1024x1024px minimum)
        let targetSize = CGSize(
            width: max(size.width, 1024),
            height: max(size.height, 1024)
        )
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let designedQR = renderer.image { context in
            let rect = CGRect(origin: .zero, size: targetSize)
            
            // Fond
            context.cgContext.setFillColor(secondaryColor.cgColor)
            context.cgContext.fill(rect)
            
            // Appliquer coins arrondis si nécessaire
            let path: CGPath
            switch cornerStyle {
            case .square:
                path = CGPath(rect: rect, transform: nil)
            case .rounded(let radius):
                path = CGPath(
                    roundedRect: rect,
                    cornerWidth: radius,
                    cornerHeight: radius,
                    transform: nil
                )
            case .dot:
                path = CGPath(ellipseIn: rect, transform: nil)
            }
            
            context.cgContext.addPath(path)
            context.cgContext.clip()
            
            // Dessiner QR code
            qrCode.draw(in: rect)
            
            // Ajouter logo si fourni
            if let logo = logo {
                let logoSize = min(targetSize.width, targetSize.height) * 0.18
                let logoRect = CGRect(
                    x: (targetSize.width - logoSize) / 2,
                    y: (targetSize.height - logoSize) / 2,
                    width: logoSize,
                    height: logoSize
                )
                
                // Fond logo si nécessaire
                let logoBg = primaryColor.withAlphaComponent(0.1)
                context.cgContext.setFillColor(logoBg.cgColor)
                context.cgContext.fillEllipse(in: logoRect.insetBy(dx: -8, dy: -8))
                
                logo.draw(in: logoRect)
            }
        }
        
        return designedQR
    }
    
    // MARK: - PNG Export
    
    func exportToPNG(_ image: UIImage, resolution: CGFloat = 1024) -> Data? {
        // Redimensionner si nécessaire
        let targetSize = CGSize(width: resolution, height: resolution)
        let resizedImage: UIImage
        
        if image.size.width != resolution || image.size.height != resolution {
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            resizedImage = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: targetSize))
            }
        } else {
            resizedImage = image
        }
        
        // Exporter en PNG
        return resizedImage.pngData()
    }
    
    // MARK: - SVG Export
    
    func exportToSVG(
        _ qrCodeData: String,
        logo: UIImage?,
        colors: QRCodeColors,
        size: CGSize
    ) -> String? {
        // Générer QR code basique pour extraction pattern
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }
        
        filter.setValue(qrCodeData.data(using: .utf8), forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")
        
        guard let qrCodeImage = filter.outputImage else {
            return nil
        }
        
        // Créer SVG manuellement
        let width = Int(size.width)
        let height = Int(size.height)
        
        var svg = """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg width="\(width)" height="\(height)" xmlns="http://www.w3.org/2000/svg">
            <rect width="\(width)" height="\(height)" fill="\(colors.background.hexString)"/>
        """
        
        // Note: Pour vrai SVG QR code, il faudrait parser le pattern de pixels
        // Pour l'instant, créer un SVG simplifié avec rectangle placeholder
        // Une implémentation complète nécessiterait extraction pattern QR code
        
        svg += """
            <rect x="\(width/2 - 100)" y="\(height/2 - 100)" width="200" height="200" fill="\(colors.foreground.hexString)" opacity="0.1"/>
            <text x="\(width/2)" y="\(height/2)" text-anchor="middle" font-size="20" fill="\(colors.foreground.hexString)">QR Code</text>
        """
        
        // Logo SVG si fourni
        if let logo = logo, let logoData = logo.pngData() {
            let logoBase64 = logoData.base64EncodedString()
            svg += """
                <image x="\(width/2 - 50)" y="\(height/2 - 50)" width="100" height="100" href="data:image/png;base64,\(logoBase64)"/>
            """
        }
        
        svg += "</svg>"
        
        return svg
    }
}

extension UIColor {
    var hexString: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb: Int = (Int)(r * 255) << 16 | (Int)(g * 255) << 8 | (Int)(b * 255) << 0
        
        return String(format: "#%06x", rgb)
    }
}

