//
//  DatabaseQueryable.swift
//  core-data-kit
//
//  Created by Robert Nash on 02/02/2025.
//

import Foundation
import CoreData
import NonEmpty

/// A protocol that defines a queryable database entity.
///
/// Types conforming to this protocol must provide a fetch request,
/// an result state representing the query result, and an execution method.
public protocol DatabaseQueryable: AnyObject {

    /// The type of record returned by the query.
    associatedtype Record: NSFetchRequestResult

    /// The result of a query operation.
    var result: DatabaseQueryResult<NonEmpty<[Record]>>? { get set }

    /// The Core Data fetch request used to retrieve records.
    var fetchRequest: NSFetchRequest<Record> { get }

    /// The Core Data managed object context used for fetching data.
    var context: NSManagedObjectContext { get }

    /// Executes the database query and updates the `result` state accordingly.
    ///
    /// - Parameter timestamp: The time at which the query was executed.
    func perform(timestamp: Date)
}

public extension DatabaseQueryable {
    
    /// Executes a fetch request and updates `result`.
    func perform(timestamp: Date = Date()) {
        do {
            let fetchedObjects = try context.fetch(fetchRequest) as [Record]
            switch fetchedObjects.isEmpty {
            case true:
                result = .performed(timestamp)
            case false:
                let records = NonEmpty(rawValue: fetchedObjects)!
                result = .records(records)
            }
        } catch {
            result = .failure(error)
        }
    }
}
