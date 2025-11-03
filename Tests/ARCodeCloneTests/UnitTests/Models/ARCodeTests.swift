//
//  ARCodeTests.swift
//  ARCodeCloneTests
//
//  Unit tests for ARCode model
//

import XCTest
@testable import ARCodeClone

final class ARCodeTests: XCTestCase {
    
    func testARCodeInitialization() {
        let arCode = ARCode(
            id: "test-id",
            title: "Test AR Code",
            description: "Test description",
            type: .objectCapture,
            qrCodeURL: "https://ar-code.com/a/test",
            assetURL: "https://ar-code.com/assets/test.usdz",
            thumbnailURL: "https://ar-code.com/thumbnails/test.png",
            createdAt: Date(),
            updatedAt: Date(),
            userId: "user-123",
            isPublic: true,
            metadata: ["scans": 100]
        )
        
        XCTAssertEqual(arCode.id, "test-id")
        XCTAssertEqual(arCode.title, "Test AR Code")
        XCTAssertEqual(arCode.type, .objectCapture)
        XCTAssertTrue(arCode.isPublic)
    }
    
    func testARCodeCodable() throws {
        let arCode = ARCode(
            id: "test-id",
            title: "Test",
            description: nil,
            type: .video,
            qrCodeURL: "https://ar-code.com/a/test",
            assetURL: nil,
            thumbnailURL: nil,
            createdAt: Date(),
            updatedAt: Date(),
            userId: "user-123",
            isPublic: false,
            metadata: [:]
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(arCode)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ARCode.self, from: data)
        
        XCTAssertEqual(arCode.id, decoded.id)
        XCTAssertEqual(arCode.title, decoded.title)
        XCTAssertEqual(arCode.type, decoded.type)
    }
    
    func testARCodeTypeEnum() {
        XCTAssertEqual(ARCodeType.objectCapture.rawValue, "object_capture")
        XCTAssertEqual(ARCodeType.faceFilter.rawValue, "face_filter")
        XCTAssertEqual(ARCodeType.video.rawValue, "video")
    }
}







