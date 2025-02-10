//
//  CoreDataEntityRegistrarTests.swift
//  persistence
//
//  Created by Robert Nash on 03/01/2025.
//

import Foundation
import XCTest
import CoreData
import CoreDataKit

final class CoreDataEntityRegistrarTests: XCTestCase {
    
    var container: NSPersistentContainer!
    let entityName = "MockManagedObject"
    let storeURL = URL(fileURLWithPath: "/dev/null")
    
    override func setUp() {
        super.setUp()
        
        let entity = NSEntityDescription()
        entity.name = entityName
        entity.managedObjectClassName = NSStringFromClass(MockManagedObject.self)
        
        let identifierAttribute = NSAttributeDescription()
        identifierAttribute.name = "identifier"
        identifierAttribute.attributeType = .UUIDAttributeType
        identifierAttribute.isOptional = false
        
        let createdAttribute = NSAttributeDescription()
        createdAttribute.name = "name"
        createdAttribute.attributeType = .dateAttributeType
        identifierAttribute.isOptional = false
        
        entity.properties = [identifierAttribute, createdAttribute]
        
        let model = NSManagedObjectModel()
        model.entities = [entity]
        
        container = NSPersistentContainer(name: "TestContainer", managedObjectModel: model)
        let description = NSPersistentStoreDescription()
        description.url = storeURL
        description.type = NSSQLiteStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores {
            if let error = $1 {
                XCTFail("Failed to load persistent stores: \(error)")
            }
        }
    }
    
    func testPrimaryKeyQuerySuccess() throws {
        
        /// Given
        ///
        /// 1. A concrete implementation of `CoreDataEntityRegistrar`.
        /// 2. A pre-existing entity saved in the db.
        let context = container.viewContext
        let identifier = UUID()
        
        let record = MockManagedObject(context: context)
        record.identifier = identifier
        try context.save()
        
        let recordProvider = PrimaryKeyQuery<MockEntityRegistrar>(identifier: identifier, context: context)
        
        /// When
        ///
        /// We call the `perform` method.
        recordProvider.perform()
        
        switch recordProvider.result {
        case .records(let records):
            /// Then
            ///
            /// The method should return the existing record.
            let first = records.first
            XCTAssertEqual(first.identifier, identifier, "Loaded record does not have the expected identifier.")
        case .performed:
            XCTFail("Expected throw")
        default:
            XCTFail("Expected performed. Found: \(String(describing: recordProvider.result))")
        }
    }
    
    func testPrimaryKeyQueryNotFound() {
        /// Given
        ///
        /// 1. A concrete implementation of `CoreDataEntityRegistrar`.
        /// 2. No pre-existing records saved in db.
        let context = container.viewContext
        let recordProvider = PrimaryKeyQuery<MockEntityRegistrar>(identifier: UUID(), context: context)
        let timestamp = Date()
        
        /// When
        ///
        /// We call the `perform` method.
        recordProvider.perform(timestamp: timestamp)
        
        switch recordProvider.result {
        case .performed(let date):
            XCTAssertEqual(date, timestamp)
        default:
            XCTFail("Expected throw. Found: \(String(describing: recordProvider.result))")
        }
    }
}
