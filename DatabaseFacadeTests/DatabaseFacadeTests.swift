//
//  DatabaseFacadeTests.swift
//  DatabaseFacadeTests
//
//  Created by Ray Fix on 2/12/22.
//

import XCTest
@testable import DatabaseFacade

class DatabaseFacadeTests: XCTestCase {

  override func setUp() async throws {
  }
  
  override func tearDown() async throws {
    try await PersistenceService(inMemory: true).destroy()
  }
  
  func testCreate() async throws {
    let service = PersistenceService(inMemory: true)
    try await service.create(timeStamp: .now)
  }
  
  func testDelete() async throws {
    let service = PersistenceService(inMemory: true)
    let time = Date.now
    try await service.create(timeStamp: time)
    try await service.delete(id: time)
  }


}
