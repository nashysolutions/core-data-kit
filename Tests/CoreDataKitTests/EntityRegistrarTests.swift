//
//  EntityRegistrarTests.swift
//  core-data-kit
//
//  Created by Robert Nash on 02/02/2025.
//

import Foundation
import CoreData
import CoreDataKit
import XCTest

final class EntityRegistrarTests: XCTestCase {
    
    var container: NSPersistentContainer!
    let storeURL = URL(fileURLWithPath: "/dev/null")
    
    override func setUp() {
        super.setUp()
        
        let entity = NSEntityDescription()
        entity.name = "MockManagedObject"
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
    
    func testQueryOrInsertRecordSuccessfully() throws {
        
        /// Given
        ///
        /// A concrete implementation of `CoreDataEntityRegistrar`.
        let context = container.viewContext
        let identifier = UUID()
        let recordProvider = MockEntityRegistrar(identifier: identifier, context: context)
        
        /// When
        ///
        /// Call the `queryOrInsert` method.
        _ = try recordProvider.queryOrInsert(save: false)
        
        /// Then
        ///
        /// A new record with the given identifier should exist in the database.
        let fetchRequest: NSFetchRequest<MockManagedObject> = .init(entityName: "MockManagedObject")
        fetchRequest.predicate = NSPredicate(format: "identifier == %@", identifier as CVarArg)
        let result = try context.fetch(fetchRequest)
        
        XCTAssertEqual(result.count, 1, "Expected exactly one record but found \(result.count).")
        XCTAssertEqual(result.first?.identifier, identifier, "The created record does not have the expected identifier.")
    }
    
    func testQueryOrInsertWhenAlreadyExists() throws {
        
        /// Given
        ///
        /// 1. A concrete implementation of `CoreDataEntityRegistrar`.
        /// 2. A pre-existing entity saved in the db.
        let context = container.viewContext
        let identifier = UUID()
        
        let record = MockManagedObject(context: context)
        record.identifier = identifier
        try context.save()
        
        let recordProvider = MockEntityRegistrar(identifier: identifier, context: context)
        
        /// When
        ///
        /// Call the `queryOrInsert` method.
        _ = try recordProvider.queryOrInsert(save: false)
        
        /// Then
        ///
        /// 1. Another record is not created.
        /// 2. Instead the existing one is fetched.
        let fetchRequest: NSFetchRequest<MockManagedObject> = .init(entityName: "MockManagedObject")
        fetchRequest.predicate = NSPredicate(format: "identifier == %@", identifier as CVarArg)
        let result = try context.count(for: fetchRequest)
        XCTAssertTrue(result == 1)
    }
    
    func testInsert() throws {
        /// Given
        ///
        /// 1. A concrete implementation of `CoreDataEntityRegistrar`.
        /// 2. No pre-existing records saved in db.
        let context = container.viewContext
        let identifier = UUID()
        let recordProvider = MockEntityRegistrar(identifier: identifier, context: context)
        
        /// When
        ///
        /// We call the `insert` method.
        _ = try recordProvider.insert(save: false)
        
        /// Then
        ///
        /// 1. We do not throw.
        /// 2. A record exists in the db.
        let fetchRequest: NSFetchRequest<MockManagedObject> = .init(entityName: "MockManagedObject")
        fetchRequest.predicate = NSPredicate(format: "identifier == %@", identifier as CVarArg)
        let count = try context.count(for: fetchRequest)
        XCTAssertTrue(count == 1)
    }
    
    func testInsertWithPreExistingRecord() throws {
        /// Given
        ///
        /// 1. A concrete implementation of `CoreDataEntityRegistrar`.
        /// 2. A pre-existing record saved in db.
        let context = container.viewContext
        let identifier = UUID()
        let recordProvider = MockEntityRegistrar(identifier: identifier, context: context)
        
        let record = MockManagedObject(context: context)
        record.identifier = identifier
        try context.save()
        
        /// When
        ///
        /// We call the `insert` method.
        do {
            let result = try recordProvider.insert(save: false)
            XCTFail("Expected throw. Got result: \(result)")
        } catch CoreDataEntityError.alreadyExists(let objectID) {
            XCTAssertEqual(record.objectID, objectID)
        } catch {
            XCTFail("Expected throw. Found \(error)")
        }
    }
}
