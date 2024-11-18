//
//  EntityRepository.swift
//  SwiftyCoreData
//
//  Created by Yevhen Biiak on 18.11.2024.
//

import Foundation
import CoreData
import Combine


open class EntityRepository<Entity, Model>: ObservableObject where Entity: NSManagedObject & Identifiable, Model: Identifiable, Entity.ID == Model.ID {
    
    @Published public var items: [Model] = []
    
    public let coreData: CoreDataStack
    
    open var predicate: CDPredicate<Entity>? { nil }
    open var sortDescriptor: CDSortDescriptor<Entity>? { nil }
    
    private var cancellable: AnyCancellable?
    
    public init(coreData: CoreDataStack) {
        self.coreData = coreData
        
        self.cancellable = coreData.publisher(for: Entity.self, predicate: predicate, sortBy: sortDescriptor).sink { [weak self] in
            self?.items = $0.compactMap { self?.mapToModel(from: $0) }
        }
    }
    
    public func itemBy(id: Model.ID) -> Model? {
        return items.first { $0.id == id }
    }
    
    public func addItem(_ item: Model) {
        let entity = coreData.create(Entity.self)
        mapFromModel(item, toEntity: entity)
        coreData.saveContext()
    }
    
    public func updateItemBy(id: Model.ID, _ setter: (Entity) -> Void) {
        coreData.fetch(Entity.self, where: { $0.id == id }).forEach {
            setter($0)
        }
        coreData.saveContext()
    }
    
    public func deleteItemBy(id: Model.ID) {
        coreData.fetch(Entity.self, where: { $0.id == id }).forEach {
            coreData.delete($0)
        }
        coreData.saveContext()
    }
    
    /// Maps entity to model.
    /// - Returns: The model
    ///
    /// - Parameters:
    ///   - entity: The entity
    ///
    ///# Example #
    /// ```
    /// override func mapToModel(from entity: Entity) -> Model? {
    ///     Model(
    ///         id: entity.id,
    ///         date: entity.date,
    ///         notes: entity.notes
    ///     )
    /// }
    /// ```
    open func mapToModel(from entity: Entity) -> Model? {
        print("\(String(describing: EntityRepository.self)): 'mapToModel(from:)' returns nil. Please override 'mapToModel(from:)' to provide logic for mapping entity to model.")
        return nil
    }
    
    /// Updates entity with model.
    ///
    /// - Parameters:
    ///   - model: The model
    ///   - entity: The entity to update
    ///
    ///# Example #
    /// ```
    /// override func mapFromModel(_ model: Model, toEntity entity: Entity) {
    ///     entity.id = model.id
    ///     entity.date = model.date
    ///     entity.notes = model.notes
    /// }
    open func mapFromModel(_ model: Model, toEntity entity: Entity) {
        print("\(String(describing: EntityRepository.self)): 'mapFromModel(_:toEntity:)' skipping entity update. Please override 'mapFromModel(_:toEntity:)' to provide logic for updating entity with model.")
    }
}
