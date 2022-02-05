//
//  PersistenceService.swift
//  Shared
//
//  Created by Joshua Homann on 5/22/21.
//

import CoreData
import Combine

actor PersistenceService: PersistenceServiceProtocol {
  @discardableResult
  func create(timeStamp: Date) async throws -> Item {
    let newItem = ManagedItem(context: backgroundContext)
    newItem.timeStamp = .init()
    try backgroundContext.save()
    return .init(from: newItem)
  }

  func delete(id: Date) async throws {
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: ManagedItem.description())
    let sort = NSSortDescriptor(key: "timeStamp", ascending: false)
    request.sortDescriptors = [sort]
    request.predicate = NSPredicate(format: "timeStamp = %@", id as NSDate)
    guard let toDelete = try backgroundContext.fetch(request).first as? NSManagedObject else { return }
    backgroundContext.delete(toDelete)
    try backgroundContext.save()
  }
  
  func watchedItems(for: Item.Query) async -> WatchedItems {
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: ManagedItem.description())
    let sort = NSSortDescriptor(key: "timeStamp", ascending: false)
    request.sortDescriptors = [sort]
    return WatchedCoreDataItems(fetchRequest: request, context: backgroundContext)
  }
  
  // MARK: - Instance
  private let backgroundContext: NSManagedObjectContext
  
  init() {
    let container = NSPersistentContainer(name: "DatabaseFacade")
    backgroundContext = container.newBackgroundContext()
    container.loadPersistentStores(completionHandler: { (storeDescription, error) in
      if let error = error as NSError? {
        fatalError("Unresolved error \(error), \(error.userInfo)")
      }
    })
  }
}

// MARK: - CoreData Initializer
private extension Item {
  init(from managedItem: ManagedItem) {
    timeStamp = managedItem.timeStamp ?? Date()
  }
}

// MARK: - WatchedCoreDataItems
extension ManagedItem: ValueTypeConvertable {
  func valueType() throws -> Item {
    Item(from: self)
  }
}
typealias WatchedCoreDataItems = WatchedCoreDataValues<Item, ManagedItem>
extension WatchedCoreDataItems: WatchedItems {}
