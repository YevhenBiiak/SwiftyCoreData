//
//  CoreDataStack.swift
//  SwiftyCoreData
//
//  Created by Yevhen Biiak on 18.11.2024.
//

import CoreData


public final class CoreDataStack {
    
    public static let shared = CoreDataStack()
    
    private var coordinator: NSPersistentStoreCoordinator?
    private var store: NSPersistentStore?
    
    private let name: String
    private let storeURL: URL
    
    internal let viewContext: NSManagedObjectContext
    
    
    public init(sqliteFileName: String = "store", specifiedURL: URL? = nil) {
        let coreDataFolder = specifiedURL ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("core_data")
        
        do {
            if !FileManager.default.fileExists(atPath: coreDataFolder.path) {
                try FileManager.default.createDirectory(at: coreDataFolder, withIntermediateDirectories: true)
            }
        } catch {
            print(error)
        }
        
        self.name = sqliteFileName
        self.storeURL = coreDataFolder.appendingPathComponent("\(sqliteFileName).sqlite")
        self.viewContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    }
    
    deinit {
        do {
            // save context if hasChanges
            if viewContext.hasChanges {
                try viewContext.save()
            }
            // close store access
            if let store {
                try store.persistentStoreCoordinator?.remove(store)
            }
        } catch {
            print(error)
        }
    }
    
    public func saveContext() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                let nserror = error as NSError
                print("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    public func fetch<T: NSManagedObject>(_ type: T.Type) -> [T] {
        do {
            let request = NSFetchRequest<T>(entityName: String(describing: T.self))
            return try viewContext.fetch(request)
        } catch {
            print("Fetch failed: \(error.localizedDescription)")
            return []
        }
    }
    
    public func fetch<T: NSManagedObject>(_ type: T.Type, where filter: (T) -> Bool) -> [T] {
        return self.fetch(type).filter(filter)
    }
    
    public func create<T: NSManagedObject>(_ type: T.Type) -> T {
        return T(context: viewContext)
    }
    
    public func delete<T: NSManagedObject>(_ object: T) {
        viewContext.delete(object)
    }
    
    public func configureModel(name: String) {
        
        ValueTransformer.setValueTransformer(ArrayTransformer(), forName: NSValueTransformerName(String(describing: ArrayTransformer.self)))
        
        let model = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: name, withExtension: "momd")!)!
        
        coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        viewContext.persistentStoreCoordinator = coordinator
        
        // Open the persistent store, which must be compatible with the given object model.
        do {
            store = try coordinator!.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL)
        } catch {
            print(error)
        }
    }
    
    public func configureModel(entities: [NSManagedObject.Type]) {
        
        ValueTransformer.setValueTransformer(ArrayTransformer(), forName: NSValueTransformerName(String(describing: ArrayTransformer.self)))
        
        let entityDescriptions = entities.map { $0.entityDescription }
        
        let model = NSManagedObjectModel()
        model.entities = entityDescriptions
        
        coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        viewContext.persistentStoreCoordinator = coordinator
        
        // Open the persistent store, which must be compatible with the given object model.
        do {
            store = try coordinator!.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL)
        } catch {
            print(error)
        }
    }
}
