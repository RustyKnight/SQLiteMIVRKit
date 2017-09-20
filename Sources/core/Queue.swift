//
//  QueueItem.swift
//  SQLiteMIVRKit-macOS
//
//  Created by Shane Whitehead on 19/9/17.
//  Copyright © 2017 SQLiteMIVRKit. All rights reserved.
//

import Foundation
import SQLite
import MIVRKit
import KZSimpleLogger

class QueueTable {
	
	let table = Table("QueueEntries")
	
	let keyColumn = Expression<Int64>("key")
	let guidColumn = Expression<String>("guid")
	let idColumn = Expression<String>("id")
	let nameColumn = Expression<String>("name")
	let statusColumn = Expression<Int>("status")
	let scoreColumn = Expression<Int>("score")
  let linkColumn = Expression<String>("link")

	func create(using connection: Connection) throws {
		try connection.run(table.create(ifNotExists: true) { (table) in
			table.column(keyColumn, primaryKey: .autoincrement)
			table.column(guidColumn, unique: true)
			table.column(idColumn)
			table.column(nameColumn)
			table.column(statusColumn)
			table.column(scoreColumn)
      table.column(linkColumn)
		})
	}
	
  public func insert(guid: String, groupID: String, name: String, status: QueueItemStatus, score: Int, link: String, using db: Connection) throws -> QueueItem {
		var rowID: Int64? = nil
		try db.transaction {
			log(debug: "Insert queue entry")
      
      let parameters = [
        self.guidColumn <- guid,
        self.idColumn <- groupID,
        self.nameColumn <- name,
        self.statusColumn <- status.rawValue,
        self.scoreColumn <- score,
        self.linkColumn <- link
      ]
      
			rowID = try db.run(self.table.insert(parameters))
			log(debug: "Inserted with \(String(describing: rowID))")
		}
		guard let id = rowID else {
			throw SQLDataStoreError.invalidRowID
		}
		let filter = self.table.filter(self.keyColumn == id)
		guard let value = try select(using: db, filteredUsing: filter).first else {
			throw SQLDataStoreError.couldNotFindQueueItemAfterInsert
		}
		return value
	}
	
	public func delete(using db: Connection, entries: QueueItem...) throws {
		try delete(using: db, entries: entries)
	}
	
	public func delete(using db: Connection, entries: [QueueItem]) throws {
		try db.transaction {
			for entry in entries {
				guard let guide = entry as? SQLQueueItem else {
					throw SQLDataStoreError.invalidQueueImplementation(element: entry)
				}
				let filter = self.table.filter(self.keyColumn == guide.key)
				guard try db.run(filter.delete()) == 0 else {
					continue
				}
				throw SQLDataStoreError.couldNotDeleteQueueItem(element: guide)
			}
		}
	}
	
	public func select(using db: Connection, filteredUsing filter: Table) throws -> [QueueItem] {
		var entries: [QueueItem] = []
		for entry in try db.prepare(filter) {
			let statusValue = entry[statusColumn]
			guard let status = QueueItemStatus(rawValue: statusValue) else {
				throw SQLDataStoreError.invalidQueueStatus(value: statusValue)
			}
			entries.append(
				SQLQueueItem(
					key: entry[keyColumn],
					guid: entry[guidColumn],
					groupID: entry[idColumn],
					name: entry[nameColumn],
					status: status,
					score: entry[scoreColumn],
          link: entry[linkColumn])
			)
		}
		return entries
	}
	
	public func select(using db: Connection) throws -> [QueueItem] {
		return try select(using: db, filteredUsing: table)
	}
	
	public func update(using db: Connection, entries: QueueItem...) throws {
		try update(using: db, entries: entries)
	}
	
	public func update(using db: Connection, entries: [QueueItem]) throws {
		try db.transaction {
			for entry in entries {
				guard let mutabled = entry as? SQLQueueItem else {
					throw SQLDataStoreError.invalidQueueImplementation(element: entry)
				}
				log(debug: "Updating queue entry with key \(mutabled.key)")
				let filter = self.table.filter(self.keyColumn == mutabled.key)
				let parameters = [
					self.guidColumn <- entry.guid,
					self.idColumn <- entry.groupID,
					self.nameColumn <- entry.name,
					self.statusColumn <- entry.status.rawValue,
					self.scoreColumn <- entry.score,
          self.linkColumn <- entry.link
				]
				guard try db.run(filter.update(parameters)) == 0 else {
					continue
				}
				throw SQLDataStoreError.couldNotUpdateQueueItem(element: entry)
			}
		}
	}
	
}

public class SQLQueueItem: QueueItem {

  var key: Int64
	public var guid: String
	public var groupID: String
	public var name: String
	public var status: QueueItemStatus
	public var score: Int
  public var link: String

  init(key: Int64, guid: String, groupID: String, name: String, status: QueueItemStatus, score: Int, link: String) {
		self.key = key
		self.guid = guid
		self.groupID = groupID
		self.name = name
		self.status = status
		self.score = score
    self.link = link
	}
	
}



