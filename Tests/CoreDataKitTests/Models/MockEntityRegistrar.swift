//
//  MockEntityRegistrar.swift
//  core-data-kit
//
//  Created by Robert Nash on 02/02/2025.
//

import Foundation
import CoreData
import CoreDataKit

final class MockEntityRegistrar: CoreDataEntityRegistrar {
    
    let identifier: UUID
    let context: NSManagedObjectContext
    
    init(identifier: UUID, context: NSManagedObjectContext) {
        self.identifier = identifier
        self.context = context
    }
    
    func applyInitialMetadata(_ entity: MockManagedObject) {}
}
