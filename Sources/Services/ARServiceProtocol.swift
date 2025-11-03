//
//  ARServiceProtocol.swift
//  ARCodeClone
//
//  Protocol pour le service AR
//

import Foundation
import ARKit
import RealityKit

/// Protocol pour les opérations AR
protocol ARServiceProtocol {
    func startARSession(configuration: ARConfiguration) throws
    func stopARSession()
    func loadModel(at url: URL) async throws -> ModelEntity
    func placeModel(_ model: ModelEntity, at position: SIMD3<Float>)
    func detectPlanes() -> [ARPlaneAnchor]
    func estimateLighting() -> ARLightEstimate?
}











