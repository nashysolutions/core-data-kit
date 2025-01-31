//
//  IdentifiableEntity.swift
//  persistence
//
//  Created by Robert Nash on 01/01/2025.
//

import Foundation
import CoreData

/// A protocol representing a Core Data entity with a unique identifier.
///
/// This protocol defines a Core Data entity that has a distinct identifier,
/// allowing it to be queried and managed efficiently. Conforming types
/// must provide an `id` property and specify the identifier’s attribute name.
///
/// - Note: The default identifier attribute name is `"identifier"`, but
///   this can be overridden if necessary.
public protocol IdentifiableEntity: NSManagedObject {
    
    /// The type used as the unique identifier for the entity.
    associatedtype ID
    
    /// The unique identifier (primary key) for this entity.
    var id: ID { get set }
    
    /// The Core Data entity name associated with the registrar's entity type.
    ///
    /// This property provides the name of the Core Data entity that corresponds
    /// to the generic type `T`. By default, it returns the class name of `T`,
    /// assuming the entity name in the Core Data model matches the class name.
    ///
    /// - Returns: A `String` representing the Core Data entity name.
    ///
    /// - Note: If the entity name in the Core Data model differs from the class name,
    ///   consider overriding this property to return the correct name.
    static var entityName: String { get }
    
    /// The name of the Core Data attribute used to store the unique identifier.
    ///
    /// This is used when constructing predicates and fetch requests to
    /// identify entities by their primary key.
    ///
    /// - Note: If the attribute name for your identifier field is different
    /// from 'identifier', consider overriding this property to return the correct name.
    static var identifierAttributeName: String { get }
}

public extension IdentifiableEntity {
    
    static var entityName: String {
        String(describing: self)
    }
    
    /// The default name for the identifier attribute in Core Data.
    ///
    /// By default, this property returns `"identifier"`. If an entity
    /// uses a different attribute name for its unique identifier, it should
    /// override this value.
    static var identifierAttributeName: String {
        return "identifier"
    }
}
