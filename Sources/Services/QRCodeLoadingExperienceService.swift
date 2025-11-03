//
//  QRCodeLoadingExperienceService.swift
//  ARCodeClone
//
//  Service pour loading experience (splash screen, progress, preloading)
//

import Foundation
import SwiftUI
import UIKit

protocol QRCodeLoadingExperienceServiceProtocol {
    func showSplashScreen(completion: @escaping () -> Void)
    func createProgressBar(progress: Binding<Double>, message: Binding<String>) -> AnyView
    func preloadAssets(urls: [URL], contentType: String, completion: @escaping (Result<Void, Error>) -> Void)
}

final class QRCodeLoadingExperienceService: QRCodeLoadingExperienceServiceProtocol {
    
    // MARK: - Splash Screen
    
    func showSplashScreen(completion: @escaping () -> Void) {
        // Créer splash screen view
        // Note: En production, utiliser UIWindow pour overlay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion()
        }
    }
    
    // MARK: - Progress Bar
    
    func createProgressBar(progress: Binding<Double>, message: Binding<String>) -> AnyView {
        return AnyView(
            VStack(spacing: 16) {
                // Logo AR Code (3D spinning si disponible)
                if let logo = UIImage(named: "ARCodeLogo") {
                    Image(uiImage: logo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(progress.wrappedValue * 360))
                }
                
                // Progress bar
                ProgressView(value: progress.wrappedValue)
                    .progressViewStyle(LinearProgressViewStyle())
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                
                // Message
                Text(message.wrappedValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Percentage
                Text("\(Int(progress.wrappedValue * 100))%")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 8)
        )
    }
    
    // MARK: - Preloading
    
    func preloadAssets(
        urls: [URL],
        contentType: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        // Précharger assets en parallèle
        let group = DispatchGroup()
        var errors: [Error] = []
        
        for url in urls {
            group.enter()
            
            // Note: Utiliser AssetLoadingService pour preload
            // Pour l'instant, simuler preload
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if errors.isEmpty {
                completion(.success(()))
            } else {
                completion(.failure(errors.first!))
            }
        }
    }
}









