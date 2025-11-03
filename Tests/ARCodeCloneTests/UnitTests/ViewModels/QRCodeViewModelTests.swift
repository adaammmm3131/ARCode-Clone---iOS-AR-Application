//
//  QRCodeViewModelTests.swift
//  ARCodeCloneTests
//
//  Unit tests for QRCodeViewModel with dependency injection
//

import XCTest
@testable import ARCodeClone
import Combine

final class QRCodeViewModelTests: XCTestCase {
    var viewModel: QRCodeViewModel!
    var mockQRService: MockQRCodeGenerationService!
    var mockURLService: MockQRCodeURLService!
    var mockDesignService: MockQRCodeDesignService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        
        mockQRService = MockQRCodeGenerationService()
        mockURLService = MockQRCodeURLService()
        mockDesignService = MockQRCodeDesignService()
        
        viewModel = QRCodeViewModel(
            qrGenerationService: mockQRService,
            urlService: mockURLService,
            designService: mockDesignService
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockQRService = nil
        mockURLService = nil
        mockDesignService = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testViewModelInitialization() {
        XCTAssertNotNil(viewModel.arCodeId)
        XCTAssertEqual(viewModel.contentType, "object_capture")
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testGenerateQRCode() {
        let expectation = expectation(description: "Generate QR Code")
        
        viewModel.generateQRCode()
        
        // Wait for async operation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertFalse(self.viewModel.isLoading)
            XCTAssertNotNil(self.viewModel.qrCodeImage)
            XCTAssertFalse(self.viewModel.shortURL.isEmpty)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testSetLogo() {
        let testImage = UIImage(systemName: "star.fill")!
        viewModel.setLogo(image: testImage)
        
        XCTAssertEqual(viewModel.selectedLogo, testImage)
    }
    
    func testExportPNG() {
        // Setup: Generate QR code first
        let expectation = expectation(description: "Export PNG")
        
        viewModel.generateQRCode()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let pngData = self.viewModel.exportQRCodePNG()
            XCTAssertNotNil(pngData)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testCleanup() {
        viewModel.arCodeId = "test-id"
        viewModel.qrCodeImage = UIImage()
        viewModel.shortURL = "https://test.com"
        
        viewModel.cleanup()
        
        XCTAssertNotEqual(viewModel.arCodeId, "test-id")
        XCTAssertNil(viewModel.qrCodeImage)
        XCTAssertTrue(viewModel.shortURL.isEmpty)
    }
}

// MARK: - Mock Services

class MockQRCodeGenerationService: QRCodeGenerationServiceProtocol {
    var shouldSucceed: Bool = true
    
    func generateQRCode(
        data: String,
        size: CGSize,
        correctionLevel: QRCodeErrorCorrection,
        logo: UIImage?,
        foregroundColor: UIColor,
        backgroundColor: UIColor,
        cornerRadius: CGFloat,
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) {
        if shouldSucceed {
            // Create mock QR code image
            let image = UIImage(systemName: "qrcode")!
            completion(.success(image))
        } else {
            completion(.failure(NSError(domain: "QRGenerationError", code: -1)))
        }
    }
    
    func estimateQRCodeVersion(dataSize: Int) -> Int {
        return 20 // Mock version
    }
}

class MockQRCodeURLService: QRCodeURLServiceProtocol {
    func generateShortURL(
        arCodeId: String,
        contentType: String,
        assetId: String?,
        params: [String: Any]?
    ) -> String {
        return "https://ar-code.com/a/mock123"
    }
    
    func parseShortURL(url: String) -> QRCodeMetadata? {
        return QRCodeMetadata(
            arCodeId: "mock-id",
            contentType: "object_capture",
            assetId: nil,
            params: [:]
        )
    }
    
    func generateUniqueID() -> String {
        return "mock-unique-id"
    }
}

class MockQRCodeDesignService: QRCodeDesignServiceProtocol {
    func applyDesign(
        to qrCodeImage: UIImage,
        primaryColor: UIColor,
        backgroundColor: UIColor,
        logo: UIImage?,
        cornerRadius: CGFloat,
        resolution: CGFloat
    ) -> UIImage {
        return qrCodeImage
    }
    
    func exportToPNG(_ image: UIImage, resolution: CGFloat) -> Data? {
        return image.pngData()
    }
    
    func exportToSVG(_ qrCodeImage: UIImage, primaryColor: UIColor, backgroundColor: UIColor, logo: UIImage?) -> String? {
        return "<svg>...</svg>"
    }
}

