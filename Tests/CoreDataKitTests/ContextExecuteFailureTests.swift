//
//  ContextExecuteFailureTests.swift
//  core-data-kit
//
//  Created by Robert Nash on 31/01/2025.
//

import Foundation
import XCTest
import CoreData
import CoreDataKit

final class ContextExecuteFailureTests: XCTestCase {
    
    private let error = NSError(
        domain: "AnyDomain",
        code: 123,
        userInfo: nil
    )
    
    private let context = MockNSManagedObjectContext(
        concurrencyType: .mainQueueConcurrencyType
    )
    
    var registrar: MockEntityRegistrar {
        MockEntityRegistrar(identifier: identifier, context: context)
    }
    
    private let identifier = UUID()
    
    override func setUp() {
        super.setUp()
        context.simulateFetchError(error)
    }
    
    func testInsertFailsForOtherReason() {
        XCTAssertThrowsError(try registrar.insert(save: false))
    }
    
    func testQueryFailsForOtherReason() {
        XCTAssertThrowsError(try registrar.query())
    }
    
    func testQueryOrInsertFailsForOtherReason() {
        XCTAssertThrowsError(try registrar.queryOrInsert(save: false))
    }
}
