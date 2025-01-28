//
//  CoreDataEntityRegistrar.swift
//  persistence
//
//  Created by Robert Nash on 01/01/2025.
//

import Foundation
import CoreData

/// A protocol defining a lightweight provider responsible for managing essential metadata of a Core Data entity.
///
/// `CoreDataEntityRegistrar` ensures that entities in the local database are uniquely identifiable and
/// contain any **non-negotiable** metadata, such as creation timestamps. It does **not** handle domain-specific
/// business logic or custom attributes beyond these essentials.
///
/// Conforming types are responsible for:
/// - Maintaining an `id` value as a unique reference to the entity.
/// - Loading entities based on their unique identifier.
/// - Creating a new entity if it does not already exist.
/// - Applying essential metadata using `applyInitialMetadata(_:)`.
///
/// ### Scope & Limitations
/// - This protocol does **not** manage any properties beyond the unique identifier and required metadata.
/// - It provides a standardised approach for loading and creating database records safely.
/// - Any additional business logic must be implemented separately.
///
/// ## Example
///
/// ```swift
/// struct ChatEntityRegistrar: CoreDataEntityRegistrar {
///     let context: NSManagedObjectContext
///     let id: UUID
///
///     func applyInitialMetadata(_ entity: Chat) {
///         entity.created = Date() // Setting required metadata
///     }
/// }
/// ```
///
/// - Note: If an entity requires further customisation, this should be handled independently.
///
/// - Warning: Ensure `load()` is correctly implemented to prevent unnecessary duplicate record creation.
public protocol CoreDataEntityRegistrar {
    
    /// The type of entity managed by the provider.
    associatedtype T: IdentifiableEntity

    /// The unique identifier for the entity.
    var id: T.ID { get }
    
    /// The Core Data context used for database interactions.
    var context: NSManagedObjectContext { get }
    
    /// Loads the entity corresponding to the given `id`, if it exists.
    ///
    /// This function is used to check whether an entity is already present in the database.
    /// It must be implemented in a way that ensures efficient retrieval of a single record.
    ///
    /// - Returns: The entity if it exists, otherwise `nil`.
    /// - Throws: `CoreDataEntityRegistrarError` if a database issue occurs.
    func load() throws(CoreDataEntityRegistrarError) -> T?
    
    /// Applies essential metadata for a newly created entity.
    ///
    /// - Parameter entity: The newly created entity instance.
    ///
    /// This function is called **only when a new entity is created** to ensure
    /// required metadata (such as timestamps and identifiers) is correctly set.
    ///
    /// - Important: This function **must not** be used to modify existing records.
    func applyInitialMetadata(_ entity: T)
}

public extension CoreDataEntityRegistrar {
    
    /// Creates a new entity if one does not already exist.
    ///
    /// - Throws: `CoreDataEntityRegistrarError` if a database issue occurs.
    ///
    /// This method ensures that a new entity is instantiated only when one does not already exist.
    /// The entity is then configured using `applyInitialMetadata(_:)` before being persisted.
    ///
    /// - Note: `applyInitialMetadata(_:)` **must not** be used outside of this function.
    func create() throws(CoreDataEntityRegistrarError) {
        
        if try load() != nil {
            throw CoreDataEntityRegistrarError.alreadyExists
        }
        
        let entity = T(context: context)
        entity.id = id
        applyInitialMetadata(entity)
    }
    
    /// Ensures the entity exists, throwing an error if it does not.
    ///
    /// This function is useful for cases where the existence of the entity is required before proceeding.
    ///
    /// - Returns: The existing entity.
    /// - Throws: `CoreDataEntityRegistrarError` if a database issue occurs.
    func require() throws(CoreDataEntityRegistrarError) -> T {
        
        let record: T?
        do {
            record = try load()
        } catch {
            throw CoreDataEntityRegistrarError.unexpectedError(error)
        }
        
        guard let record else {
            throw CoreDataEntityRegistrarError.notFound
        }
        
        return record
    }
}
