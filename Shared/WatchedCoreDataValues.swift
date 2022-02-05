//
//  WatchedValues.swift
//
//  Created by Ray Fix on 1/20/22.
//

import CoreData
import Combine

// Protocol to let you turn core data types into value types.

protocol ValueTypeConvertable {
  associatedtype ValueType
  func valueType() throws -> ValueType
}

// A private fetched results controller delegate that can publish

private final class FetchEngine<ValueType, CoreDataType>: NSObject, NSFetchedResultsControllerDelegate where CoreDataType: ValueTypeConvertable, CoreDataType.ValueType == ValueType
{
  private let controller: NSFetchedResultsController<NSFetchRequestResult>
  weak var target: WatchedCoreDataValues<ValueType, CoreDataType>?
  
  init(fetchRequest: NSFetchRequest<NSFetchRequestResult>, context: NSManagedObjectContext) {
    controller = NSFetchedResultsController<NSFetchRequestResult>(fetchRequest: fetchRequest,
                                                                  managedObjectContext: context,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
    super.init()
  }
  
  func start(target: WatchedCoreDataValues<ValueType, CoreDataType>) {
    self.target = target
    controller.delegate = self
    try? controller.performFetch()
  }

  private func transform(_ objects: [NSFetchRequestResult]) -> [ValueType] {
    return objects
      .compactMap { $0 as? CoreDataType }
      .compactMap { try? $0.valueType() }
  }
  
  fileprivate
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    guard let objects = controller.fetchedObjects else { return }
    target?.results.send(transform(objects))
  }
  
  func initialValues() -> [ValueType] {
    guard let results = try? controller.managedObjectContext.fetch(controller.fetchRequest) else {
      return []
    }
    return transform(results)
  }
}

final class WatchedCoreDataValues<ValueType, CoreDataType>: ObservableObject
  where CoreDataType: ValueTypeConvertable, CoreDataType.ValueType == ValueType
{
  var publisher: AnyPublisher<[ValueType], Never> {
    return results
      .prepend(fetcher.initialValues())
      .eraseToAnyPublisher()
  }
  
  fileprivate let results = PassthroughSubject<[ValueType], Never>()
  
  private let fetcher: FetchEngine<ValueType, CoreDataType>
  init(fetchRequest: NSFetchRequest<NSFetchRequestResult>, context: NSManagedObjectContext) {
    fetcher = FetchEngine(fetchRequest: fetchRequest, context: context)
    fetcher.start(target: self)
  }
}
