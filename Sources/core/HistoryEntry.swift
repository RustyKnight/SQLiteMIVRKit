//
//  HistoryEntry.swift
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
	let guidColumn = Expression<String>("guid")
	let ignoredColumn = Expression<Bool>("isgnored")
	let scoreColumn = Expression<Int>("score")
	
	func create(using connection: Connection) throws {
		try connection.run(table.create(ifNotExists: true) { (table) in
			table.column(keyColumn, primaryKey: .autoincrement)
			table.column(guidColumn, unique: true)
			table.column(ignoredColumn)
			table.column(scoreColumn)
		})
	}
	
	public func insert(guid: String, ignored: Bool, score: Int, using db: Connection) throws -> HistoryEntry {
		var rowID: Int64? = nil
		try db.transaction {
			log(debug: "Insert history entry")
			rowID = try db.run(self.table.insert(
				self.guidColumn <- guid,
				self.ignoredColumn <- ignored,
				self.scoreColumn <- score))
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
	
	public func delete(using db: Connection, entries: HistoryEntry...) throws {
		try delete(using: db, entries: entries)
	}
	
	public func delete(using db: Connection, entries: [HistoryEntry]) throws {
		try db.transaction {
			for entry in entries {
				guard let guide = entry as? SQLHistoryEntry else {
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
	
	public func select(using db: Connection, filteredUsing filter: Table) throws -> [HistoryEntry] {
		var entries: [HistoryEntry] = []
		for entry in try db.prepare(filter) {
			entries.append(
				SQLHistoryEntry(
					key: entry[keyColumn],
					guid: entry[guidColumn],
					ignored: entry[ignoredColumn],
					score: entry[scoreColumn])
			)
		}
		return entries
	}
	
	public func select(using db: Connection) throws -> [HistoryEntry] {
		return try select(using: db, filteredUsing: table)
	}
	
	public func update(using db: Connection, entries: HistoryEntry...) throws {
		try update(using: db, entries: entries)
	}
	
	public func update(using db: Connection, entries: [HistoryEntry]) throws {
		try db.transaction {
			for entry in entries {
				guard let mutabled = entry as? SQLHistoryEntry else {
					throw SQLDataStoreError.invalidHistoryImplementation(element: entry)
				}
				log(debug: "Updating history entry with key \(mutabled.key)")
				let filter = self.table.filter(self.keyColumn == mutabled.key)
				let parameters = [
					self.ignoredColumn <- entry.isIgnored,
					self.guidColumn <- entry.guid,
					self.scoreColumn <- entry.score
				]
				guard try db.run(filter.update(parameters)) == 0 else {
					continue
				}
				throw SQLDataStoreError.couldNotUpdateHistory(element: entry)
			}
		}
	}
	
}

public class SQLHistoryEntry: HistoryEntry {
	
	var key: Int64
	public var guid: String
	public var isIgnored: Bool
	public var score: Int
	
	init(key: Int64, guid: String, ignored: Bool, score: Int) {
		self.key = key
		self.guid = guid
		self.isIgnored = ignored
		self.score = score
	}
	
}


