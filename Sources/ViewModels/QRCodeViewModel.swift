//
//  QRCodeViewModel.swift
//  ARCodeClone
//
//  ViewModel pour génération QR codes
//

import Foundation
import SwiftUI
import Combine
import UIKit

final class QRCodeViewModel: BaseViewModel, ObservableObject {
    @Published var arCodeId: String = ""
    @Published var contentType: String = "object_capture"
    @Published var qrCodeImage: UIImage?
    @Published var shortURL: String = ""
    @Published var qrCodeSize: CGSize = CGSize(width: 1024, height: 1024)
    @Published var logoImage: UIImage?
    @Published var foregroundColor: Color = .black
    @Published var backgroundColor: Color = .white
    @Published var cornerRadius: CGFloat = 0
    @Published var selectedFormat: ExportFormat = .png
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let qrGenerationService: QRCodeGenerationServiceProtocol
    private let urlService: QRCodeURLServiceProtocol
    private let designService: QRCodeDesignServiceProtocol
    
    enum ExportFormat: String, CaseIterable {
        case png = "PNG"
        case svg = "SVG"
        
        var id: String { self.rawValue }
    }
    
    init(
        qrGenerationService: QRCodeGenerationServiceProtocol,
        urlService: QRCodeURLServiceProtocol,
        designService: QRCodeDesignServiceProtocol
    ) {
        self.qrGenerationService = qrGenerationService
        self.urlService = urlService
        self.designService = designService
        super.init()
    }
    
    // MARK: - QR Code Generation
    
    func generateQRCode() {
        guard !arCodeId.isEmpty else {
            errorMessage = "AR Code ID requis"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Créer URL court avec metadata
        let url = urlService.createShortURL(
            arCodeId: arCodeId,
            contentType: contentType,
            assetId: nil,
            params: nil
        )
        
        shortURL = url
        
        // Générer QR code
        qrGenerationService.generateQRCode(
            data: url,
            size: qrCodeSize,
            correctionLevel: .high, // Level H (30%)
            logo: logoImage,
            foregroundColor: UIColor(foregroundColor),
            backgroundColor: UIColor(backgroundColor),
            cornerRadius: cornerRadius
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let image):
                    // Appliquer design brand
                    if let logo = self?.logoImage,
                       let designedImage = self?.designService.applyBrandDesign(
                           to: image,
                           logo: logo,
                           primaryColor: UIColor(self?.foregroundColor ?? .black),
                           secondaryColor: UIColor(self?.backgroundColor ?? .white),
                           cornerStyle: self?.cornerRadius ?? 0 > 0 ? .rounded(radius: self?.cornerRadius ?? 0) : .square,
                           size: self?.qrCodeSize ?? CGSize(width: 1024, height: 1024)
                       ) {
                        self?.qrCodeImage = designedImage
                    } else {
                        self?.qrCodeImage = image
                    }
                    
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Export
    
    func exportQRCode() -> Data? {
        guard let image = qrCodeImage else {
            return nil
        }
        
        switch selectedFormat {
        case .png:
            return designService.exportToPNG(image, resolution: qrCodeSize.width)
        case .svg:
            return designService.exportToSVG(
                shortURL,
                logo: logoImage,
                colors: QRCodeColors(
                    foreground: UIColor(foregroundColor),
                    background: UIColor(backgroundColor),
                    logoBackground: nil
                ),
                size: qrCodeSize
            )?.data(using: .utf8)
        }
    }
    
    // MARK: - Logo Selection
    
    func setLogo(_ image: UIImage?) {
        logoImage = image
    }
    
    // MARK: - Reset
    
    func reset() {
        qrCodeImage = nil
        shortURL = ""
        errorMessage = nil
        isLoading = false
    }
}









