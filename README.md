# SwiftyCoreData

SwiftyCoreData is a Swift package that simplifies working with CoreData in your iOS and macOS applications. It provides a convenient wrapper around Core Data operations and includes features like automatic schema generation and a generic repository pattern.

## Requirements
- iOS 13.0+
- macOS 10.13+
- Swift 5.7 or later

## Features

- Easy setup with automatic schema generation
- Generic EntityRepository for common CRUD operations
- Combine integration for reactive data updates
- Support for custom predicates and sort descriptors

## Installation

Add the following dependency to your Package.swift file:

```swift
dependencies: [
    .package(url: "https://github.com/YevhenBiiak/SwiftyCoreData.git", from: "1.0.0")
]
```

## Usage

### Setup with model file

If you have an existing .xcdatamodeld file:

```swift
import SwiftyCoreData

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    CoreDataStack.shared.configureModel(name: "my_model")
}
```

### Setup manually

For manual setup without a model file:

```swift
import SwiftyCoreData

@objc(EntityType)
enum EntityType: Int {
    case typeA
    case typeB
}

@objc(YourEntity)
class YourEntity: NSManagedObject, Identifiable {
    @NSManaged var id: UUID
    @NSManaged var type: EntityType
    @NSManaged var createdAt: Date
}

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    CoreDataStack.shared.configureModel(entities: [YourEntity.self])
}
```

### Using EntityRepository

Create a repository for your entity:

```swift
struct YourModel, Identifiable {
    var id: UUID
    var type: EntityType
    var createdAt: Date
}

class YourEntityRepository: EntityRepository<YourEntity, YourModel> {
    override var sortDescriptor: CDSortDescriptor<YourEntity>? {
        .init(\.date, ascending: false)
    }

    override func mapToModel(from entity: YourEntity) -> YourModel? {
        YourModel(id: entity.id, type: entity.type, createdAt: entity.createdAt)
    }
    
    override func mapFromModel(_ model: YourModel, toEntity entity: YourEntity) {
        entity.id = model.id
        entity.type = model.type
        entity.createdAt = model.createdAt
    }
}

let repository = YourEntityRepository(coreData: .shared)

// Get items
repository.items

// Add item
let newItem = YourModel(id: UUID(), type: .typeA, createdAt: Date())
repository.addItem(newItem)

// Update item
repository.updateItemBy(id: newItem.id) { entity in
    entity.type = .typeB
}

// Delete item
repository.deleteItemBy(id: newItem.id)
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.
