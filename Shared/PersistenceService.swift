//
//  PersistenceService.swift
//  Shared
//
//  Created by Joshua Homann on 5/22/21.
//

import CoreData
import Combine

extension NSManagedObjectContext {
  func makeScratchContext() -> NSManagedObjectContext {
    let scratch = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    scratch.persistentStoreCoordinator = self.persistentStoreCoordinator
    return scratch
  }
}

actor PersistenceService: PersistenceServiceProtocol {
  
  private var watcherItems: [UUID: WatchedCoreDataItems] = [:]
  private func removeWatcherItem(id: UUID) {
    self.watcherItems.removeValue(forKey: id)
  }
  
  @discardableResult
  func create(timeStamp: Date) async throws -> Item {
    let context = backgroundContext.makeScratchContext()
    return try await context.perform {
      let newItem = ManagedItem(context: context)
      newItem.timeStamp = .init()
      try context.save()
      return .init(from: newItem)
    }
  }

  func delete(id: Date) async throws {
    let context = backgroundContext
    try await context.perform{
      let request = NSFetchRequest<NSFetchRequestResult>(entityName: ManagedItem.description())
      let sort = NSSortDescriptor(key: "timeStamp", ascending: false)
      request.sortDescriptors = [sort]
      request.predicate = NSPredicate(format: "timeStamp = %@", id as NSDate)
      guard let toDelete = try context.fetch(request).first as? NSManagedObject else { return }
      context.delete(toDelete)
      try context.save()
    }
  }
  
  func publisher(for: Item.Query) async -> AnyPublisher<[Item], Never> {
    let request = ManagedItem.fetchRequest()
    let sort = NSSortDescriptor(key: "timeStamp", ascending: false)
    request.sortDescriptors = [sort]
    let watcher = WatchedCoreDataItems(fetchRequest: request, context: backgroundContext)
    let id = UUID()
    watcherItems[id] = watcher
    return watcher.publisher
      .handleEvents(receiveCancel: { [weak self] in
        Task { [weak self] in
          await self?.removeWatcherItem(id: id)
        }
      })
      .eraseToAnyPublisher()
  }
  
  func destroy() async throws {
    let context = backgroundContext
    try await context.perform {
      let request = ManagedItem.fetchRequest()
      let results = try context.fetch(request)
      for item in results {
        context.delete(item)
      }
      try context.save()
    }
  }

  // MARK: - Instance
  private let backgroundContext: NSManagedObjectContext
  
  init(inMemory: Bool) {
    let container = inMemory ? inMemoryContainer : productionContainer
    backgroundContext = container.newBackgroundContext()
    backgroundContext.automaticallyMergesChangesFromParent = true
  }
}

let inMemoryContainer: NSPersistentContainer = {
  let container = NSPersistentContainer(name: "DatabaseFacade")
  container.persistentStoreDescriptions[0].url = URL(fileURLWithPath: "/dev/null")
  container.loadPersistentStores{ (storeDescription, error) in
    if let error = error as NSError? {
      fatalError("Unresolved error \(error), \(error.userInfo)")
    }
  }
  return container
}()
   
let productionContainer: NSPersistentContainer = {
  let container = NSPersistentContainer(name: "DatabaseFacade")
  container.loadPersistentStores{ (storeDescription, error) in
    if let error = error as NSError? {
      fatalError("Unresolved error \(error), \(error.userInfo)")
    }
  }
  return container
}()
                                 
                                 

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
