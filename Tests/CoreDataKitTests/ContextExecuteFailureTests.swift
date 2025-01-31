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
    
    private let id = UUID()
    
    var provider: MockManagedObjectProvider {
        MockManagedObjectProvider(context: context, id: id)
    }
    
    override func setUp() {
        super.setUp()
        context.simulateFetchError(error)
    }
    
    func testInsertFailsForOtherReason() {
        XCTAssertThrowsError(try provider.insert(save: false))
    }
    
    func testQueryFailsForOtherReason() {
        XCTAssertThrowsError(try provider.query())
    }
    
    func testQueryOrInsertFailsForOtherReason() {
        XCTAssertThrowsError(try provider.queryOrInsert(save: false))
    }
}
