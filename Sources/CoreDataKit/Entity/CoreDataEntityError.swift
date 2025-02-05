//
//  CoreDataEntityError.swift
//  persistence
//
//  Created by Robert Nash on 01/01/2025.
//

import Foundation
import CoreData

/// An error type representing issues encountered when managing Core Data entities.
///
/// This enum defines errors related to Core Data entity resolution, such as when an entity
/// cannot be found or when an attempt is made to insert a duplicate entity.
///
/// - Note: These errors are commonly thrown when querying or inserting entities within a
///   `CoreDataEntityRegistrar` implementation.
public enum CoreDataEntityError: Error {

    /// The requested entity could not be found in the Core Data store.
    ///
    /// This error is thrown when a fetch request returns no results for a given query.
    case notFound

    /// An entity with the same unique identifier already exists.
    ///
    /// This error occurs when attempting to insert a new entity that conflicts
    /// with an existing one. The associated `NSManagedObjectID` provides
    /// a reference to the pre-existing entity.
    ///
    /// - Parameter objectID: The unique identifier of the existing entity in Core Data.
    case alreadyExists(NSManagedObjectID)
}
