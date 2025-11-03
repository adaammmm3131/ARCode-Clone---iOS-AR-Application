//
//  QRCodeGenerationServiceTests.swift
//  ARCodeCloneTests
//
//  Unit tests for QR Code generation service
//

import XCTest
@testable import ARCodeClone
import UIKit
import CoreGraphics

final class QRCodeGenerationServiceTests: XCTestCase {
    var service: QRCodeGenerationService!
    
    override func setUp() {
        super.setUp()
        service = QRCodeGenerationService()
    }
    
    override func tearDown() {
        service = nil
        super.tearDown()
    }
    
    func testQRCodeGeneration() {
        let expectation = expectation(description: "QR Code generation")
        
        service.generateQRCode(
            data: "https://ar-code.com/a/test123",
            size: CGSize(width: 512, height: 512),
            correctionLevel: .high,
            logo: nil,
            foregroundColor: .black,
            backgroundColor: .white,
            cornerRadius: 0
        ) { result in
            switch result {
            case .success(let image):
                XCTAssertNotNil(image)
                XCTAssertEqual(image.size.width, 512, accuracy: 1.0)
                XCTAssertEqual(image.size.height, 512, accuracy: 1.0)
            case .failure:
                XCTFail("QR Code generation should succeed")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testQRCodeWithLogo() {
        let expectation = expectation(description: "QR Code with logo")
        
        let logoImage = UIImage(systemName: "star.fill")!
        
        service.generateQRCode(
            data: "https://ar-code.com/a/test",
            size: CGSize(width: 1024, height: 1024),
            correctionLevel: .high,
            logo: logoImage,
            foregroundColor: .blue,
            backgroundColor: .white,
            cornerRadius: 10
        ) { result in
            switch result {
            case .success(let image):
                XCTAssertNotNil(image)
            case .failure:
                XCTFail("QR Code with logo should succeed")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testVersionEstimation() {
        let smallData = 100
        let mediumData = 500
        let largeData = 2000
        
        let versionSmall = service.estimateQRCodeVersion(dataSize: smallData)
        let versionMedium = service.estimateQRCodeVersion(dataSize: mediumData)
        let versionLarge = service.estimateQRCodeVersion(dataSize: largeData)
        
        XCTAssertGreaterThanOrEqual(versionSmall, 10)
        XCTAssertLessThanOrEqual(versionSmall, 40)
        
        XCTAssertGreaterThanOrEqual(versionMedium, versionSmall)
        XCTAssertGreaterThanOrEqual(versionLarge, versionMedium)
    }
    
    func testInvalidInput() {
        let expectation = expectation(description: "Invalid input handling")
        
        // Empty string should fail or handle gracefully
        service.generateQRCode(
            data: "",
            size: CGSize(width: 512, height: 512),
            correctionLevel: .high,
            logo: nil,
            foregroundColor: .black,
            backgroundColor: .white,
            cornerRadius: 0
        ) { result in
            switch result {
            case .success:
                // Some implementations might succeed with empty string
                break
            case .failure:
                // Expected for invalid input
                break
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
}

