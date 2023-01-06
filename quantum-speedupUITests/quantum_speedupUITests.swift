//
//  quantum_speedupUITests.swift
//  quantum-speedupUITests
//
//  Created by Rustam Khakhuk on 12.11.2022.
//

import XCTest

final class quantum_speedupUITests: XCTestCase {
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
