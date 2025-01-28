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
    
    init(context: NSManagedObjectContext, id: UUID) {
        self.context = context
        self.id = id
    }
    
    func applyInitialMetadata(_ entity: MockManagedObject) {
    }
}

extension IdentifiableEntity {

    static var identifierAttributeName: String {
        return "identifier"
    }
}

extension CoreDataEntityRegistrar where T.ID == UUID {

    func load() throws(CoreDataEntityRegistrarError) -> T? {
        
        let fetchRequest = T.fetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "%K == %@", T.identifierAttributeName, id as CVarArg)

        do {
            let results = try context.fetch(fetchRequest) as? [Self.T]
            return results?.first
        } catch {
            throw CoreDataEntityRegistrarError.unexpectedError(error)
        }
    }
}
