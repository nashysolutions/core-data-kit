//
//  PrimaryKeyQuery.swift
//  core-data-kit
//
//  Created by Robert Nash on 04/02/2025.
//

import Foundation
import CoreData

/// A query for retrieving a single database record using its primary key.
public final class PrimaryKeyQuery<Registrar: CoreDataEntityRegistrar>: DatabaseQuery<Registrar.Record> {
    
    /// Initialises a query for a specific entity using its identifier.
    ///
    /// - Parameters:
    ///   - identifier: The unique primary key of the entity to query.
    ///   - context: The Core Data managed object context used for fetching data.
    public init(identifier: Record.ID, context: NSManagedObjectContext) {
        let database = Registrar(identifier: identifier, context: context)
        let fetchRequest = database.fetchRequest
        super.init(fetchRequest: fetchRequest, context: context)
    }
}
