//
//  MockManagedObjectProvider.swift
//  persistence
//
//  Created by Robert Nash on 31/12/2024.
//

import Foundation
import CoreData
import CoreDataKit

struct MockManagedObjectProvider: CoreDataEntityRegistrar {
    
    let context: NSManagedObjectContext
    let id: UUID
    
    func applyInitialMetadata(_ entity: MockManagedObject) {
    }
}
