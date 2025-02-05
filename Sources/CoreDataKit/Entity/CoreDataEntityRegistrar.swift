//
//  CoreDataEntityRegistrar.swift
//  persistence
//
//  Created by Robert Nash on 01/01/2025.
//

import Foundation
import CoreData

/// A protocol for managing Core Data entities, ensuring structured resolution, retrieval, and insertion.
///
/// This protocol defines a mechanism for handling Core Data entities within a given
/// `NSManagedObjectContext`. It provides **consistent** entity management by:
/// - Resolving entities based on their primary key.
/// - Ensuring entities can be retrieved or created as needed.
/// - Applying initial metadata when a new entity is created.
///
/// - Important: Conforming types must specify an entity type (`Record`) that conforms to `IdentifiableEntity`.
///
/// ## **Usage**
///
/// Conforming types implement logic to resolve or create an entity based on its **unique identifier**.
/// This enables a structured approach to entity management in Core Data.
///
/// ### **Example**
///
/// ```swift
/// class UserManagedObject: NSManagedObject, IdentifiableEntity {
///     static let identifierAttributeName = "myID"
///
///     var id: UUID {
///         get { return myID }
///         set { myID = newValue }
///     }
///
///     @NSManaged var myID: UUID
/// }
///
/// struct UserRegistrar: CoreDataEntityRegistrar {
///
///     let identifier: UUID
///     let context: NSManagedObjectContext
///
///     func applyInitialMetadata(_ entity: UserManagedObject) {
///         entity.createdAt = Date() // Assigns metadata when an entity is first created.
///     }
/// }
/// ```
///
/// - Note: Implementers must **explicitly save** the `context` if they want to persist changes.
public protocol CoreDataEntityRegistrar {
    
    /// The type of entity managed by this registrar.
    associatedtype Record: IdentifiableEntity

    /// The unique identifier (primary key) for the entity.
    var identifier: Record.ID { get }
    
    /// The Core Data context used for database operations.
    var context: NSManagedObjectContext { get }
    
    /// The fetch request used to retrieve a record using the identifier (primary key).
    ///
    /// A **default implementation** is provided for identifiers of type `UUID` (see `IdentifiableEntity`).
    var fetchRequest: NSFetchRequest<Record> { get }
    
    /// Initializes the registrar with an identifier and a Core Data context.
    ///
    /// - Parameters:
    ///   - identifier: The unique primary key for the entity.
    ///   - context: The `NSManagedObjectContext` used for database interactions.
    init(identifier: Record.ID, context: NSManagedObjectContext)
        
    /// Applies initial metadata to a newly created entity.
    ///
    /// - Parameter entity: The newly created entity instance.
    ///
    /// This method is called **only when an entity is created** to assign metadata
    /// such as timestamps or default values.
    ///
    /// - Important: This function is **not** meant for updating existing entities.
    func applyInitialMetadata(_ entity: Record)
}

public extension CoreDataEntityRegistrar {
    
    /// A Boolean value indicating whether an entity with the specified identifier exists in Core Data.
    ///
    /// This computed property executes a fetch request using the registrar's `fetchRequest`
    /// and determines whether at least one matching entity is present in the database.
    ///
    /// - Returns: `true` if an entity with the given identifier exists; otherwise, `false`.
    ///
    /// - Throws: An error if the fetch request fails due to persistent store issues.
    var exists: Bool {
        get throws {
            let first = try context.fetch(fetchRequest).first
            return first != nil
        }
    }
    
    /// Retrieves an entity based on the `fetchRequest`.
    ///
    /// Attempts to fetch an entity from Core Data that matches the **primary key**.
    /// If the entity exists, it is returned. If no entity is found, an error of type
    /// `CoreDataEntityError.notFound` is thrown.
    ///
    /// - Returns: An instance of `Record` representing the retrieved entity.
    ///
    /// - Throws:
    ///   - `CoreDataEntityError.notFound` if no entity matches the identifier.
    ///   - Other Core Data errors if the fetch request fails.
    func query() throws -> Record {
        let first = try context.fetch(fetchRequest).first
        switch first {
        case .none:
            throw CoreDataEntityError.notFound
        case .some(let unwrapped):
            return unwrapped
        }
    }
    
    /// Retrieves an entity or inserts a new one if it does not exist.
    ///
    /// - If the entity is found, it is returned.
    /// - If no entity exists, a new one is created, initialized, and optionally persisted.
    ///
    /// - Parameters:
    ///   - save: If `true`, the context is immediately saved after insertion.
    ///
    /// - Returns: An instance of `Record`.
    ///
    /// - Throws:
    ///   - Errors from `query()`, unless `CoreDataEntityError.notFound`, which results in insertion.
    ///   - Errors from `context.save()` if `save` is `true`.
    func queryOrInsert(save: Bool = false) throws -> Record {
        do {
            return try query()
        } catch CoreDataEntityError.notFound {
            return try create(save: save)
        } catch {
            throw error
        }
    }
    
    /// Inserts a new entity into Core Data.
    ///
    /// If an entity with the same identifier already exists, this method throws an error.
    ///
    /// - Parameters:
    ///   - save: If `true`, the context is immediately saved after insertion.
    ///
    /// - Returns: A newly inserted `Record`.
    ///
    /// - Throws:
    ///   - `CoreDataEntityError.alreadyExists` if an entity with the identifier already exists.
    ///   - Other errors from Core Data during save operations.
    func insert(save: Bool = false) throws -> Record {
        let record: Record
        do {
            record = try query()
        } catch CoreDataEntityError.notFound {
            return try create(save: save)
        } catch {
            throw error
        }
        
        throw CoreDataEntityError.alreadyExists(record.objectID)
    }
    
    /// Creates a new entity and applies initial metadata.
    ///
    /// - Parameters:
    ///   - save: If `true`, the context is immediately saved.
    ///
    /// - Returns: A newly created `Record`.
    ///
    /// - Throws: Errors from `context.save()` if `save` is `true`.
    private func create(save: Bool) throws -> Record {
        let entity = Record(context: context)
        entity.id = identifier
        applyInitialMetadata(entity)
        if save {
            try context.save()
        }
        return entity
    }
}

// MARK: FetchRequest

public extension CoreDataEntityRegistrar where Record.ID == UUID {
    
    /// A fetch request for retrieving an entity using a `UUID` identifier.
    var fetchRequest: NSFetchRequest<Record> {
        makeFetchRequest(
            identifier: identifier as CVarArg,
            entityName: Record.entityName,
            identifierKey: Record.identifierAttributeName
        )
    }
}

public extension CoreDataEntityRegistrar where Record.ID: CVarArg {
    
    /// A fetch request for retrieving an entity using a primary key that conforms to `CVarArg`.
    var fetchRequest: NSFetchRequest<Record> {
        makeFetchRequest(
            identifier: identifier,
            entityName: Record.entityName,
            identifierKey: Record.identifierAttributeName
        )
    }
}

/// Constructs a fetch request for querying an entity by its primary key.
///
/// - Parameters:
///   - identifier: The unique identifier.
///   - entityName: The Core Data entity name.
///   - identifierKey: The attribute name corresponding to the identifier.
///
/// - Returns: An `NSFetchRequest<Record>` configured for single-record retrieval.
private func makeFetchRequest<Record>(
    identifier: CVarArg,
    entityName: String,
    identifierKey: String
) -> NSFetchRequest<Record> {
    let fetchRequest = NSFetchRequest<Record>(entityName: entityName)
    fetchRequest.fetchLimit = 1
    fetchRequest.predicate = NSPredicate(format: "%K == %@", identifierKey, identifier)
    return fetchRequest
}
