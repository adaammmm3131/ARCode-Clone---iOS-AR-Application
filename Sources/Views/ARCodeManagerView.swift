//
//  ARCodeManagerView.swift
//  ARCodeClone
//
//  Vue pour gérer AR Codes (liste, grid, filtres, actions)
//

import SwiftUI

struct ARCodeManagerView: View {
    @StateObject var viewModel: ARCodeManagerViewModel
    @State private var showDeleteConfirmation: Bool = false
    @State private var arCodeToDelete: ARCode?
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar + Filters
            VStack(spacing: 12) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(ARColors.textSecondary)
                    
                    TextField("Rechercher...", text: $viewModel.searchText)
                        .font(ARTypography.bodyMedium)
                }
                .padding(12)
                .background(ARColors.surface)
                .cornerRadius(12)
                
                // Filters
                HStack(spacing: 12) {
                    // Type Filter
                    Menu {
                        ForEach(FilterType.allCases, id: \.self) { type in
                            Button(type.rawValue) {
                                viewModel.selectedFilterType = type
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.selectedFilterType.rawValue)
                            Image(systemName: "chevron.down")
                        }
                        .font(ARTypography.labelMedium)
                        .foregroundColor(ARColors.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(ARColors.primary.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Status Filter
                    Menu {
                        ForEach(FilterStatus.allCases, id: \.self) { status in
                            Button(status.rawValue) {
                                viewModel.selectedFilterStatus = status
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.selectedFilterStatus.rawValue)
                            Image(systemName: "chevron.down")
                        }
                        .font(ARTypography.labelMedium)
                        .foregroundColor(ARColors.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(ARColors.primary.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    // View Mode Toggle
                    HStack(spacing: 0) {
                        Button(action: {
                            viewModel.viewMode = .grid
                        }) {
                            Image(systemName: "square.grid.2x2")
                                .padding(8)
                                .foregroundColor(viewModel.viewMode == .grid ? .white : ARColors.textSecondary)
                                .background(viewModel.viewMode == .grid ? ARColors.primary : Color.clear)
                        }
                        
                        Button(action: {
                            viewModel.viewMode = .list
                        }) {
                            Image(systemName: "list.bullet")
                                .padding(8)
                                .foregroundColor(viewModel.viewMode == .list ? .white : ARColors.textSecondary)
                                .background(viewModel.viewMode == .list ? ARColors.primary : Color.clear)
                        }
                    }
                    .background(ARColors.surface)
                    .cornerRadius(8)
                }
            }
            .padding()
            .background(ARColors.background)
            
            // Content
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredARCodes.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(ARColors.textDisabled)
                    
                    Text("Aucun AR Code trouvé")
                        .font(ARTypography.titleMedium)
                        .foregroundColor(ARColors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    if viewModel.viewMode == .grid {
                        gridView
                    } else {
                        listView
                    }
                }
            }
        }
        .navigationTitle("AR Codes")
        .navigationBarTitleDisplayMode(.large)
        .background(ARColors.background)
        .alert("Supprimer AR Code", isPresented: $showDeleteConfirmation) {
            Button("Annuler", role: .cancel) {}
            Button("Supprimer", role: .destructive) {
                if let arCode = arCodeToDelete {
                    viewModel.deleteARCode(arCode)
                }
            }
        } message: {
            Text("Êtes-vous sûr de vouloir supprimer cet AR Code ?")
        }
    }
    
    // MARK: - Grid View
    
    private var gridView: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing: 16
        ) {
            ForEach(viewModel.filteredARCodes) { arCode in
                ARCodeManagerCardView(
                    arCode: arCode,
                    viewModel: viewModel,
                    onDelete: {
                        arCodeToDelete = arCode
                        showDeleteConfirmation = true
                    }
                )
            }
        }
        .padding()
    }
    
    // MARK: - List View
    
    private var listView: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.filteredARCodes) { arCode in
                ARCodeManagerListItemView(
                    arCode: arCode,
                    viewModel: viewModel,
                    onDelete: {
                        arCodeToDelete = arCode
                        showDeleteConfirmation = true
                    }
                )
            }
        }
        .padding()
    }
}

// MARK: - AR Code Manager Card

struct ARCodeManagerCardView: View {
    let arCode: ARCode
    let viewModel: ARCodeManagerViewModel
    let onDelete: () -> Void
    
    var body: some View {
        ARCard {
            VStack(alignment: .leading, spacing: 12) {
                // Thumbnail 3D Preview
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(ARColors.border)
                        .frame(height: 120)
                    
                    // Preview 3D (placeholder)
                    Image(systemName: iconForType(arCode.type))
                        .font(.system(size: 40))
                        .foregroundColor(colorForType(arCode.type))
                }
                
                // Title
                Text(arCode.title)
                    .font(ARTypography.titleSmall)
                    .foregroundColor(ARColors.textPrimary)
                    .lineLimit(2)
                
                // Stats inline
                HStack {
                    Label("\(0)", systemImage: "qrcode.viewfinder")
                        .font(ARTypography.labelSmall)
                        .foregroundColor(ARColors.textSecondary)
                    
                    Spacer()
                    
                    Label("\(0)", systemImage: "eye")
                        .font(ARTypography.labelSmall)
                        .foregroundColor(ARColors.textSecondary)
                }
                
                // Actions
                HStack(spacing: 8) {
                    Button(action: { viewModel.editARCode(arCode) }) {
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundColor(ARColors.primary)
                            .padding(8)
                            .background(ARColors.primary.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Button(action: { viewModel.duplicateARCode(arCode) }) {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                            .foregroundColor(ARColors.secondary)
                            .padding(8)
                            .background(ARColors.secondary.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Button(action: { viewModel.shareARCode(arCode) }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.caption)
                            .foregroundColor(ARColors.info)
                            .padding(8)
                            .background(ARColors.info.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(ARColors.error)
                            .padding(8)
                            .background(ARColors.error.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
        }
    }
    
    private func iconForType(_ type: ARCodeType) -> String {
        switch type {
        case .objectCapture: return "cube.box"
        case .faceFilter: return "face.smiling"
        case .aiCode: return "brain.head.profile"
        case .video: return "video.fill"
        case .portal: return "door.left.hand.open"
        case .text: return "textformat"
        case .photo: return "photo.frame"
        case .logo: return "signature"
        case .splat: return "sparkles"
        case .data: return "chart.bar"
        }
    }
    
    private func colorForType(_ type: ARCodeType) -> Color {
        switch type {
        case .objectCapture: return ARColors.primary
        case .faceFilter: return ARColors.accent
        case .aiCode: return ARColors.info
        case .video: return ARColors.warning
        case .portal: return ARColors.success
        case .text: return ARColors.primary
        case .photo: return ARColors.secondary
        case .logo: return ARColors.accent
        case .splat: return ARColors.info
        case .data: return ARColors.success
        }
    }
}

// MARK: - AR Code Manager List Item

struct ARCodeManagerListItemView: View {
    let arCode: ARCode
    let viewModel: ARCodeManagerViewModel
    let onDelete: () -> Void
    
    var body: some View {
        ARCard {
            HStack(spacing: 16) {
                // Thumbnail
                RoundedRectangle(cornerRadius: 8)
                    .fill(ARColors.border)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "cube.box")
                            .font(.title2)
                            .foregroundColor(ARColors.textSecondary)
                    )
                
                // Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(arCode.title)
                        .font(ARTypography.titleMedium)
                        .foregroundColor(ARColors.textPrimary)
                    
                    HStack {
                        Label("\(0)", systemImage: "qrcode.viewfinder")
                        Label("\(0)", systemImage: "eye")
                    }
                    .font(ARTypography.labelSmall)
                    .foregroundColor(ARColors.textSecondary)
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: 8) {
                    Button(action: { viewModel.editARCode(arCode) }) {
                        Image(systemName: "pencil")
                    }
                    Button(action: { viewModel.shareARCode(arCode) }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(ARColors.error)
                    }
                }
                .font(.caption)
                .foregroundColor(ARColors.primary)
            }
        }
    }
}









