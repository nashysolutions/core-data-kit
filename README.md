# CoreDataKit

A lightweight Swift protocol for managing essential metadata of Core Data entities. This provides a standardised way to ensure entities are uniquely identifiable and include required metadata, such as creation timestamps.

## Features
	•	Ensures entities have a unique identifier.
	•	Provides a structured approach for loading and creating database records.
	•	Applies essential metadata when a new entity is created.
	•	Keeps concerns separate from business logic.
	•	Prevents duplicate record creation.

## Installation

### Swift Package Manager (SPM)

Add the package to your Package.swift:

```swift
dependencies: [
    .package(url: "https://github.com/nashysolutions/CoreDataKit.git", from: "1.0.0")
]
```

## Usage

To conform to CoreDataKit, define an entity registrar for your Core Data model:

```swift
import CoreData

struct ChatEntityRegistrar: CoreDataEntityRegistrar {
    let context: NSManagedObjectContext
    let id: UUID

    func load() throws -> Chat? {
        let request = Chat.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try context.fetch(request).first
    }

    // only fires for new records
    func applyInitialMetadata(_ entity: Chat) {
        entity.created = Date()
    }
}
```

### Creating an Entity if It Does Not Exist

```swift
do {
    let registrar = ChatEntityRegistrar(context: context, id: UUID())
    try registrar.create()
} catch {
    print("Failed to create entity: \(error)")
}
```

### Ensuring an Entity Exists

```swift
do {
    let registrar = ChatEntityRegistrar(context: context, id: someUUID)
    // let chat: Chat? = try registrar.load()
    let chat: Chat = try registrar.require() // elimates optional, but throws 'not found error' if not in db
    print("Chat exists:", chat)
} catch {
    print("Entity not found:", error)
}
```

### Error Handling

The protocol uses CoreDataEntityRegistrarError to standardise error cases:

```swift
enum CoreDataEntityRegistrarError: Error {
    case alreadyExists
    case notFound
    case unexpectedError(Error)
}
```

### Retro-Active Modelling

You may want to add the following to your project, if your attribute naming for `identifier` is consistent.

```swift
extension IdentifiableEntity {

    static var identifierAttributeName: String {
        return "identifier"
    }
}

extension CoreDataEntityRegistrar where T.ID == UUID {

    func load() throws(CoreDataEntityRegistrarError) -> T? {
        
        let fetchRequest = T.fetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "%K == %@", T.identifierAttributeName, id as CVarArg)

        do {
            let results = try context.fetch(fetchRequest) as? [Self.T]
            return results?.first
        } catch {
            throw CoreDataEntityRegistrarError.unexpectedError(error)
        }
    }
}

// Your concrete implementations will be more concise
struct ChatEntityRegistrar: CoreDataEntityRegistrar {

    let context: NSManagedObjectContext
    let id: UUID

    func applyInitialMetadata(_ entity: Chat) {
        entity.created = Date()
    }
}
```
