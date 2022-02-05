//
//  PersistenceServiceProtocol.swift
//  DatabaseFacade
//
//  Created by Joshua Homann on 5/22/21.
//

import Combine
import Foundation

protocol WatchedItems: AnyObject {
  var publisher: AnyPublisher<[Item], Never> { get }
}

protocol PersistenceServiceProtocol {
  @discardableResult
  func create(timeStamp: Date) async throws -> Item
  func delete(id: Date) async throws
  func watchedItems(for: Item.Query) async -> WatchedItems
}

struct Item: Hashable, Identifiable {
  var id: Date { timeStamp }
  var timeStamp: Date
}

extension Item {
  enum Query {
    case all
  }
}
