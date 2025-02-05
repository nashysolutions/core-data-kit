//
//  MockNSManagedObjectContext.swift
//  persistence
//
//  Created by Robert Nash on 03/01/2025.
//

import Foundation
import CoreData

final class MockNSManagedObjectContext: NSManagedObjectContext {
    
    private var fetchError: Error?

    override func execute(_ request: NSPersistentStoreRequest) throws -> NSPersistentStoreResult {
        if let fetchError = fetchError, request is NSFetchRequest<NSFetchRequestResult> {
            throw fetchError
        }
        return try super.execute(request)
    }

    func simulateFetchError(_ error: Error) {
        self.fetchError = error
    }
}
