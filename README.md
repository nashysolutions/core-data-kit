# CoreDataKit

![Swift](https://img.shields.io/badge/Swift-6.0-orange?logo=swift) ![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20visionOS%20%7C%20tvOS%20%7C%20watchOS-blue?logo=apple)

A lightweight framework that simplifies entity management in Core Data. It provides a structured approach for handling unique identifiers, metadata, and entity loading while keeping concerns separate from business logic.

## Features
- Ensures entities have a unique identifier.
- Provides a structured approach for loading and creating database records.
- Automatically applies essential metadata to new entities.
- Utilises DatabaseQueryResult to provide insight into entity retrieval and creation.
- Keeps concerns separate from business logic.
- Prevents duplicate record creation.

## Installation

### Swift Package Manager (SPM)

Add the package to your Package.swift:

```swift
import PackageDescription

let package = Package(
    dependencies: [
        .package(url: "git@github.com:nashysolutions/core-data-kit.git", .upToNextMinor(from: "4.0.0")),
    ],
    targets: [
        .target(
            dependencies: [
                .product(name: "CoreDataKit", package: "core-data-kit")
            ]
        )
    ]
)
```

---

## Usage

### Defining an Entity

To use CoreDataKit, your entity should conform to IdentifiableEntity, ensuring it has a unique identifier. You should also define a registrar that manages how the entity is loaded and inserted.

```swift
import CoreData

class Chat: NSManagedObject, IdentifiableEntity {

   var id: UUID {
       get { return self.identifier }
       set { self.identifier = newValue }
   }
   
   @NSManaged var identifier: UUID
   @NSManaged var created: Date
   /// etc
}

struct ChatEntityRegistrar: CoreDataEntityRegistrar {

    let context: NSManagedObjectContext
    let id: UUID

    // only fires for new records
    func applyInitialMetadata(_ entity: Chat) {
        entity.created = Date()
    }
}
```

---

## Querying Entities

### Handling DatabaseQueryResult

When executing a query, a result is emitted that describes the outcome of the operation. This enables you to handle different scenarios, such as retrieving an existing entity, inserting a new one, or managing errors. Although you receive a collection of results, the query itself targets a single identifier. In this case, the array will contain a single item for .results(let chats):.

```swift
let query = RegistrarQuery<ChatEntityRegistrar>(identifier: someUUID, context: context)
query.performQuery()

switch query.result {
case .results(let chats): // A collection - compile time guarantee NonEmpty<Chat>.
    // For registrar query, the array will contain 1 object here.
    let first: Chat = chat.first // Not an optional value
    print("Chat exists:", first)
case .performed:
    print("No chat found for this identifier.")
case .failure(let error):
    print("Failed to fetch chat: \(error)")
case .none:
    print("Query not executed yet.")
}
```

Alternatively, you can query using CoreDataEntityRegistrar directly:

```swift
do {
    let registrar = ChatEntityRegistrar(context: context, id: someUUID)
    let chat: Chat = try registrar.query()
    print("Chat exists:", chat)
} catch CoreDataEntityError.notFound {
    print("Entity not found:", error)
} catch {
    //
}
```

---

### Querying or Inserting an Entity

If an entity does not exist, you may want to insert a new record. CoreDataKit allows you to fetch or create an entity in a single step.

```swift
do {
    let registrar = ChatEntityRegistrar(context: context, id: someUUID)
    let chat: Chat = try registrar.queryOrInsert()
    
    print("Chat already existed or was created:", chat)

    if context.hasChanges {
        try context.save()
    }
} catch {
    print("Failed to fetch or insert entity:", error)
}
```

---

### Inserting a New Entity

To explicitly create a new entity, use insert(). If an entity with the same primary key already exists, an error is thrown.

```swift
do {
    let registrar = ChatEntityRegistrar(context: context, id: UUID())
    try registrar.insert(save: true)
} catch CoreDataEntityError.alreadyExists(let objectID) {
    print("Entity already exists with ID:", objectID)
} catch {
    print("Failed to create entity:", error)
}
```
