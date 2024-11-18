//
//  FetchedResultPublisher.swift
//  SwiftyCoreData
//
//  Created by Yevhen Biiak on 18.11.2024.
//

import Foundation
import Combine
import CoreData


public struct CDPredicate<Root> {
    fileprivate var nsPredicate: NSPredicate
    public init?<Value>(_ keyPath: KeyPath<Root, Value>, equal value: Value) {
        if let nsObject = value as? NSObject {
            self.nsPredicate = NSPredicate(format: "%K == %@", NSExpression(forKeyPath: keyPath).keyPath, nsObject)
        } else {
            return nil
        }
    }
    public init(_ nsPredicate: NSPredicate) {
        self.nsPredicate = nsPredicate
    }
}

public struct CDSortDescriptor<Root: NSObject> {
    fileprivate var nsSortDescriptor: NSSortDescriptor
    public init<Value>(_ keyPath: KeyPath<Root, Value> & Sendable, ascending: Bool) {
        nsSortDescriptor = NSSortDescriptor(keyPath: keyPath, ascending: ascending)
    }
}

extension CoreDataStack {
    public func publisher<T: NSFetchRequestResult>(for type: T.Type, predicate: CDPredicate<T>? = nil, sortBy sortDescriptor: CDSortDescriptor<T>? = nil) -> AnyPublisher<[T], Never> {
        let request = NSFetchRequest<T>(entityName: String(describing: T.self))
        request.predicate = predicate?.nsPredicate
        if let sortDescriptor {
            request.sortDescriptors = [sortDescriptor.nsSortDescriptor]
        }
        return FetchedResultsPublisher(request: request, context: viewContext).replaceError(with: []).eraseToAnyPublisher()
    }
    
    public func publisher<T: NSFetchRequestResult, Value>(for type: T.Type, predicate: CDPredicate<T>? = nil, sortBy keyPath: KeyPath<T, Value> & Sendable) -> AnyPublisher<[T], Never> {
        let request = NSFetchRequest<T>(entityName: String(describing: T.self))
        request.predicate = predicate?.nsPredicate
        request.sortDescriptors = [NSSortDescriptor(keyPath: keyPath, ascending: true)]
        return FetchedResultsPublisher(request: request, context: viewContext).replaceError(with: []).eraseToAnyPublisher()
    }
    
    // public func publisher<T: NSFetchRequestResult>(for type: T.Type) -> AnyPublisher<[T], Never> {
    //     let request = NSFetchRequest<T>(entityName: String(describing: T.self))
    //     return FetchedResultsPublisher(request: request, context: viewContext).replaceError(with: []).eraseToAnyPublisher()
    // }
}

public final class FetchedResultsPublisher<ResultType: NSFetchRequestResult>: Publisher {
    
    public typealias Output = [ResultType]
    public typealias Failure = NSError
    
    let request: NSFetchRequest<ResultType>
    let context: NSManagedObjectContext
    
    public init(request: NSFetchRequest<ResultType>, context: NSManagedObjectContext) {
        self.request = request
        self.context = context
    }
    
    public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Failure, S.Input == Output {
        subscriber.receive(subscription: FetchedResultsSubscription(
            subscriber: subscriber,
            request: request,
            context: context
        ))
    }
}


private final class FetchedResultsSubscription<SubscriberType, ResultType>: NSObject, Subscription, NSFetchedResultsControllerDelegate where
    SubscriberType: Subscriber,
    SubscriberType.Input == [ResultType],
    SubscriberType.Failure == NSError,
    ResultType: NSFetchRequestResult {
    
    private(set) var subscriber: SubscriberType?
    private(set) var request: NSFetchRequest<ResultType>?
    private(set) var context: NSManagedObjectContext?
    private(set) var controller: NSFetchedResultsController<ResultType>?
    
    init(subscriber: SubscriberType, request: NSFetchRequest<ResultType>, context: NSManagedObjectContext) {
        self.subscriber = subscriber
        self.request = request
        self.context = context
    }
    
    // MARK: Subscription
    
    func request(_ demand: Subscribers.Demand) {
        guard demand > 0,
              let subscriber = subscriber,
              let request = request,
              let context = context else { return }
        
        if request.sortDescriptors == nil { request.sortDescriptors = [] }
        
        controller = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        controller?.delegate = self
        
        do {
            try controller?.performFetch()
            if let fetchedObjects = controller?.fetchedObjects {
                _ = subscriber.receive(fetchedObjects)
            }
        } catch {
            subscriber.receive(completion: .failure(error as NSError))
        }
    }
    
    // MARK: Cancellable
    
    func cancel() {
        subscriber = nil
        controller = nil
        request = nil
        context = nil
    }
    
    // MARK: NSFetchedResultsControllerDelegate
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        guard let subscriber, controller == self.controller else { return }
        
        if let fetchedObjects = self.controller?.fetchedObjects {
            _ = subscriber.receive(fetchedObjects)
        }
    }
}
