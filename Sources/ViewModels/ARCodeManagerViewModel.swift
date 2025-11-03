//
//  ARCodeManagerViewModel.swift
//  ARCodeClone
//
//  ViewModel pour AR Code Manager
//

import Foundation
import SwiftUI
import Combine

enum ViewMode {
    case grid
    case list
}

enum FilterType: String, CaseIterable {
    case all = "Tous"
    case objectCapture = "Object Capture"
    case faceFilter = "Face Filter"
    case aiCode = "AI Code"
    case video = "Video"
    case portal = "Portal"
    case text = "Text"
    case photo = "Photo"
    case logo = "Logo"
    case splat = "Splat"
    case data = "Data"
}

enum FilterStatus: String, CaseIterable {
    case all = "Tous"
    case active = "Actifs"
    case inactive = "Inactifs"
    case processing = "En traitement"
}

final class ARCodeManagerViewModel: BaseViewModel, ObservableObject {
    @Published var arCodes: [ARCode] = []
    @Published var filteredARCodes: [ARCode] = []
    @Published var viewMode: ViewMode = .grid
    @Published var selectedFilterType: FilterType = .all
    @Published var selectedFilterStatus: FilterStatus = .all
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedARCode: ARCode?
    
    private let networkService: NetworkServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
        super.init()
        
        loadARCodes()
        
        // Observer search text et filters
        $searchText
            .combineLatest($selectedFilterType, $selectedFilterStatus)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
    func loadARCodes() {
        isLoading = true
        errorMessage = nil
        
        // Simuler chargement (en production, appeler API)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            // Charger AR codes depuis API
            self?.arCodes = self?.generateMockARCodes() ?? []
            self?.applyFilters()
            self?.isLoading = false
        }
    }
    
    // MARK: - Filtering
    
    private func applyFilters() {
        var filtered = arCodes
        
        // Filter by type
        if selectedFilterType != .all {
            let typeRawValue = selectedFilterType.rawValue.lowercased().replacingOccurrences(of: " ", with: "_")
            filtered = filtered.filter { 
                let codeTypeRawValue = $0.type.rawValue
                // Mapper FilterType vers ARCodeType
                switch selectedFilterType {
                case .objectCapture:
                    return codeTypeRawValue == "object_capture"
                case .faceFilter:
                    return codeTypeRawValue == "face_filter"
                case .aiCode:
                    return codeTypeRawValue == "ai_code"
                case .video:
                    return codeTypeRawValue == "video"
                case .portal:
                    return codeTypeRawValue == "portal"
                case .text:
                    return codeTypeRawValue == "text"
                case .photo:
                    return codeTypeRawValue == "photo"
                case .logo:
                    return codeTypeRawValue == "logo"
                case .splat:
                    return codeTypeRawValue == "splat"
                case .data:
                    return codeTypeRawValue == "data"
                case .all:
                    return true
                }
            }
        }
        
        // Filter by status
        if selectedFilterStatus != .all {
            // TODO: Implémenter filtre status selon metadata
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                ($0.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        filteredARCodes = filtered
    }
    
    // MARK: - Actions
    
    func editARCode(_ arCode: ARCode) {
        selectedARCode = arCode
        // Naviguer vers edit view
    }
    
    func duplicateARCode(_ arCode: ARCode) {
        // Dupliquer AR code
        var duplicated = arCode
        duplicated.id = UUID().uuidString
        duplicated.title = arCode.title + " (Copie)"
        duplicated.createdAt = Date()
        
        arCodes.append(duplicated)
        applyFilters()
    }
    
    func deleteARCode(_ arCode: ARCode) {
        arCodes.removeAll { $0.id == arCode.id }
        applyFilters()
    }
    
    func shareARCode(_ arCode: ARCode) {
        // Partager QR code ou URL
        // TODO: Implémenter share sheet
    }
    
    // MARK: - Helper
    
    private func generateMockARCodes() -> [ARCode] {
        return []
    }
}

