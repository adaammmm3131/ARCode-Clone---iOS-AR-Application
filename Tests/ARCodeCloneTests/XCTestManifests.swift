//
//  XCTestManifests.swift
//  ARCodeCloneTests
//
//  Test manifest for Linux compatibility
//

import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(ARCodeTests.allTests),
        testCase(NetworkServiceTests.allTests),
        testCase(QRCodeGenerationServiceTests.allTests),
        testCase(QRCodeViewModelTests.allTests),
        testCase(APIIntegrationTests.allTests),
        testCase(ARPlaneDetectionTests.allTests),
        testCase(ARPerformanceTests.allTests)
    ]
}
#endif







