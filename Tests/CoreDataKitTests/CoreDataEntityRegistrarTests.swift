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
        let id = UUID()
        let recordProvider = MockManagedObjectProvider(context: context, id: id)
        
        /// When
        ///
        /// Call the `queryOrInsert` method.
        _ = try recordProvider.queryOrInsert(save: false)
        
        /// Then
        ///
        /// A new record with the given identifier should exist in the database.
        let fetchRequest: NSFetchRequest<MockManagedObject> = .init(entityName: "MockManagedObject")
        fetchRequest.predicate = NSPredicate(format: "identifier == %@", id as CVarArg)
        let result = try context.fetch(fetchRequest)
        
        XCTAssertEqual(result.count, 1, "Expected exactly one record but found \(result.count).")
        XCTAssertEqual(result.first?.identifier, id, "The created record does not have the expected identifier.")
    }
    
    func testQueryOrInsertWhenAlreadyExists() throws {
        
        /// Given
        ///
        /// 1. A concrete implementation of `CoreDataEntityRegistrar`.
        /// 2. A pre-existing entity saved in the db.
        let context = container.viewContext
        let id = UUID()
        
        let record = MockManagedObject(context: context)
        record.identifier = id
        try context.save()
        
        let recordProvider = MockManagedObjectProvider(context: context, id: id)
        
        /// When
        ///
        /// Call the `queryOrInsert` method.
        _ = try recordProvider.queryOrInsert(save: false)
        
        /// Then
        ///
        /// 1. Another record is not created.
        /// 2. Instead the existing one is fetched.
        let fetchRequest: NSFetchRequest<MockManagedObject> = .init(entityName: "MockManagedObject")
        fetchRequest.predicate = NSPredicate(format: "identifier == %@", id as CVarArg)
        let result = try context.count(for: fetchRequest)
        XCTAssertTrue(result == 1)
    }
    
    func testQuerySuccess() throws {
        
        /// Given
        ///
        /// 1. A concrete implementation of `CoreDataEntityRegistrar`.
        /// 2. A pre-existing entity saved in the db.
        let context = container.viewContext
        let id = UUID()
        
        let record = MockManagedObject(context: context)
        record.identifier = id
        try context.save()
        
        let recordProvider = MockManagedObjectProvider(context: context, id: id)
        
        /// When
        ///
        /// We call the `query` method.
        let result = try recordProvider.query()
        
        /// Then
        ///
        /// The method should return the existing record.
        XCTAssertEqual(result.identifier, id, "Loaded record does not have the expected identifier.")
    }
    
    func testQueryNotFound() {
        /// Given
        ///
        /// 1. A concrete implementation of `CoreDataEntityRegistrar`.
        /// 2. No pre-existing records saved in db.
        let context = container.viewContext
        let recordProvider = MockManagedObjectProvider(context: context, id: UUID())
        
        /// When
        ///
        /// We call the `query` method.
        do {
            let result = try recordProvider.query()
            XCTFail("Expected throw. Found: \(result)")
        } catch CoreDataEntityError.notFound {
            /// Then
            ///
            /// The method should throw.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testInsert() throws {
        /// Given
        ///
        /// 1. A concrete implementation of `CoreDataEntityRegistrar`.
        /// 2. No pre-existing records saved in db.
        let context = container.viewContext
        let id = UUID()
        let recordProvider = MockManagedObjectProvider(context: context, id: id)
        
        /// When
        ///
        /// We call the `insert` method.
        _ = try recordProvider.insert(save: false)
        
        /// Then
        ///
        /// 1. We do not throw.
        /// 2. A record exists in the db.
        let fetchRequest: NSFetchRequest<MockManagedObject> = .init(entityName: "MockManagedObject")
        fetchRequest.predicate = NSPredicate(format: "identifier == %@", id as CVarArg)
        let count = try context.count(for: fetchRequest)
        XCTAssertTrue(count == 1)
    }
    
    func testInsertWithPreExistingRecord() throws {
        /// Given
        ///
        /// 1. A concrete implementation of `CoreDataEntityRegistrar`.
        /// 2. A pre-existing record saved in db.
        let context = container.viewContext
        let id = UUID()
        let recordProvider = MockManagedObjectProvider(context: context, id: id)
        
        let record = MockManagedObject(context: context)
        record.identifier = id
        try context.save()
        
        /// When
        ///
        /// We call the `insert` method.
        do {
            let result = try recordProvider.insert(save: false)
            XCTFail("Expected throw. Found: \(result)")
        } catch CoreDataEntityError.alreadyExists(let objectID) {
            /// Then
            ///
            /// The method should throw.
            XCTAssertEqual(record.objectID, objectID)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
