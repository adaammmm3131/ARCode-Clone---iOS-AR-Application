//
//  DashboardHomeView.swift
//  ARCodeClone
//
//  Dashboard Home avec header, stats, modules cards, recent AR Codes
//

import SwiftUI

struct DashboardHomeView: View {
    @StateObject var viewModel: DashboardViewModel
    @State private var selectedModule: ModuleCard?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header avec Logo + Stats
                    DashboardHeaderView(stats: viewModel.stats)
                    
                    // Modules Cards Grid
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Modules AR")
                            .font(ARTypography.titleLarge)
                            .foregroundColor(ARColors.textPrimary)
                            .padding(.horizontal)
                        
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ],
                            spacing: 16
                        ) {
                            ForEach(viewModel.modules, id: \.id) { module in
                                ModuleCardView(module: module) {
                                    selectedModule = module
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Recent AR Codes List
                    if !viewModel.recentARCodes.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("AR Codes Récents")
                                    .font(ARTypography.titleLarge)
                                    .foregroundColor(ARColors.textPrimary)
                                
                                Spacer()
                                
                                NavigationLink("Voir tout") {
                                    // TODO: Navigate to AR Code Manager
                                }
                                .font(ARTypography.labelMedium)
                                .foregroundColor(ARColors.primary)
                            }
                            .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(viewModel.recentARCodes) { arCode in
                                        ARCodeCardView(arCode: arCode)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .background(ARColors.background)
            .refreshable {
                viewModel.loadDashboardData()
            }
            .sheet(item: $selectedModule) { module in
                NavigationView {
                    module.destination
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }
}

// MARK: - Dashboard Header

struct DashboardHeaderView: View {
    let stats: DashboardStats
    
    var body: some View {
        VStack(spacing: 20) {
            // Logo
            HStack {
                ARSpinningLogo(size: 60)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("AR Code")
                        .font(ARTypography.headlineLarge)
                        .foregroundColor(ARColors.textPrimary)
                    
                    Text("Plateforme AR")
                        .font(ARTypography.bodySmall)
                        .foregroundColor(ARColors.textSecondary)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            
            // Stats Grid
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 12
            ) {
                StatCardView(
                    title: "AR Codes",
                    value: "\(stats.totalARCodes)",
                    icon: "cube.box.fill",
                    color: ARColors.primary
                )
                
                StatCardView(
                    title: "Scans",
                    value: "\(stats.totalScans)",
                    icon: "qrcode.viewfinder",
                    color: ARColors.secondary
                )
                
                StatCardView(
                    title: "Vues",
                    value: "\(stats.totalViews)",
                    icon: "eye.fill",
                    color: ARColors.accent
                )
                
                StatCardView(
                    title: "Actifs",
                    value: "\(stats.activeARCodes)",
                    icon: "checkmark.circle.fill",
                    color: ARColors.success
                )
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

// MARK: - Stat Card

struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        ARCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                    
                    Spacer()
                }
                
                Text(value)
                    .font(ARTypography.headlineMedium)
                    .foregroundColor(ARColors.textPrimary)
                
                Text(title)
                    .font(ARTypography.labelSmall)
                    .foregroundColor(ARColors.textSecondary)
            }
        }
    }
}

// MARK: - Module Card

struct ModuleCardView: View {
    let module: ModuleCard
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ARCard {
                VStack(spacing: 12) {
                    Image(systemName: module.icon)
                        .font(.system(size: 32))
                        .foregroundColor(module.color)
                    
                    Text(module.title)
                        .font(ARTypography.titleMedium)
                        .foregroundColor(ARColors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text(module.description)
                        .font(ARTypography.bodySmall)
                        .foregroundColor(ARColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - AR Code Card

struct ARCodeCardView: View {
    let arCode: ARCode
    
    var body: some View {
        ARCard {
            VStack(alignment: .leading, spacing: 12) {
                // Thumbnail placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(ARColors.border)
                    .frame(height: 120)
                    .overlay(
                        Image(systemName: "cube.box")
                            .font(.largeTitle)
                            .foregroundColor(ARColors.textSecondary)
                    )
                
                Text(arCode.title)
                    .font(ARTypography.titleSmall)
                    .foregroundColor(ARColors.textPrimary)
                    .lineLimit(2)
                
                HStack {
                    Label("\(0)", systemImage: "qrcode.viewfinder")
                        .font(ARTypography.labelSmall)
                        .foregroundColor(ARColors.textSecondary)
                    
                    Spacer()
                    
                    Label("\(0)", systemImage: "eye")
                        .font(ARTypography.labelSmall)
                        .foregroundColor(ARColors.textSecondary)
                }
            }
            .frame(width: 160)
        }
    }
}

extension ModuleCard: Identifiable {}

