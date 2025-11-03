//
//  DashboardViewModel.swift
//  ARCodeClone
//
//  ViewModel pour Dashboard Home
//

import Foundation
import SwiftUI
import Combine

struct DashboardStats {
    var totalARCodes: Int = 0
    var totalScans: Int = 0
    var totalViews: Int = 0
    var activeARCodes: Int = 0
}

struct ModuleCard: Identifiable {
    let id: String
    let title: String
    let icon: String
    let color: Color
    let description: String
    let destination: AnyView
}

final class DashboardViewModel: BaseViewModel, ObservableObject {
    @Published var stats: DashboardStats = DashboardStats()
    @Published var recentARCodes: [ARCode] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Modules disponibles
    @Published var modules: [ModuleCard] = []
    
    private let networkService: NetworkServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
        super.init()
        
        setupModules()
        loadDashboardData()
    }
    
    // MARK: - Modules Setup
    
    private func setupModules() {
        modules = [
            ModuleCard(
                id: "3d_upload",
                title: "3D Upload",
                icon: "cube.box",
                color: ARColors.primary,
                description: "Upload et traitement 3D",
                destination: AnyView(Text("3D Upload"))
            ),
            ModuleCard(
                id: "object_capture",
                title: "Object Capture",
                icon: "camera.metering.center.weighted",
                color: ARColors.secondary,
                description: "Capture d'objets 3D",
                destination: AnyView(Text("Object Capture"))
            ),
            ModuleCard(
                id: "ar_face",
                title: "AR Face Filter",
                icon: "face.smiling",
                color: ARColors.accent,
                description: "Filtres faciaux AR",
                destination: AnyView(Text("AR Face"))
            ),
            ModuleCard(
                id: "ai_code",
                title: "AI Code",
                icon: "brain.head.profile",
                color: ARColors.info,
                description: "Code IA vision",
                destination: AnyView(Text("AI Code"))
            ),
            ModuleCard(
                id: "ar_video",
                title: "AR Video",
                icon: "video.fill",
                color: ARColors.warning,
                description: "Vidéo en AR",
                destination: AnyView(Text("AR Video"))
            ),
            ModuleCard(
                id: "ar_portal",
                title: "AR Portal",
                icon: "door.left.hand.open",
                color: ARColors.success,
                description: "Portails 360°",
                destination: AnyView(Text("AR Portal"))
            ),
            ModuleCard(
                id: "ar_text",
                title: "AR Text",
                icon: "textformat",
                color: ARColors.primary,
                description: "Texte 3D AR",
                destination: AnyView(Text("AR Text"))
            ),
            ModuleCard(
                id: "ar_photo",
                title: "AR Photo Frame",
                icon: "photo.frame",
                color: ARColors.secondary,
                description: "Cadres photo AR",
                destination: AnyView(Text("AR Photo"))
            ),
            ModuleCard(
                id: "ar_logo",
                title: "AR Logo",
                icon: "signature",
                color: ARColors.accent,
                description: "Logo 3D AR",
                destination: AnyView(Text("AR Logo"))
            ),
            ModuleCard(
                id: "ar_splat",
                title: "AR Splat",
                icon: "sparkles",
                color: ARColors.info,
                description: "Gaussian Splatting",
                destination: AnyView(Text("AR Splat"))
            ),
            ModuleCard(
                id: "qr_generator",
                title: "QR Generator",
                icon: "qrcode",
                color: ARColors.success,
                description: "Génération QR codes",
                destination: AnyView(Text("QR Generator"))
            ),
            ModuleCard(
                id: "qr_scanner",
                title: "QR Scanner",
                icon: "qrcode.viewfinder",
                color: ARColors.warning,
                description: "Scanner QR codes",
                destination: AnyView(Text("QR Scanner"))
            )
        ]
    }
    
    // MARK: - Data Loading
    
    func loadDashboardData() {
        isLoading = true
        errorMessage = nil
        
        // Simuler chargement données
        // En production, appeler API pour récupérer stats et AR codes récents
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.stats = DashboardStats(
                totalARCodes: 42,
                totalScans: 1250,
                totalViews: 3500,
                activeARCodes: 28
            )
            
            // Charger AR codes récents (simulé)
            self?.recentARCodes = self?.generateMockARCodes() ?? []
            self?.isLoading = false
        }
    }
    
    private func generateMockARCodes() -> [ARCode] {
        // Générer données mock pour preview
        return []
    }
}

