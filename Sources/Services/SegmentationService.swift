//
//  SegmentationService.swift
//  ARCodeClone
//
//  Service de segmentation utilisant Vision framework pour person/object segmentation, background removal, mask generation
//

import Foundation
import Vision
import UIKit
import CoreImage

protocol SegmentationServiceProtocol {
    func segmentPerson(in image: UIImage, completion: @escaping (Result<UIImage, Error>) -> Void)
    func generatePersonMask(in image: UIImage, completion: @escaping (Result<CIImage, Error>) -> Void)
    func removeBackground(from image: UIImage, completion: @escaping (Result<UIImage, Error>) -> Void)
    func segmentObject(in image: UIImage, completion: @escaping (Result<[ObjectMask], Error>) -> Void)
}

struct ObjectMask {
    let mask: CIImage
    let boundingBox: CGRect
    let confidence: Float
    let label: String?
}

enum SegmentationError: LocalizedError {
    case imageConversionFailed
    case segmentationFailed(Error)
    case noPersonDetected
    case unsupportedDevice
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Échec de la conversion de l'image"
        case .segmentationFailed(let error):
            return "Échec de la segmentation: \(error.localizedDescription)"
        case .noPersonDetected:
            return "Aucune personne détectée dans l'image"
        case .unsupportedDevice:
            return "Segmentation person non supportée sur cet appareil"
        }
    }
}

final class SegmentationService: SegmentationServiceProtocol {
    private let context: CIContext
    
    init() {
        // Initialiser CIContext pour traitement d'images
        self.context = CIContext(options: [.useSoftwareRenderer: false])
    }
    
    // MARK: - Person Segmentation
    
    func segmentPerson(in image: UIImage, completion: @escaping (Result<UIImage, Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(SegmentationError.imageConversionFailed))
            return
        }
        
        // Vérifier support device (iOS 13+, Neural Engine)
        guard #available(iOS 13.0, *) else {
            completion(.failure(SegmentationError.unsupportedDevice))
            return
        }
        
        let request = VNGeneratePersonSegmentationRequest { request, error in
            if let error = error {
                completion(.failure(SegmentationError.segmentationFailed(error)))
                return
            }
            
            guard let observations = request.results as? [VNPixelBufferObservation],
                  let observation = observations.first else {
                completion(.failure(SegmentationError.noPersonDetected))
                return
            }
            
            // Convertir pixel buffer en UIImage
            let ciImage = CIImage(cvPixelBuffer: observation.pixelBuffer)
            
            // Appliquer masque sur image originale
            guard let maskedImage = self.applyMask(to: image, mask: ciImage) else {
                completion(.failure(SegmentationError.segmentationFailed(NSError(domain: "Segmentation", code: -1))))
                return
            }
            
            completion(.success(maskedImage))
        }
        
        // Configuration segmentation
        request.qualityLevel = .balanced // .fast, .balanced, .accurate
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            completion(.failure(SegmentationError.segmentationFailed(error)))
        }
    }
    
    // MARK: - Person Mask Generation
    
    func generatePersonMask(in image: UIImage, completion: @escaping (Result<CIImage, Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(SegmentationError.imageConversionFailed))
            return
        }
        
        guard #available(iOS 13.0, *) else {
            completion(.failure(SegmentationError.unsupportedDevice))
            return
        }
        
        let request = VNGeneratePersonSegmentationRequest { request, error in
            if let error = error {
                completion(.failure(SegmentationError.segmentationFailed(error)))
                return
            }
            
            guard let observations = request.results as? [VNPixelBufferObservation],
                  let observation = observations.first else {
                completion(.failure(SegmentationError.noPersonDetected))
                return
            }
            
            let maskImage = CIImage(cvPixelBuffer: observation.pixelBuffer)
            completion(.success(maskImage))
        }
        
        request.qualityLevel = .accurate // Pour masque précis
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            completion(.failure(SegmentationError.segmentationFailed(error)))
        }
    }
    
    // MARK: - Background Removal
    
    func removeBackground(from image: UIImage, completion: @escaping (Result<UIImage, Error>) -> Void) {
        generatePersonMask(in: image) { result in
            switch result {
            case .success(let mask):
                // Créer image avec fond transparent
                guard let originalCIImage = CIImage(image: image),
                      let outputImage = self.compositeImageWithTransparentBackground(originalCIImage, mask: mask) else {
                    completion(.failure(SegmentationError.segmentationFailed(NSError(domain: "Segmentation", code: -1))))
                    return
                }
                
                // Convertir CIImage en UIImage avec fond transparent
                guard let cgImage = self.context.createCGImage(outputImage, from: outputImage.extent) else {
                    completion(.failure(SegmentationError.imageConversionFailed))
                    return
                }
                
                let resultImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
                completion(.success(resultImage))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Object Segmentation (Saliency)
    
    func segmentObject(in image: UIImage, completion: @escaping (Result<[ObjectMask], Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(SegmentationError.imageConversionFailed))
            return
        }
        
        // Utiliser saliency pour détecter objets saillants
        let attentionRequest = VNGenerateAttentionBasedSaliencyImageRequest()
        let objectnessRequest = VNGenerateObjectnessBasedSaliencyImageRequest()
        
        var objectMasks: [ObjectMask] = []
        let group = DispatchGroup()
        
        // Attention-based saliency
        group.enter()
        attentionRequest.completionHandler = { request, error in
            defer { group.leave() }
            if let observation = request.results?.first as? VNSaliencyImageObservation,
               let salientObjects = observation.salientObjects {
                for salientObject in salientObjects {
                    let mask = CIImage(cvPixelBuffer: observation.pixelBuffer)
                    let boundingBox = VNImageRectForNormalizedRect(
                        salientObject.boundingBox,
                        cgImage.width,
                        cgImage.height
                    )
                    objectMasks.append(ObjectMask(
                        mask: mask,
                        boundingBox: boundingBox,
                        confidence: salientObject.confidence,
                        label: nil
                    ))
                }
            }
        }
        
        // Objectness-based saliency
        group.enter()
        objectnessRequest.completionHandler = { request, error in
            defer { group.leave() }
            if let observation = request.results?.first as? VNSaliencyImageObservation,
               let salientObjects = observation.salientObjects {
                for salientObject in salientObjects {
                    let mask = CIImage(cvPixelBuffer: observation.pixelBuffer)
                    let boundingBox = VNImageRectForNormalizedRect(
                        salientObject.boundingBox,
                        cgImage.width,
                        cgImage.height
                    )
                    objectMasks.append(ObjectMask(
                        mask: mask,
                        boundingBox: boundingBox,
                        confidence: salientObject.confidence,
                        label: nil
                    ))
                }
            }
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([attentionRequest, objectnessRequest])
        } catch {
            completion(.failure(SegmentationError.segmentationFailed(error)))
            return
        }
        
        group.notify(queue: .main) {
            if objectMasks.isEmpty {
                completion(.failure(SegmentationError.segmentationFailed(NSError(domain: "Segmentation", code: -1, userInfo: [NSLocalizedDescriptionKey: "Aucun objet détecté"]))))
            } else {
                completion(.success(objectMasks))
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func applyMask(to image: UIImage, mask: CIImage) -> UIImage? {
        guard let originalCIImage = CIImage(image: image) else {
            return nil
        }
        
        // Redimensionner masque si nécessaire
        let maskScaled = mask.transformed(by: CGAffineTransform(
            scaleX: originalCIImage.extent.width / mask.extent.width,
            y: originalCIImage.extent.height / mask.extent.height
        ))
        
        // Appliquer masque
        let maskedImage = originalCIImage.applyingFilter("CIBlendWithAlphaMask", parameters: [
            "inputMaskImage": maskScaled
        ])
        
        guard let cgImage = context.createCGImage(maskedImage, from: maskedImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    private func compositeImageWithTransparentBackground(_ image: CIImage, mask: CIImage) -> CIImage? {
        // Redimensionner masque si nécessaire
        let maskScaled = mask.transformed(by: CGAffineTransform(
            scaleX: image.extent.width / mask.extent.width,
            y: image.extent.height / mask.extent.height
        ))
        
        // Créer image avec alpha channel basé sur masque
        let alphaMask = maskScaled.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputAVector": CIVector(x: 1, y: 0, z: 0, w: 0), // Utiliser masque comme alpha
            "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0)
        ])
        
        // Composite avec fond transparent
        return image.applyingFilter("CIBlendWithMask", parameters: [
            "inputMaskImage": alphaMask
        ])
    }
}

// MARK: - iOS 15+ Person Instance Segmentation

@available(iOS 15.0, *)
extension SegmentationService {
    /// Segmentation multi-person avec instances séparées (iOS 15+)
    func segmentPersonInstances(in image: UIImage, completion: @escaping (Result<[PersonInstance], Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(SegmentationError.imageConversionFailed))
            return
        }
        
        let request = VNGenerateForegroundInstanceMaskRequest { request, error in
            if let error = error {
                completion(.failure(SegmentationError.segmentationFailed(error)))
                return
            }
            
            guard let observation = request.results?.first as? VNForegroundInstanceMaskObservation else {
                completion(.failure(SegmentationError.noPersonDetected))
                return
            }
            
            // Extraire toutes les instances de personnes
            var instances: [PersonInstance] = []
            for instanceIndex in 0..<observation.instanceCount {
                do {
                    let instanceMask = try observation.generateScaledMaskForImage(forInstances: [instanceIndex], orientation: .up)
                    let maskCIImage = CIImage(cvPixelBuffer: instanceMask)
                    
                    // Calculer bounding box
                    let boundingBox = observation.allInstancesBoundingBox[instanceIndex]
                    
                    instances.append(PersonInstance(
                        mask: maskCIImage,
                        boundingBox: boundingBox,
                        instanceIndex: instanceIndex
                    ))
                } catch {
                    continue
                }
            }
            
            completion(.success(instances))
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            completion(.failure(SegmentationError.segmentationFailed(error)))
        }
    }
}

struct PersonInstance {
    let mask: CIImage
    let boundingBox: CGRect
    let instanceIndex: Int
}










