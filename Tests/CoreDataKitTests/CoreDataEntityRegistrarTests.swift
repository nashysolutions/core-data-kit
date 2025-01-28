//
//  CoreDataEntityRegistrarTests.swift
//  persistence
//
//  Created by Robert Nash on 03/01/2025.
//

import Foundation
import XCTest
import CoreData

@testable import CoreDataKit

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
    
    func testCreateRecordSuccessfully() throws {
        /// Given
        ///
        /// A MockManagedObjectProvider and an empty database.
        let context = container.viewContext
        let id = UUID()
        let recordProvider = MockManagedObjectProvider(context: context, id: id)
        
        /// When
        ///
        /// Call the `create` method.
        try recordProvider.create()
        
        /// Then
        ///
        /// A new record with the given identifier should exist in the database.
        let fetchRequest: NSFetchRequest<MockManagedObject> = .init(entityName: "MockManagedObject")
        fetchRequest.predicate = NSPredicate(format: "identifier == %@", id as CVarArg)
        let result = try context.fetch(fetchRequest)
        
        XCTAssertEqual(result.count, 1, "Expected exactly one record but found \(result.count).")
        XCTAssertEqual(result.first?.identifier, id, "The created record does not have the expected identifier.")
    }
    
    func testCreateRecordFailsWhenRecordAlreadyExists() throws {
        /// Given
        ///
        /// A MockManagedObjectProvider and a pre-existing record with the same identifier.
        let context = container.viewContext
        let id = UUID()
        
        let existingRecord = MockManagedObject(context: context)
        existingRecord.identifier = id
        try context.save()
        
        let recordProvider = MockManagedObjectProvider(context: context, id: id)
        
        /// When
        ///
        /// Call the `create` method.
        do {
            try recordProvider.create()
            XCTFail("Expected create() to throw an error, but it did not.")
        } catch CoreDataEntityRegistrarError.alreadyExists {
            /// Then
            ///
            /// The method should throw a `CoreDataEntityRegistrarError.alreadyExists` error.
        } catch {
            XCTFail("Unexpected error thrown: \(error).")
        }
    }
    
    func testCreateRecordHandlesUnexpectedFetchError() throws {
        
        /// Given
        ///
        /// A MockManagedObjectProvider and a mock error during fetch.
        let context = MockNSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = container.persistentStoreCoordinator
        /// Configure so that an error will occur when fetching is performed
        context.simulateFetchError(MockError.fetchFailed)
        
        let id = UUID()
        let recordProvider = MockManagedObjectProvider(context: context, id: id)
        
        /// When
        ///
        /// Call the `create` method, which performs a fetch to verify the record
        /// doesn't already exist.
        do {
            try recordProvider.create()
            XCTFail("Expected create() to throw an error, but it did not.")
        } catch CoreDataEntityRegistrarError.unexpectedError(let error) {
            /// Then
            ///
            /// The method should throw an `unexpectedError` containing the underlying fetch error.
            XCTAssertEqual(error as? MockError, MockError.fetchFailed, "Unexpected error type: \(error).")
        } catch {
            XCTFail("Unexpected error thrown: \(error).")
        }
    }
    
    func testLoadReturnsWhenFound() throws {
        /// Given
        ///
        /// A MockManagedObjectProvider with a pre-existing entity.
        let context = container.viewContext
        let id = UUID()
        
        let record = MockManagedObject(context: context)
        record.identifier = id
        try context.save()
        
        let recordProvider = MockManagedObjectProvider(context: context, id: id)
        
        /// When
        ///
        /// Call the `load` method.
        let result = try recordProvider.load()
        
        /// Then
        ///
        /// The method should return the existing record.
        XCTAssertNotNil(result, "Expected to find a record but got nil.")
        XCTAssertEqual(result?.identifier, id, "Loaded record does not have the expected identifier.")
    }
    
    func testLoadReturnsNilWhenRecordNotFound() throws {
        /// Given
        ///
        /// A MockManagedObjectProvider with no matching entity in the database.
        let context = container.viewContext
        let recordProvider = MockManagedObjectProvider(context: context, id: UUID())
        
        /// When
        ///
        /// Call the `load` method.
        let result = try recordProvider.load()
        
        /// Then
        ///
        /// The method should return nil.
        XCTAssertNil(result, "Expected nil but found a record.")
    }
    
    func testRequireThrowsWhenRecordNotFound() throws {
        /// Given
        ///
        /// A MockManagedObjectProvider with no matching entity in the database.
        let context = container.viewContext
        let recordProvider = MockManagedObjectProvider(context: context, id: UUID())
        
        /// When
        ///
        /// Call the `require` method.
        do {
            _ = try recordProvider.require()
            XCTFail("Expected require() to throw an error, but it did not.")
        } catch CoreDataEntityRegistrarError.notFound {
            /// Then
            ///
            /// The method should throw the `notFound` error.
        } catch {
            XCTFail("Unexpected error thrown: \(error).")
        }
    }
    
    func testRequireReturnsRecordWhenFound() throws {
        /// Given
        ///
        /// A MockManagedObjectProvider with a pre-existing entity.
        let context = container.viewContext
        let id = UUID()
        
        let record = MockManagedObject(context: context)
        record.identifier = id
        try context.save()
        
        let recordProvider = MockManagedObjectProvider(context: context, id: id)
        
        /// When
        ///
        /// Call the `require` method.
        let result = try recordProvider.require()
        
        /// Then
        ///
        /// The method should return the existing record.
        XCTAssertEqual(result.identifier, id, "Required record does not have the expected identifier.")
    }
}

enum MockError: Error {
    case fetchFailed
}
