//
//  DatabaseQuery.swift
//  core-data-kit
//
//  Created by Robert Nash on 04/02/2025.
//

import Foundation
import CoreData
import NonEmpty

/// A generic query class for executing Core Data fetch requests.
open class DatabaseQuery<T: NSFetchRequestResult>: DatabaseQueryable, ObservableObject {
    
    /// The Core Data managed object context used for fetching data.
    public let context: NSManagedObjectContext
    
    /// The fetch request used to retrieve database records.
    public let fetchRequest: NSFetchRequest<T>
    
    /// The current result of the query operation.
    ///
    /// This property is used to track the state of a database query.
    @Published public var result: DatabaseQueryResult<NonEmpty<[T]>>?
    
    /// Initializes a query with a fetch request and managed object context.
    ///
    /// - Parameters:
    ///   - fetchRequest: The Core Data fetch request specifying the query criteria.
    ///   - context: The Core Data managed object context used to execute the query.
    public init(fetchRequest: NSFetchRequest<T>, context: NSManagedObjectContext) {
        self.context = context
        self.fetchRequest = fetchRequest
    }
}
