//
//  ARPlaneDetectionTests.swift
//  ARCodeCloneTests
//
//  ARKit tests with simulation
//

import XCTest
import ARKit
@testable import ARCodeClone

final class ARPlaneDetectionTests: XCTestCase {
    
    func testARConfigurationCreation() {
        // Test AR configuration setup
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        
        XCTAssertTrue(config.planeDetection.contains(.horizontal))
        XCTAssertTrue(config.planeDetection.contains(.vertical))
    }
    
    func testARPlaneAnchor() {
        // Test ARPlaneAnchor properties
        // Note: Actual anchor creation requires ARSession running
        // This tests the structure
        
        let anchor = ARPlaneAnchor(
            identifier: UUID(),
            transform: simd_float4x4(1.0),
            alignment: .horizontal,
            center: simd_float3(0, 0, 0),
            extent: simd_float3(1, 0, 1)
        )
        
        XCTAssertEqual(anchor.alignment, .horizontal)
        XCTAssertEqual(anchor.center, simd_float3(0, 0, 0))
    }
    
    func testARFaceTrackingConfiguration() {
        let config = ARFaceTrackingConfiguration()
        config.maximumNumberOfTrackedFaces = 2
        
        XCTAssertEqual(config.maximumNumberOfTrackedFaces, 2)
        XCTAssertTrue(config.supportedNumberOfTrackedFaces >= 1)
    }
    
    func testARImageTrackingConfiguration() {
        guard let config = ARImageTrackingConfiguration() as ARImageTrackingConfiguration? else {
            XCTFail("ARImageTrackingConfiguration not supported")
            return
        }
        
        // Test configuration
        config.maximumNumberOfTrackedImages = 4
        XCTAssertEqual(config.maximumNumberOfTrackedImages, 4)
    }
}

// MARK: - ARSession Mock

class MockARSession: ARSession {
    var mockConfiguration: ARConfiguration?
    var isRunning: Bool = false
    
    override func run(_ configuration: ARConfiguration, options: ARSession.RunOptions = []) {
        mockConfiguration = configuration
        isRunning = true
    }
    
    override func pause() {
        isRunning = false
    }
}







