//
//  ProgressiveTextureLoader.swift
//  ARCodeClone
//
//  Progressive texture loading with mipmaps
//

import Foundation
import SceneKit
import UIKit

protocol ProgressiveTextureLoaderProtocol {
    func loadTexture(
        url: URL,
        mipmaps: Bool,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> SCNMaterialProperty
}

final class ProgressiveTextureLoader: ProgressiveTextureLoaderProtocol {
    
    func loadTexture(
        url: URL,
        mipmaps: Bool = true,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> SCNMaterialProperty {
        // Load base texture first (low quality)
        progressHandler(0.1)
        
        let (lowResData, _) = try await URLSession.shared.data(from: url)
        guard let lowResImage = UIImage(data: lowResData) else {
            throw NSError(domain: "TextureLoader", code: -1)
        }
        
        progressHandler(0.3)
        
        // Create material property with low-res texture
        let materialProperty = SCNMaterialProperty(contents: lowResImage)
        
        // Set minification and magnification filters for mipmaps
        if mipmaps {
            materialProperty.minificationFilter = .linear
            materialProperty.magnificationFilter = .linear
            materialProperty.mipFilter = .linear
        }
        
        progressHandler(0.5)
        
        // Load high-res texture asynchronously
        Task {
            do {
                // Request high-res version (if available)
                var highResURL = url
                // Option: Append ?quality=high or use different URL
                
                let (highResData, _) = try await URLSession.shared.data(from: highResURL)
                if let highResImage = UIImage(data: highResData) {
                    DispatchQueue.main.async {
                        materialProperty.contents = highResImage
                        progressHandler(1.0)
                    }
                }
            } catch {
                // Fallback: use low-res
                print("Failed to load high-res texture: \(error)")
            }
        }
        
        progressHandler(0.7)
        
        return materialProperty
    }
    
    func loadTextureWithMipmaps(
        url: URL,
        mipmapLevels: [Int] = [0, 1, 2, 3],
        progressHandler: @escaping (Double) -> Void
    ) async throws -> SCNMaterialProperty {
        let materialProperty = SCNMaterialProperty()
        
        // Load mipmap levels progressively
        for (index, level) in mipmapLevels.enumerated() {
            let levelURL = url.appendingPathComponent("mipmap_\(level)")
            
            do {
                let (data, _) = try await URLSession.shared.data(from: levelURL)
                if let image = UIImage(data: data) {
                    // Update texture (SceneKit handles mipmap levels automatically)
                    if level == 0 {
                        materialProperty.contents = image
                    }
                    
                    let progress = Double(index + 1) / Double(mipmapLevels.count)
                    progressHandler(progress)
                }
            } catch {
                // Continue with next level
                continue
            }
        }
        
        return materialProperty
    }
}







