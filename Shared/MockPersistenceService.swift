//
//  MockPersistenceService.swift
//  DatabaseFacade
//
//  Created by Joshua Homann on 5/22/21.
//

import Combine
import Foundation


actor MockPersistenceService: PersistenceServiceProtocol {
  @Published var items: [Item] = (0..<10).map { Item(timeStamp: Date.distantFuture + TimeInterval($0)) }
  @discardableResult
  func create(timeStamp: Date) async throws -> Item {
    let item = Item(timeStamp: timeStamp)
    items.append(item)
    return item
  }
  func delete(id: Date) async throws {
    guard let index = items.firstIndex(where: { $0.timeStamp == id }) else { return }
    items.remove(at: index)
  }
  
  func items(for: Item.Query) async -> [Item] {
    items
  }
  
  func publisher(for: Item.Query) async -> AnyPublisher<[Item], Never> {
    $items.eraseToAnyPublisher()
  }
}
