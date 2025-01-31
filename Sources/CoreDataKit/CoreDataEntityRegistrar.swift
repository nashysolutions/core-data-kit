//
//  CoreDataEntityRegistrar.swift
//  persistence
//
//  Created by Robert Nash on 01/01/2025.
//

import Foundation
import CoreData

/// A protocol for managing Core Data entities, defining logic for resolution, retrieval, and insertion to ensure consistent entity management.
///
/// This protocol provides a mechanism for identifying, resolving, and initialising
/// Core Data entities within a given managed object context. It ensures that entities
/// can be retrieved or created as needed while enforcing a structured approach to entity management.
///
/// ## Conformance
/// Types conforming to this protocol must specify an entity type (`T`) that
/// conforms to `IdentifiableEntity` and implement methods for resolving and
/// applying initial metadata.
///
/// ## Defining a Registrar
///
/// A registrar is responsible for resolving or creating entities within a Core Data store.
/// It conforms to `CoreDataEntityRegistrar` by specifying an entity type and providing
/// logic to query existing records or insert new ones.
///
/// ### Example
///
/// ```swift
/// class UserManagedObject: NSManagedObject, IdentifiableEntity {
///
///    let identifierAttributeName: String = "myID"
///
///    var id: UUID {
///        get { return self.myID }
///        set { self.myID = newValue }
///    }
///
///    @NSManaged var myID: UUID
///    /// etc
/// }
///
/// struct UserRegistrar: CoreDataEntityRegistrar {
///
///     let id: UUID
///     let context: NSManagedObjectContext
///
///     func applyInitialMetadata(_ entity: UserManagedObject) {
///         entity.createdAt = Date() // Assign metadata to newly created entities.
///     }
/// }
/// ```
///
/// - Note: Implementers are responsible for calling `context.save()` to persist changes.
public protocol CoreDataEntityRegistrar {
    
    /// The type of entity managed by the provider.
    associatedtype T: IdentifiableEntity

    /// The unique identifier (primary key) for the entity.
    var id: T.ID { get }
    
    /// The Core Data context used for database interactions.
    var context: NSManagedObjectContext { get }
    
    /// The fetch request used to query for a record using the provided identifier (considered the primary key).
    ///
    /// A default implementation is provided for identifiers of type `UUID`.
    /// See `IdentifiableEntity` for details.
    var fetchRequest: NSFetchRequest<T> { get }
        
    /// Applies essential metadata for a newly created entity.
    ///
    /// - Parameter entity: The newly created entity instance.
    ///
    /// This function is called **only when a new entity is created** to ensure
    /// required metadata (such as timestamps and identifiers) is correctly set.
    ///
    /// - Important: This function is intended **only for newly created entities**
    ///   and should not be used to update existing ones.
    func applyInitialMetadata(_ entity: T)
}

public extension CoreDataEntityRegistrar where T.ID == UUID {
    
    var fetchRequest: NSFetchRequest<T> {
        let fetchRequest = NSFetchRequest<T>(entityName: T.entityName)
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "%K == %@", T.identifierAttributeName, id as CVarArg)
        return fetchRequest
    }
}

public extension CoreDataEntityRegistrar {
    
    /// Resolves the entity based on the `fetchRequest`.
    ///
    /// This method attempts to fetch an existing entity from the Core Data store
    /// using the provided `fetchRequest`. If the entity is found, it is returned.
    /// If no entity matches the given identifier, an error of type `CoreDataEntityError.notFound` is thrown.
    /// Other Core Data errors may be thrown if the fetch operation fails.
    ///
    /// - Returns: An instance of `T` representing the resolved entity.
    ///
    /// - Throws:
    ///   - `CoreDataEntityError.notFound` if no entity matches the predicate defined in `fetchRequest`.
    ///   - Other errors may be thrown if the fetch operation fails.
    func query() throws -> T {
        let first = try context.fetch(fetchRequest).first
        switch first {
        case .none:
            throw CoreDataEntityError.notFound
        case .some(let unwrapped):
            return unwrapped
        }
    }
    
    /// Ensures an entity exists by querying for it or inserting a new one if necessary.
    ///
    /// This method first attempts to query an existing entity using `query()`.
    /// If the entity is found, it is returned. If no entity matches the identifier,
    /// a new instance of `T` is created, assigned the provided `id`, and initialised
    /// using `applyInitialMetadata(_:)`.
    ///
    /// If `save` is set to `true`, the entity is automatically persisted by calling `context.save()`.
    ///
    /// - Parameters:
    ///   - save: A Boolean value indicating whether the entity should be saved immediately after creation.
    ///
    /// - Returns: An instance of `T`, either an existing entity or a newly created one.
    ///
    /// - Throws:
    ///   - Any errors encountered during the query process, except for `CoreDataEntityError.notFound`,
    ///     which results in a new entity being created.
    ///   - Errors encountered when attempting to save the context, if `save` is `true`.
    ///
    /// - Important: If `save` is `false`, you must manually chech `context.hasChanges` and call `context.save()` to persist
    /// any changes that might have occured.
    func queryOrInsert(save: Bool = false) throws -> T {
        do {
            return try query()
        } catch CoreDataEntityError.notFound {
            return try create(save: save)
        } catch {
            throw error
        }
    }
    
    /// Inserts a new entity into the Core Data store.
    ///
    /// This method attempts to insert a new instance of the entity into the managed
    /// object context. If an entity with the same identifier already exists, an error
    /// of type `CoreDataEntityError.alreadyExists` is thrown. If no entity matches
    /// the identifier, a new entity is created and initialised using the provided metadata.
    ///
    /// If `save` is set to `true`, the entity is immediately persisted by calling `context.save()`.
    ///
    /// - Parameters:
    ///   - save: A Boolean value indicating whether the entity should be saved immediately after creation.
    ///
    /// - Returns: An instance of `T` representing the newly created entity.
    ///
    /// - Throws:
    ///   - `CoreDataEntityError.alreadyExists`: If an entity with the provided identifier
    ///     already exists in the Core Data store.
    ///   - Other errors encountered during the query process.
    ///   - Errors encountered when attempting to save the context, if `save` is `true`.
    ///
    /// - Important: If `save` is `false`, you must manually call `context.save()` to persist the changes.
    func insert(save: Bool = false) throws -> T {
        
        /// Query for the record
        let record: T
        do {
            record = try query()
        } catch CoreDataEntityError.notFound {
            return try create(save: save)
        } catch {
            throw error
        }
        
        /// If query successful, then throw.
        throw CoreDataEntityError.alreadyExists(record.objectID)
    }
    
    /// Creates a new entity and applies initial metadata.
    ///
    /// This method initialises a new instance of the entity, assigns it the provided `id`,
    /// and applies metadata via `applyInitialMetadata(_:)`. If `save` is `true`, the entity
    /// is immediately persisted by calling `context.save()`.
    ///
    /// - Parameters:
    ///   - save: A Boolean value indicating whether the entity should be saved immediately after creation.
    ///
    /// - Returns: The newly created entity of type `T`.
    ///
    /// - Throws: Errors encountered when attempting to save the context, if `save` is `true`.
    ///
    /// - Important: If `save` is `false`, you must manually call `context.save()` to persist the changes.
    private func create(save: Bool) throws -> T {
        let entity = T(context: context)
        entity.id = id
        applyInitialMetadata(entity)
        if save {
            try context.save()
        }
        return entity
    }
}
