//
//  ContentView.swift
//  ARCodeClone
//
//  Vue principale de l'application avec navigation TabView
//

import SwiftUI

struct ContentView: View {
    @StateObject private var dashboardViewModel: DashboardViewModel
    @StateObject private var arCodeManagerViewModel: ARCodeManagerViewModel
    @StateObject private var analyticsViewModel: AnalyticsViewModel
    
    init() {
        let container = DependencyContainer.shared
        
        _dashboardViewModel = StateObject(wrappedValue: DashboardViewModel(
            networkService: container.resolve(NetworkServiceProtocol.self)
        ))
        
        _arCodeManagerViewModel = StateObject(wrappedValue: ARCodeManagerViewModel(
            networkService: container.resolve(NetworkServiceProtocol.self)
        ))
        
        _analyticsViewModel = StateObject(wrappedValue: AnalyticsViewModel(
            analyticsService: container.resolve(AnalyticsServiceProtocol.self)
        ))
    }
    
    var body: some View {
        TabView {
            // Dashboard Home
            DashboardHomeView(viewModel: dashboardViewModel)
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
            
            // AR Code Manager
            ARCodeManagerView(viewModel: arCodeManagerViewModel)
                .tabItem {
                    Label("AR Codes", systemImage: "cube.box.fill")
                }
            
            // Analytics
            AnalyticsDashboardView(viewModel: analyticsViewModel)
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }
            
            // 3D Editor
            AR3DEditorView()
                .tabItem {
                    Label("Editor", systemImage: "pencil.and.outline")
                }
        }
        .accentColor(ARColors.primary)
    }
}

#Preview {
    ContentView()
}

