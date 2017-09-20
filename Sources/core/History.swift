//
//  HistoryItem.swift
//  SQLiteMIVRKit-macOS
//
//  Created by Shane Whitehead on 19/9/17.
//  Copyright © 2017 SQLiteMIVRKit. All rights reserved.
//

import Foundation
import MIVRKit
import SQLite
import KZSimpleLogger

class HistoryTable {
	
	let table = Table("HistoryEntries")
	
	let keyColumn = Expression<Int64>("key")
  let groupIDColumn = Expression<String>("groupID")
	let guidColumn = Expression<String>("guid")
	let ignoredColumn = Expression<Bool>("isgnored")
	let scoreColumn = Expression<Int>("score")

	func create(using connection: Connection) throws {
		try connection.run(table.create(ifNotExists: true) { (table) in
			table.column(keyColumn, primaryKey: .autoincrement)
			table.column(guidColumn, unique: true)
			table.column(ignoredColumn)
			table.column(scoreColumn)
      table.column(groupIDColumn)
		})
	}
	
  func insert(groupID: String, guid: String, ignored: Bool, score: Int, using db: Connection) throws -> HistoryItem {
		var rowID: Int64? = nil
		try db.transaction {
			log(debug: "Insert history entry")
			rowID = try db.run(self.table.insert(
				self.guidColumn <- guid,
				self.ignoredColumn <- ignored,
				self.scoreColumn <- score,
        self.groupIDColumn <- groupID))
			log(debug: "Inserted with \(String(describing: rowID))")
		}
		guard let id = rowID else {
			throw SQLDataStoreError.invalidRowID
		}
		let filter = self.table.filter(self.keyColumn == id)
		guard let value = try select(using: db, filteredUsing: filter).first else {
			throw SQLDataStoreError.couldNotFindHistoryAfterInsert
		}
		return value
	}
	
	func delete(using db: Connection, entries: HistoryItem...) throws {
		try delete(using: db, entries: entries)
	}
	
	func delete(using db: Connection, entries: [HistoryItem]) throws {
		try db.transaction {
			for entry in entries {
				guard let guide = entry as? SQLHistoryItem else {
					throw SQLDataStoreError.invalidHistoryImplementation(element: entry)
				}
				let filter = self.table.filter(self.keyColumn == guide.key)
				guard try db.run(filter.delete()) == 0 else {
					continue
				}
				throw SQLDataStoreError.couldNotDeleteHistory(element: guide)
			}
		}
	}
	
	func select(using db: Connection, filteredByGUID filter: String) throws -> [HistoryItem] {
		let tableFilter = self.table.filter(self.guidColumn == filter)
		return try select(using: db, filteredUsing: tableFilter)
	}

	func select(using db: Connection, filteredByGroupID filter: String) throws -> [HistoryItem] {
		let tableFilter = self.table.filter(self.groupIDColumn == filter)
		return try select(using: db, filteredUsing: tableFilter)
	}

	func select(using db: Connection, filteredUsing filter: Table) throws -> [HistoryItem] {
		var entries: [HistoryItem] = []
		for entry in try db.prepare(filter) {
			entries.append(
				SQLHistoryItem(
					key: entry[keyColumn],
          groupID: entry[groupIDColumn],
					guid: entry[guidColumn],
					ignored: entry[ignoredColumn],
					score: entry[scoreColumn])
			)
		}
		return entries
	}
	
	func select(using db: Connection) throws -> [HistoryItem] {
		return try select(using: db, filteredUsing: table)
	}
	
	func update(using db: Connection, entries: HistoryItem...) throws {
		try update(using: db, entries: entries)
	}
	
	func update(using db: Connection, entries: [HistoryItem]) throws {
		try db.transaction {
			for entry in entries {
				guard let mutabled = entry as? SQLHistoryItem else {
					throw SQLDataStoreError.invalidHistoryImplementation(element: entry)
				}
				log(debug: "Updating history entry with key \(mutabled.key)")
				let filter = self.table.filter(self.keyColumn == mutabled.key)
				let parameters = [
					self.ignoredColumn <- entry.isIgnored,
					self.guidColumn <- entry.guid,
					self.scoreColumn <- entry.score,
          self.groupIDColumn <- entry.groupID
				]
				guard try db.run(filter.update(parameters)) == 0 else {
					continue
				}
				throw SQLDataStoreError.couldNotUpdateHistory(element: entry)
			}
		}
	}
	
}

class SQLHistoryItem: HistoryItem {
  
	
	var key: Int64
  var groupID: String
	var guid: String
	var isIgnored: Bool
	var score: Int
	
  init(key: Int64, groupID: String, guid: String, ignored: Bool, score: Int) {
		self.key = key
    self.groupID = groupID
		self.guid = guid
		self.isIgnored = ignored
		self.score = score
	}
	
}


