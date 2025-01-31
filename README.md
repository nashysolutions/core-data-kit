# CoreDataKit

![Swift](https://img.shields.io/badge/Swift-6.0-orange?logo=swift) ![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20visionOS%20%7C%20tvOS%20%7C%20watchOS-blue?logo=apple)

A lightweight wrapper for managing essential metadata of Core Data entities. This provides a standardised way to ensure entities are uniquely identifiable and include required metadata, such as creation timestamps.

## Features
- Ensures entities have a unique identifier.
- Provides a structured approach for loading and creating database records.
- Applies essential metadata when a new entity is created.
- Keeps concerns separate from business logic.
- Prevents duplicate record creation.

## Installation

### Swift Package Manager (SPM)

Add the package to your Package.swift:

```swift
import PackageDescription

let package = Package(
    dependencies: [
        .package(url: "git@github.com:nashysolutions/core-data-kit.git", .upToNextMinor(from: "2.0.0")),
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

## Usage

To conform to CoreDataKit, define an entity that conforms to `IdentifiableEntity` and define a registrar for your Core Data model:

```swift
import CoreData

class Chat: NSManagedObject, IdentifiableEntity {

   var id: UUID {
       get { return self.identifier }
       set { self.identifier = newValue }
   }
   
   @NSManaged var identifier: UUID
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

### Query by primary key (someUUID)

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

do {
    let registrar = ChatEntityRegistrar(context: context, id: someUUID)
    let chat: Chat = try registrar.queryOrInsert()
    print("Chat already existed or was created:", chat)
    if context.hasChanges {
        try context.save()
    }
}
} catch {
    //
}
```

### Inserting

```swift
do {
    let registrar = ChatEntityRegistrar(context: context, id: UUID())
    try registrar.insert()
    try context.save()
} catch CoreDataEntityError.alreadyExists(let objectID) {
    //
} catch {
    print("Failed to create entity: \(error)")
}
```

### Error Handling

The protocol uses CoreDataEntityRegistrarError to standardise error cases:

```swift
enum CoreDataEntityRegistrarError: Error {
    case alreadyExists
    case notFound
}
```
