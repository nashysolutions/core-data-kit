//
//  MockManagedObject.swift
//  core-data-kit
//
//  Created by Robert Nash on 28/01/2025.
//

import Foundation
import CoreData
import CoreDataKit

final class MockManagedObject: NSManagedObject, IdentifiableEntity {
    
    static let identifierAttributeName: String = "identifier"
    
    var id: UUID {
        get { return self.identifier }
        set { self.identifier = newValue }
    }
        
    @NSManaged var identifier: UUID
    @NSManaged var name: String
}
