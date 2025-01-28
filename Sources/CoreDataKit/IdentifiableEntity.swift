//
//  IdentifiableEntity.swift
//  persistence
//
//  Created by Robert Nash on 01/01/2025.
//

import Foundation
import CoreData

public protocol IdentifiableEntity: NSManagedObject {
    associatedtype ID
    var id: ID { get set }
    var identifierAttributeName: String { get }
}
