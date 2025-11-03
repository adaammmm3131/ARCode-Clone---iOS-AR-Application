//
//  AnalyticsViewModel.swift
//  ARCodeClone
//
//  ViewModel pour Analytics Dashboard
//

import Foundation
import SwiftUI
import Combine
import MapKit

struct AnalyticsDataPoint {
    let date: Date
    let value: Int
}

struct ScanLocation {
    let latitude: Double
    let longitude: Double
    let count: Int
}

struct DeviceBreakdown {
    let device: String
    let count: Int
    let percentage: Double
}

final class AnalyticsViewModel: BaseViewModel, ObservableObject {
    @Published var scansOverTime: [AnalyticsDataPoint] = []
    @Published var scanLocations: [ScanLocation] = []
    @Published var deviceBreakdown: [DeviceBreakdown] = []
    @Published var browserStats: [DeviceBreakdown] = []
    @Published var engagementTime: TimeInterval = 0
    @Published var conversionRate: Double = 0.0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let analyticsService: AnalyticsServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(analyticsService: AnalyticsServiceProtocol) {
        self.analyticsService = analyticsService
        super.init()
        
        loadAnalyticsData()
    }
    
    // MARK: - Data Loading
    
    func loadAnalyticsData() {
        isLoading = true
        
        // Simuler chargement (en production, appeler API)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.generateMockData()
            self?.isLoading = false
        }
    }
    
    private func generateMockData() {
        // Générer données mock
        let calendar = Calendar.current
        scansOverTime = (0..<30).map { day in
            AnalyticsDataPoint(
                date: calendar.date(byAdding: .day, value: -day, to: Date()) ?? Date(),
                value: Int.random(in: 10...100)
            )
        }.reversed()
        
        scanLocations = [
            ScanLocation(latitude: 48.8566, longitude: 2.3522, count: 125), // Paris
            ScanLocation(latitude: 40.7128, longitude: -74.0060, count: 89), // New York
            ScanLocation(latitude: 51.5074, longitude: -0.1278, count: 67), // London
        ]
        
        deviceBreakdown = [
            DeviceBreakdown(device: "iPhone", count: 450, percentage: 60.0),
            DeviceBreakdown(device: "Android", count: 250, percentage: 33.3),
            DeviceBreakdown(device: "iPad", count: 50, percentage: 6.7)
        ]
        
        browserStats = [
            DeviceBreakdown(device: "Safari", count: 500, percentage: 66.7),
            DeviceBreakdown(device: "Chrome", count: 200, percentage: 26.7),
            DeviceBreakdown(device: "Firefox", count: 50, percentage: 6.6)
        ]
        
        engagementTime = 125.5 // seconds
        conversionRate = 12.5 // percentage
    }
}









