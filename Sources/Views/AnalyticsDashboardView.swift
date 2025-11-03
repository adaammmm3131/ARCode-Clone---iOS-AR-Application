//
//  AnalyticsDashboardView.swift
//  ARCodeClone
//
//  Analytics Dashboard avec graphiques, MapKit heatmap, charts
//

import SwiftUI
import MapKit
#if canImport(Charts)
import Charts
#endif

struct AnalyticsDashboardView: View {
    @StateObject var viewModel: AnalyticsViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Scans Over Time Chart
                VStack(alignment: .leading, spacing: 16) {
                    Text("Scans dans le temps")
                        .font(ARTypography.titleLarge)
                        .foregroundColor(ARColors.textPrimary)
                        .padding(.horizontal)
                    
                    ARCard {
                        if #available(iOS 16.0, *) {
                            Chart {
                                ForEach(Array(viewModel.scansOverTime.enumerated()), id: \.offset) { index, point in
                                    LineMark(
                                        x: .value("Date", point.date),
                                        y: .value("Scans", point.value)
                                    )
                                    .foregroundStyle(ARColors.primary)
                                    .interpolationMethod(.catmullRom)
                                    
                                    AreaMark(
                                        x: .value("Date", point.date),
                                        y: .value("Scans", point.value)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [ARColors.primary.opacity(0.3), ARColors.primary.opacity(0.0)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .interpolationMethod(.catmullRom)
                                }
                            }
                            .frame(height: 200)
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                                    AxisGridLine()
                                    AxisValueLabel(format: .dateTime.month().day())
                                }
                            }
                            .chartYAxis {
                                AxisMarks { _ in
                                    AxisGridLine()
                                    AxisValueLabel()
                                }
                            }
                        } else {
                            // Fallback pour iOS < 16
                            Text("Graphique nécessite iOS 16+")
                                .foregroundColor(ARColors.textSecondary)
                                .frame(height: 200)
                        }
                        #else
                        // Fallback si Charts non disponible
                        Text("Graphique nécessite Charts framework")
                            .foregroundColor(ARColors.textSecondary)
                            .frame(height: 200)
                        #endif
                    }
                    .padding(.horizontal)
                }
                
                // Geographic Heatmap
                VStack(alignment: .leading, spacing: 16) {
                    Text("Carte géographique")
                        .font(ARTypography.titleLarge)
                        .foregroundColor(ARColors.textPrimary)
                        .padding(.horizontal)
                    
                    ARCard {
                        AnalyticsHeatmapView(locations: viewModel.scanLocations)
                            .frame(height: 300)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                // Device Breakdown
                VStack(alignment: .leading, spacing: 16) {
                    Text("Répartition par appareil")
                        .font(ARTypography.titleLarge)
                        .foregroundColor(ARColors.textPrimary)
                        .padding(.horizontal)
                    
                    ARCard {
                        #if canImport(Charts)
                        if #available(iOS 16.0, *) {
                            Chart {
                                ForEach(viewModel.deviceBreakdown, id: \.device) { breakdown in
                                    BarMark(
                                        x: .value("Device", breakdown.device),
                                        y: .value("Count", breakdown.count)
                                    )
                                    .foregroundStyle(ARColors.primary)
                                }
                            }
                            .frame(height: 200)
                            .chartYAxis {
                                AxisMarks { _ in
                                    AxisGridLine()
                                    AxisValueLabel()
                                }
                            }
                        } else {
                            // Fallback pour iOS < 16
                            VStack(spacing: 12) {
                                ForEach(viewModel.deviceBreakdown, id: \.device) { breakdown in
                                    HStack {
                                        Text(breakdown.device)
                                        Spacer()
                                        Text("\(breakdown.count) (\(String(format: "%.1f", breakdown.percentage))%)")
                                            .foregroundColor(ARColors.textSecondary)
                                    }
                                }
                            }
                            .frame(height: 200)
                        }
                        #else
                        // Fallback si Charts non disponible
                            VStack(spacing: 12) {
                                ForEach(viewModel.deviceBreakdown, id: \.device) { breakdown in
                                    HStack {
                                        Text(breakdown.device)
                                        Spacer()
                                        Text("\(breakdown.count) (\(String(format: "%.1f", breakdown.percentage))%)")
                                            .foregroundColor(ARColors.textSecondary)
                                    }
                                }
                            }
                            .frame(height: 200)
                        }
                        #endif
                    }
                    .padding(.horizontal)
                }
                
                // Browser Stats
                VStack(alignment: .leading, spacing: 16) {
                    Text("Répartition par navigateur")
                        .font(ARTypography.titleLarge)
                        .foregroundColor(ARColors.textPrimary)
                        .padding(.horizontal)
                    
                    ARCard {
                        VStack(spacing: 12) {
                            ForEach(viewModel.browserStats, id: \.device) { stat in
                                HStack {
                                    Text(stat.device)
                                        .font(ARTypography.bodyMedium)
                                    
                                    Spacer()
                                    
                                    ARProgressBar(
                                        progress: stat.percentage / 100.0,
                                        color: ARColors.secondary,
                                        height: 8
                                    )
                                    .frame(width: 100)
                                    
                                    Text("\(String(format: "%.1f", stat.percentage))%")
                                        .font(ARTypography.labelSmall)
                                        .foregroundColor(ARColors.textSecondary)
                                        .frame(width: 50, alignment: .trailing)
                                }
                            }
                        }
                        .frame(height: 150)
                    }
                    .padding(.horizontal)
                }
                
                // Engagement & Conversion
                HStack(spacing: 16) {
                    ARCard {
                        VStack(spacing: 12) {
                            Text("Temps d'engagement")
                                .font(ARTypography.labelMedium)
                                .foregroundColor(ARColors.textSecondary)
                            
                            Text("\(Int(viewModel.engagementTime))s")
                                .font(ARTypography.headlineLarge)
                                .foregroundColor(ARColors.primary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    ARCard {
                        VStack(spacing: 12) {
                            Text("Taux de conversion")
                                .font(ARTypography.labelMedium)
                                .foregroundColor(ARColors.textSecondary)
                            
                            Text("\(String(format: "%.1f", viewModel.conversionRate))%")
                                .font(ARTypography.headlineLarge)
                                .foregroundColor(ARColors.success)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.large)
        .background(ARColors.background)
        .refreshable {
            viewModel.loadAnalyticsData()
        }
    }
}

// MARK: - Analytics Heatmap

struct AnalyticsHeatmapView: UIViewRepresentable {
    let locations: [ScanLocation]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.mapType = .standard
        mapView.showsUserLocation = false
        
        // Configurer région
        if let firstLocation = locations.first {
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: firstLocation.latitude,
                    longitude: firstLocation.longitude
                ),
                span: MKCoordinateSpan(latitudeDelta: 50, longitudeDelta: 50)
            )
            mapView.setRegion(region, animated: false)
        }
        
        // Ajouter annotations pour chaque location
        let annotations = locations.map { location in
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(
                latitude: location.latitude,
                longitude: location.longitude
            )
            annotation.title = "\(location.count) scans"
            return annotation
        }
        
        mapView.addAnnotations(annotations)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Mettre à jour si nécessaire
    }
}

