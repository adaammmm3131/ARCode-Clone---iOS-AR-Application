//
//  DependencyContainer.swift
//  ARCodeClone
//
//  Container d'injection de dépendances avec Swinject
//

import Swinject
import Foundation

/// Container principal pour l'injection de dépendances
final class DependencyContainer {
    static let shared = DependencyContainer()
    
    private let container: Container
    
    private init() {
        container = Container()
        registerServices()
    }
    
    /// Enregistre tous les services dans le container
    private func registerServices() {
        // Network Service
        container.register(NetworkServiceProtocol.self) { _ in
            NetworkService()
        }.inObjectScope(.container)
        
        // AR Service
        container.register(ARServiceProtocol.self) { _ in
            ARService()
        }.inObjectScope(.container)
        
        // Storage Service
        container.register(StorageServiceProtocol.self) { _ in
            StorageService()
        }.inObjectScope(.container)
        
        // Analytics Service
        container.register(AnalyticsServiceProtocol.self) { _ in
            AnalyticsService()
        }.inObjectScope(.container)
        
        // Face Filter Services
        container.register(FaceFilterServiceProtocol.self) { _ in
            FaceFilterService()
        }.inObjectScope(.container)
        
        container.register(FaceFilterImageServiceProtocol.self) { _ in
            FaceFilterImageService()
        }.inObjectScope(.transient)
        
        container.register(FaceFilterMappingServiceProtocol.self) { _ in
            FaceFilterMappingService()
        }.inObjectScope(.transient)
        
        container.register(FaceFilterRecordingServiceProtocol.self) { _ in
            FaceFilterRecordingService()
        }.inObjectScope(.transient)
        
        container.register(FaceFilterCameraServiceProtocol.self) { _ in
            FaceFilterCameraService()
        }.inObjectScope(.container)
        
        // Face Filter ViewModel
        container.register(FaceFilterViewModel.self) { resolver in
            FaceFilterViewModel(
                faceFilterService: resolver.resolve(FaceFilterServiceProtocol.self)!,
                arService: resolver.resolve(ARServiceProtocol.self)!
            )
        }.inObjectScope(.transient)
        
        // OCR Service
        container.register(OCRServiceProtocol.self) { _ in
            OCRService()
        }.inObjectScope(.container)
        
        // Segmentation Service
        container.register(SegmentationServiceProtocol.self) { _ in
            SegmentationService()
        }.inObjectScope(.container)
        
        // AI Analysis Service
        container.register(AIAnalysisServiceProtocol.self) { resolver in
            AIAnalysisService(
                networkService: resolver.resolve(NetworkServiceProtocol.self)!
            )
        }.inObjectScope(.container)
        
        // AI Code ViewModel
        container.register(AICodeViewModel.self) { resolver in
            AICodeViewModel(
                aiAnalysisService: resolver.resolve(AIAnalysisServiceProtocol.self)!,
                ocrService: resolver.resolve(OCRServiceProtocol.self)!,
                segmentationService: resolver.resolve(SegmentationServiceProtocol.self)!
            )
        }.inObjectScope(.transient)
        
        // Virtual Try-On Service
        container.register(VirtualTryOnServiceProtocol.self) { resolver in
            VirtualTryOnService(
                networkService: resolver.resolve(NetworkServiceProtocol.self)!,
                segmentationService: resolver.resolve(SegmentationServiceProtocol.self)!
            )
        }.inObjectScope(.container)
        
        // Prompt Generator Service
        container.register(PromptGeneratorServiceProtocol.self) { _ in
            PromptGeneratorService()
        }.inObjectScope(.container)
        
        // AR Video Player Services
        container.register(ARVideoPlayerServiceProtocol.self) { _ in
            ARVideoPlayerService()
        }.inObjectScope(.container)
        
        container.register(ARVideoControlsServiceProtocol.self) { _ in
            ARVideoControlsService()
        }.inObjectScope(.container)
        
        container.register(ARVideoGestureServiceProtocol.self) { _ in
            ARVideoGestureService()
        }.inObjectScope(.container)
        
        container.register(ARVideoFormatServiceProtocol.self) { _ in
            ARVideoFormatService()
        }.inObjectScope(.container)
        
        // AR Video ViewModel
        container.register(ARVideoViewModel.self) { resolver in
            ARVideoViewModel(
                arService: resolver.resolve(ARServiceProtocol.self)!,
                videoPlayerService: resolver.resolve(ARVideoPlayerServiceProtocol.self)!,
                controlsService: resolver.resolve(ARVideoControlsServiceProtocol.self)!,
                gestureService: resolver.resolve(ARVideoGestureServiceProtocol.self)!,
                formatService: resolver.resolve(ARVideoFormatServiceProtocol.self)!
            )
        }.inObjectScope(.transient)
        
        // AR Portal Services
        container.register(ARPortalServiceProtocol.self) { _ in
            ARPortalService()
        }.inObjectScope(.container)
        
        container.register(ARPortalControlsServiceProtocol.self) { _ in
            ARPortalControlsService()
        }.inObjectScope(.container)
        
        container.register(ARPortalFormatServiceProtocol.self) { _ in
            ARPortalFormatService()
        }.inObjectScope(.container)
        
        container.register(ARPortalTransitionServiceProtocol.self) { _ in
            ARPortalTransitionService()
        }.inObjectScope(.container)
        
        // AR Portal ViewModel
        container.register(ARPortalViewModel.self) { resolver in
            ARPortalViewModel(
                arService: resolver.resolve(ARServiceProtocol.self)!,
                portalService: resolver.resolve(ARPortalServiceProtocol.self)!,
                controlsService: resolver.resolve(ARPortalControlsServiceProtocol.self)!,
                formatService: resolver.resolve(ARPortalFormatServiceProtocol.self)!,
                transitionService: resolver.resolve(ARPortalTransitionServiceProtocol.self)!
            )
        }.inObjectScope(.transient)
        
        // AR Text Services
        container.register(ARText3DServiceProtocol.self) { _ in
            ARText3DService()
        }.inObjectScope(.container)
        
        container.register(ARTextFontServiceProtocol.self) { _ in
            ARTextFontService()
        }.inObjectScope(.container)
        
        container.register(ARTextColorServiceProtocol.self) { _ in
            ARTextColorService()
        }.inObjectScope(.container)
        
        container.register(ARTextGestureServiceProtocol.self) { _ in
            ARTextGestureService()
        }.inObjectScope(.container)
        
        // AR Text ViewModel
        container.register(ARTextViewModel.self) { resolver in
            ARTextViewModel(
                arService: resolver.resolve(ARServiceProtocol.self)!,
                text3DService: resolver.resolve(ARText3DServiceProtocol.self)!,
                fontService: resolver.resolve(ARTextFontServiceProtocol.self)!,
                colorService: resolver.resolve(ARTextColorServiceProtocol.self)!,
                gestureService: resolver.resolve(ARTextGestureServiceProtocol.self)!
            )
        }.inObjectScope(.transient)
        
        // AR Photo Frame Services
        container.register(ARPhotoFrameServiceProtocol.self) { _ in
            ARPhotoFrameService()
        }.inObjectScope(.container)
        
        container.register(ARPhotoFrameImageServiceProtocol.self) { _ in
            ARPhotoFrameImageService()
        }.inObjectScope(.container)
        
        container.register(ARPhotoFramePlacementServiceProtocol.self) { _ in
            ARPhotoFramePlacementService()
        }.inObjectScope(.container)
        
        container.register(ARPhotoFrameGestureServiceProtocol.self) { _ in
            ARPhotoFrameGestureService()
        }.inObjectScope(.container)
        
        // AR Photo Frame ViewModel
        container.register(ARPhotoFrameViewModel.self) { resolver in
            ARPhotoFrameViewModel(
                arService: resolver.resolve(ARServiceProtocol.self)!,
                frameService: resolver.resolve(ARPhotoFrameServiceProtocol.self)!,
                imageService: resolver.resolve(ARPhotoFrameImageServiceProtocol.self)!,
                placementService: resolver.resolve(ARPhotoFramePlacementServiceProtocol.self)!,
                gestureService: resolver.resolve(ARPhotoFrameGestureServiceProtocol.self)!
            )
        }.inObjectScope(.transient)
        
        // AR Logo Services
        container.register(ARLogoUploadServiceProtocol.self) { _ in
            ARLogoUploadService()
        }.inObjectScope(.container)
        
        container.register(ARLogo3DExtrusionServiceProtocol.self) { _ in
            ARLogo3DExtrusionService()
        }.inObjectScope(.container)
        
        container.register(ARLogoAnimationServiceProtocol.self) { _ in
            ARLogoAnimationService()
        }.inObjectScope(.container)
        
        // AR Logo ViewModel
        container.register(ARLogoViewModel.self) { resolver in
            ARLogoViewModel(
                uploadService: resolver.resolve(ARLogoUploadServiceProtocol.self)!,
                extrusionService: resolver.resolve(ARLogo3DExtrusionServiceProtocol.self)!,
                animationService: resolver.resolve(ARLogoAnimationServiceProtocol.self)!,
                arService: resolver.resolve(ARServiceProtocol.self)!
            )
        }.inObjectScope(.transient)
        
        // AR Splat Services
        container.register(ARSplatUploadServiceProtocol.self) { _ in
            ARSplatUploadService()
        }.inObjectScope(.container)
        
        container.register(ARSplatProcessingServiceProtocol.self) { resolver in
            ARSplatProcessingService(
                networkService: resolver.resolve(NetworkServiceProtocol.self)!,
                baseURL: "http://localhost:5000"
            )
        }.inObjectScope(.container)
        
        container.register(ARSplatViewerServiceProtocol.self) { _ in
            ARSplatViewerService()
        }.inObjectScope(.container)
        
        // AR Splat ViewModel
        container.register(ARSplatViewModel.self) { resolver in
            ARSplatViewModel(
                uploadService: resolver.resolve(ARSplatUploadServiceProtocol.self)!,
                processingService: resolver.resolve(ARSplatProcessingServiceProtocol.self)!,
                viewerService: resolver.resolve(ARSplatViewerServiceProtocol.self)!
            )
        }.inObjectScope(.transient)
        
        // Authentication Service
        container.register(AuthenticationServiceProtocol.self) { resolver in
            AuthenticationService(
                networkService: resolver.resolve(NetworkServiceProtocol.self)!,
                clientId: "default_client_id", // En production, depuis config
                clientSecret: "default_client_secret"
            )
        }.inObjectScope(.container)
        
        // AR Data API Services
        container.register(ARDataAPIServiceProtocol.self) { resolver in
            ARDataAPIService(
                networkService: resolver.resolve(NetworkServiceProtocol.self)!,
                authService: resolver.resolve(AuthenticationServiceProtocol.self)!
            )
        }.inObjectScope(.container)
        
        container.register(ARDataTemplateServiceProtocol.self) { _ in
            ARDataTemplateService()
        }.inObjectScope(.container)
        
        // AR Data ViewModel
        container.register(ARDataViewModel.self) { resolver in
            ARDataViewModel(
                authService: resolver.resolve(AuthenticationServiceProtocol.self)!,
                dataService: resolver.resolve(ARDataAPIServiceProtocol.self)!,
                templateService: resolver.resolve(ARDataTemplateServiceProtocol.self)!
            )
        }.inObjectScope(.transient)
        
        // QR Code Services
        container.register(QRCodeGenerationServiceProtocol.self) { _ in
            QRCodeGenerationService()
        }.inObjectScope(.container)
        
        container.register(QRCodeURLServiceProtocol.self) { _ in
            QRCodeURLService()
        }.inObjectScope(.container)
        
        container.register(QRCodeDesignServiceProtocol.self) { _ in
            QRCodeDesignService()
        }.inObjectScope(.container)
        
        // QR Code ViewModel
        container.register(QRCodeViewModel.self) { resolver in
            QRCodeViewModel(
                qrGenerationService: resolver.resolve(QRCodeGenerationServiceProtocol.self)!,
                urlService: resolver.resolve(QRCodeURLServiceProtocol.self)!,
                designService: resolver.resolve(QRCodeDesignServiceProtocol.self)!
            )
        }.inObjectScope(.transient)
        
        // QR Code Scanning Services
        container.register(QRCodeScanningServiceProtocol.self) { _ in
            QRCodeScanningService()
        }.inObjectScope(.container)
        
        container.register(QRCodeDeepLinkingServiceProtocol.self) { resolver in
            QRCodeDeepLinkingService(
                urlService: resolver.resolve(QRCodeURLServiceProtocol.self)!
            )
        }.inObjectScope(.container)
        
        container.register(AssetLoadingServiceProtocol.self) { resolver in
            AssetLoadingService(
                networkService: resolver.resolve(NetworkServiceProtocol.self)!
            )
        }.inObjectScope(.container)
        
        container.register(QRCodeLoadingExperienceServiceProtocol.self) { _ in
            QRCodeLoadingExperienceService()
        }.inObjectScope(.container)
        
        container.register(LODServiceProtocol.self) { _ in
            LODService()
        }.inObjectScope(.container)
        
        // QR Code Scanning ViewModel
        container.register(QRCodeScanningViewModel.self) { resolver in
            QRCodeScanningViewModel(
                scanningService: resolver.resolve(QRCodeScanningServiceProtocol.self)!,
                deepLinkingService: resolver.resolve(QRCodeDeepLinkingServiceProtocol.self)!,
                assetLoadingService: resolver.resolve(AssetLoadingServiceProtocol.self)!,
                loadingExperienceService: resolver.resolve(QRCodeLoadingExperienceServiceProtocol.self)!
            )
        }.inObjectScope(.transient)
        
        // Dashboard ViewModels
        container.register(DashboardViewModel.self) { resolver in
            DashboardViewModel(
                networkService: resolver.resolve(NetworkServiceProtocol.self)!
            )
        }.inObjectScope(.transient)
        
        container.register(ARCodeManagerViewModel.self) { resolver in
            ARCodeManagerViewModel(
                networkService: resolver.resolve(NetworkServiceProtocol.self)!
            )
        }.inObjectScope(.transient)
        
        container.register(AnalyticsViewModel.self) { resolver in
            AnalyticsViewModel(
                analyticsService: resolver.resolve(AnalyticsServiceProtocol.self)!
            )
        }.inObjectScope(.transient)
        
        // AR Rendering Services
        container.register(ARRenderingPipelineProtocol.self) { _ in
            ARRenderingPipeline()
        }.inObjectScope(.container)
        
        container.register(ARRenderingOptimizationProtocol.self) { _ in
            ARRenderingOptimization()
        }.inObjectScope(.container)
        
        container.register(ARGestureManagerProtocol.self) { _ in
            ARGestureManager()
        }.inObjectScope(.container)
        
        container.register(ARPerformanceMonitorProtocol.self) { resolver in
            ARPerformanceMonitor(
                arView: nil, // Sera injecté dynamiquement
                renderingPipeline: resolver.resolve(ARRenderingPipelineProtocol.self)
            )
        }.inObjectScope(.transient)
        
        // CTA Links Services
        container.register(CTALinkServiceProtocol.self) { resolver in
            CTALinkService(
                networkService: resolver.resolve(NetworkServiceProtocol.self)!
            )
        }.inObjectScope(.container)
        
        container.register(ABTestingServiceProtocol.self) { resolver in
            ABTestingService(
                networkService: resolver.resolve(NetworkServiceProtocol.self)!
            )
        }.inObjectScope(.container)
        
        // Workspace Services
        container.register(WorkspaceServiceProtocol.self) { resolver in
            WorkspaceService(
                networkService: resolver.resolve(NetworkServiceProtocol.self)!
            )
        }.inObjectScope(.container)
        
        // White Label Services
        container.register(WhiteLabelServiceProtocol.self) { resolver in
            WhiteLabelService(
                networkService: resolver.resolve(NetworkServiceProtocol.self)!
            )
        }.inObjectScope(.container)
        
        // ViewModels
        container.register(CTALinkViewModel.self) { resolver in
            CTALinkViewModel(
                arCodeId: "", // Sera injecté
                ctaLinkService: resolver.resolve(CTALinkServiceProtocol.self)!,
                abTestingService: resolver.resolve(ABTestingServiceProtocol.self)!
            )
        }.inObjectScope(.transient)
        
        container.register(WorkspaceViewModel.self) { resolver in
            WorkspaceViewModel(
                workspaceService: resolver.resolve(WorkspaceServiceProtocol.self)!
            )
        }.inObjectScope(.transient)
        
        // AR Experience ViewModel
        container.register(ARExperienceViewModel.self) { resolver in
            ARExperienceViewModel(
                renderingPipeline: resolver.resolve(ARRenderingPipelineProtocol.self)!,
                optimization: resolver.resolve(ARRenderingOptimizationProtocol.self)!,
                gestureManager: resolver.resolve(ARGestureManagerProtocol.self)!,
                performanceMonitor: resolver.resolve(ARPerformanceMonitorProtocol.self)!,
                ctaLinkService: resolver.resolve(CTALinkServiceProtocol.self)!,
                abTestingService: resolver.resolve(ABTestingServiceProtocol.self)!,
                arCodeId: nil // Sera injecté
            )
        }.inObjectScope(.transient)
    }
    
    /// Résout une dépendance
    func resolve<Service>(_ serviceType: Service.Type) -> Service {
        guard let service = container.resolve(serviceType) else {
            fatalError("Service \(serviceType) not registered")
        }
        return service
    }
}

