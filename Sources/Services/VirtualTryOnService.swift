//
//  VirtualTryOnService.swift
//  ARCodeClone
//
//  Service pour virtual try-on avec segmentation, keypoints, perspective correction, lighting match, SD inpainting
//

import Foundation
import UIKit
import Vision
import CoreImage

protocol VirtualTryOnServiceProtocol {
    func tryOnProduct(
        productImage: UIImage,
        userImage: UIImage,
        completion: @escaping (Result<UIImage, Error>) -> Void
    )
    func detectKeypoints(in image: UIImage, completion: @escaping (Result<[BodyKeypoint], Error>) -> Void)
}

struct BodyKeypoint {
    let name: String
    let position: CGPoint
    let confidence: Float
}

enum VirtualTryOnError: LocalizedError {
    case imageConversionFailed
    case noPersonDetected
    case keypointsDetectionFailed
    case segmentationFailed
    case networkError(Error)
    case processingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Échec de la conversion de l'image"
        case .noPersonDetected:
            return "Aucune personne détectée dans l'image"
        case .keypointsDetectionFailed:
            return "Échec de la détection des keypoints"
        case .segmentationFailed:
            return "Échec de la segmentation"
        case .networkError(let error):
            return "Erreur réseau: \(error.localizedDescription)"
        case .processingFailed(let message):
            return "Erreur traitement: \(message)"
        }
    }
}

final class VirtualTryOnService: VirtualTryOnServiceProtocol {
    private let networkService: NetworkServiceProtocol
    private let segmentationService: SegmentationServiceProtocol
    private let baseURL: String
    
    init(
        networkService: NetworkServiceProtocol,
        segmentationService: SegmentationServiceProtocol,
        baseURL: String = "http://localhost:5002"
    ) {
        self.networkService = networkService
        self.segmentationService = segmentationService
        self.baseURL = baseURL
    }
    
    // MARK: - Virtual Try-On Pipeline
    
    func tryOnProduct(
        productImage: UIImage,
        userImage: UIImage,
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) {
        // Pipeline complet:
        // 1. Segmentation utilisateur
        // 2. Détection keypoints
        // 3. Perspective correction produit
        // 4. Lighting match
        // 5. Composite avec SD inpainting
        
        // Étape 1: Segmenter personne utilisateur
        segmentationService.generatePersonMask(in: userImage) { [weak self] maskResult in
            guard let self = self else { return }
            
            switch maskResult {
            case .success(let mask):
                // Étape 2: Détecter keypoints (pieds, poignets, visage)
                self.detectKeypoints(in: userImage) { keypointsResult in
                    switch keypointsResult {
                    case .success(let keypoints):
                        // Étape 3: Préparer masque pour inpainting
                        // Créer masque combiné (personne + zones produit)
                        guard let combinedMask = self.createTryOnMask(
                            personMask: mask,
                            keypoints: keypoints,
                            productImage: productImage
                        ) else {
                            completion(.failure(VirtualTryOnError.processingFailed("Mask creation failed")))
                            return
                        }
                        
                        // Étape 4: Appliquer perspective correction sur produit
                        guard let correctedProduct = self.applyPerspectiveCorrection(
                            product: productImage,
                            basedOn: keypoints
                        ) else {
                            completion(.failure(VirtualTryOnError.processingFailed("Perspective correction failed")))
                            return
                        }
                        
                        // Étape 5: Lighting match
                        guard let matchedProduct = self.matchLighting(
                            product: correctedProduct,
                            to: userImage
                        ) else {
                            completion(.failure(VirtualTryOnError.processingFailed("Lighting match failed")))
                            return
                        }
                        
                        // Étape 6: Inpainting avec SD
                        self.performInpainting(
                            image: userImage,
                            mask: combinedMask,
                            product: matchedProduct,
                            keypoints: keypoints,
                            completion: completion
                        )
                        
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Keypoints Detection
    
    func detectKeypoints(in image: UIImage, completion: @escaping (Result<[BodyKeypoint], Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(VirtualTryOnError.imageConversionFailed))
            return
        }
        
        // Utiliser HumanBodyPoseRequest (iOS 14+)
        guard #available(iOS 14.0, *) else {
            completion(.failure(VirtualTryOnError.keypointsDetectionFailed))
            return
        }
        
        let request = VNDetectHumanBodyPoseRequest { request, error in
            if let error = error {
                completion(.failure(VirtualTryOnError.keypointsDetectionFailed))
                return
            }
            
            guard let observations = request.results as? [VNHumanBodyPoseObservation],
                  let observation = observations.first else {
                completion(.failure(VirtualTryOnError.noPersonDetected))
                return
            }
            
            var keypoints: [BodyKeypoint] = []
            let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
            
            // Extraire keypoints importants
            let keypointNames: [VNHumanBodyPoseObservation.JointName] = [
                .leftAnkle, .rightAnkle,    // Pieds
                .leftWrist, .rightWrist,    // Poignets
                .leftShoulder, .rightShoulder,  // Épaules
                .nose, .leftEye, .rightEye,      // Visage
                .neck,                          // Cou
                .root                          // Racine (hanches)
            ]
            
            for jointName in keypointNames {
                do {
                    let point = try observation.recognizedPoint(jointName)
                    if point.confidence > 0.3 {  // Seuil de confiance
                        let position = VNImagePointForNormalizedPoint(
                            point.location,
                            Int(imageSize.width),
                            Int(imageSize.height)
                        )
                        keypoints.append(BodyKeypoint(
                            name: jointName.rawValue,
                            position: position,
                            confidence: point.confidence
                        ))
                    }
                } catch {
                    continue
                }
            }
            
            if keypoints.isEmpty {
                completion(.failure(VirtualTryOnError.keypointsDetectionFailed))
            } else {
                completion(.success(keypoints))
            }
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            completion(.failure(VirtualTryOnError.keypointsDetectionFailed))
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTryOnMask(
        personMask: CIImage,
        keypoints: [BodyKeypoint],
        productImage: UIImage
    ) -> CIImage? {
        // Créer masque pour zones où le produit sera appliqué
        // Basé sur keypoints (ex: haut du corps pour t-shirt)
        // Cette implémentation est simplifiée - une version complète utiliserait
        // les keypoints pour déterminer précisément les zones du corps
        
        // Pour l'instant, utiliser masque personne comme base
        return personMask
    }
    
    private func applyPerspectiveCorrection(
        product: UIImage,
        basedOn keypoints: [BodyKeypoint]
    ) -> UIImage? {
        // Appliquer correction perspective au produit basé sur keypoints
        // Ex: ajuster taille/rotation selon largeur épaules, hauteur
        
        // Trouver épaules
        let shoulders = keypoints.filter { $0.name.contains("shoulder") }
        if shoulders.count == 2 {
            let shoulderWidth = abs(shoulders[0].position.x - shoulders[1].position.x)
            // Ajuster scale produit selon largeur épaules
            // Implémentation simplifiée
        }
        
        // Pour l'instant, retourner produit original
        return product
    }
    
    private func matchLighting(product: UIImage, to userImage: UIImage) -> UIImage? {
        // Analyser éclairage de l'image utilisateur
        // Ajuster éclairage du produit pour correspondre
        // Utiliser CoreImage filters pour ajustement couleur/luminosité
        
        guard let productCI = CIImage(image: product),
              let userCI = CIImage(image: userImage) else {
            return nil
        }
        
        // Calculer luminance moyenne utilisateur
        // Ajuster produit pour correspondre
        // Implémentation simplifiée avec CoreImage
        
        return product
    }
    
    private func performInpainting(
        image: UIImage,
        mask: CIImage,
        product: UIImage,
        keypoints: [BodyKeypoint],
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) {
        // Préparer images pour inpainting
        guard let imageData = image.jpegData(compressionQuality: 0.9),
              let maskData = self.ciImageToPNGData(mask),
              let productData = product.pngData() else {
            completion(.failure(VirtualTryOnError.imageConversionFailed))
            return
        }
        
        let imageBase64 = imageData.base64EncodedString()
        let maskBase64 = maskData.base64EncodedString()
        
        // Construire prompt pour inpainting
        let prompt = self.buildTryOnPrompt(keypoints: keypoints)
        
        // Appel API Stable Diffusion inpainting
        let body: [String: Any] = [
            "image": "data:image/jpeg;base64,\(imageBase64)",
            "mask": "data:image/png;base64,\(maskBase64)",
            "prompt": prompt,
            "negative_prompt": "blurry, distorted, artifacts, low quality",
            "strength": 0.9,
            "steps": 30
        ]
        
        Task {
            do {
                let endpoint = APIEndpoint.aiInpainting
                let response: SDInpaintingResponse = try await networkService.request(
                    endpoint,
                    method: .post,
                    parameters: body,
                    headers: ["Content-Type": "application/json"]
                )
                
                // Convertir base64 en UIImage
                if let imageData = Data(base64Encoded: response.imageBase64.components(separatedBy: ",").last ?? response.imageBase64),
                   let resultImage = UIImage(data: imageData) {
                    DispatchQueue.main.async {
                        completion(.success(resultImage))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(VirtualTryOnError.imageConversionFailed))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(VirtualTryOnError.networkError(error)))
                }
            }
        }
    }
    
    private func ciImageToPNGData(_ ciImage: CIImage) -> Data? {
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage).pngData()
    }
    
    private func buildTryOnPrompt(keypoints: [BodyKeypoint]) -> String {
        // Construire prompt optimisé pour virtual try-on
        var prompt = "photorealistic virtual try-on, high quality clothing, perfect fit, "
        prompt += "natural lighting, professional photography, detailed textures, "
        prompt += "realistic fabric, seamless integration"
        return prompt
    }
}

struct SDInpaintingResponse: Codable {
    let imageId: String
    let imageBase64: String
    let processingTime: Double
    
    enum CodingKeys: String, CodingKey {
        case imageId = "image_id"
        case imageBase64 = "image_base64"
        case processingTime = "processing_time"
    }
}










