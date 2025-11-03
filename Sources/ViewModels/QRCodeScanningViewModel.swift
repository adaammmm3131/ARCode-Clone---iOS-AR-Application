//
//  QRCodeScanningViewModel.swift
//  ARCodeClone
//
//  ViewModel pour scanning QR codes
//

import Foundation
import SwiftUI
import Combine
import AVFoundation

final class QRCodeScanningViewModel: BaseViewModel, ObservableObject {
    @Published var scannedURL: String?
    @Published var isScanning: Bool = false
    @Published var hasCameraPermission: Bool = false
    @Published var isLoadingAR: Bool = false
    @Published var loadingProgress: Double = 0.0
    @Published var loadingMessage: String = ""
    @Published var errorMessage: String?
    @Published var deepLinkResult: DeepLinkResult?
    
    let scanningService: QRCodeScanningServiceProtocol
    private let deepLinkingService: QRCodeDeepLinkingServiceProtocol
    private let assetLoadingService: AssetLoadingServiceProtocol
    let loadingExperienceService: QRCodeLoadingExperienceServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(
        scanningService: QRCodeScanningServiceProtocol,
        deepLinkingService: QRCodeDeepLinkingServiceProtocol,
        assetLoadingService: AssetLoadingServiceProtocol,
        loadingExperienceService: QRCodeLoadingExperienceServiceProtocol
    ) {
        self.scanningService = scanningService
        self.deepLinkingService = deepLinkingService
        self.assetLoadingService = assetLoadingService
        self.loadingExperienceService = loadingExperienceService
        super.init()
        
        checkCameraPermission()
    }
    
    // MARK: - Camera Permission
    
    func checkCameraPermission() {
        scanningService.requestCameraPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.hasCameraPermission = granted
            }
        }
    }
    
    // MARK: - Scanning
    
    func startScanning() {
        guard hasCameraPermission else {
            requestCameraPermission()
            return
        }
        
        isScanning = true
        errorMessage = nil
        scannedURL = nil
        
        scanningService.startScanning { [weak self] result in
            DispatchQueue.main.async {
                self?.isScanning = false
                
                switch result {
                case .success(let url):
                    self?.scannedURL = url
                    self?.handleScannedURL(url)
                    
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func stopScanning() {
        scanningService.stopScanning()
        isScanning = false
    }
    
    func requestCameraPermission() {
        scanningService.requestCameraPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.hasCameraPermission = granted
                if granted {
                    self?.startScanning()
                }
            }
        }
    }
    
    // MARK: - URL Handling
    
    func handleScannedURL(_ url: String) {
        // Traiter URL scannée
        let result = deepLinkingService.handleQRCodeURL(url)
        deepLinkResult = result
        
        if result.shouldOpenAR {
            loadARContent(from: result)
        } else if result.shouldOpenInApp {
            _ = deepLinkingService.openInApp(url: url)
        } else {
            deepLinkingService.openInBrowser(url: url)
        }
    }
    
    // MARK: - AR Content Loading
    
    func loadARContent(from result: DeepLinkResult) {
        guard let arCodeId = result.arCodeId,
              let contentType = result.contentType else {
            errorMessage = "Metadata AR Code manquante"
            return
        }
        
        isLoadingAR = true
        loadingProgress = 0.0
        loadingMessage = "Chargement AR Code..."
        
        // Construire URL asset (en production, depuis API)
        let assetURL = URL(string: "https://ar-code.com/assets/\(arCodeId)")!
        
        Task {
            do {
                let asset = try await assetLoadingService.loadARAsset(
                    url: assetURL,
                    contentType: contentType
                ) { [weak self] progress in
                    DispatchQueue.main.async {
                        self?.loadingProgress = progress
                        self?.loadingMessage = "Chargement \(Int(progress * 100))%..."
                    }
                }
                
                DispatchQueue.main.async {
                    self.isLoadingAR = false
                    self.loadingProgress = 1.0
                    self.loadingMessage = "Prêt!"
                    // Naviguer vers AR view avec asset
                    // Notification pour ouvrir AR view sera gérée par parent view
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.isLoadingAR = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Preloading
    
    func preloadAssets(urls: [URL], contentType: String) {
        loadingExperienceService.preloadAssets(urls: urls, contentType: contentType) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Preload réussi
                    break
                case .failure(let error):
                    // Log error mais ne pas bloquer
                    print("Preload error: \(error.localizedDescription)")
                }
            }
        }
    }
}

