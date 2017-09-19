//
//  GuideEntry.swift
//  SQLiteMIVRKit-macOS
//
//  Created by Shane Whitehead on 19/9/17.
//  Copyright © 2017 SQLiteMIVRKit. All rights reserved.
//

import Foundation
import MIVRKit
import SQLite
import KZSimpleLogger

class GuideTable {

	let table = Table("GuideEntries")
	
	let keyColumn = Expression<Int64>("key")
	let idColumn = Expression<String>("id")
	let nameColumn = Expression<String>("name")
	let typeColumn = Expression<Int>("type")
	let lastGrabColumn = Expression<Date?>("lastGrab")

	func create(using connection: Connection) throws {
		try connection.run(table.create(ifNotExists: true) { (table) in
			table.column(keyColumn, primaryKey: .autoincrement)
			table.column(idColumn, unique: true)
			table.column(nameColumn)
			table.column(typeColumn)
			table.column(lastGrabColumn)
		})
	}

	public func insert(name: String, id: String, type: GuideEntryType, lastGrab: Date? = nil, using db: Connection) throws -> GuideEntry {
		var rowID: Int64? = nil
		try db.transaction {
			log(debug: "Insert guide entry")
			
			let parameters = [
				self.idColumn <- id,
				self.nameColumn <- name,
				self.typeColumn <- type.rawValue,
				self.lastGrabColumn <- lastGrab
			]
			
			rowID = try db.run(self.table.insert(parameters))
			log(debug: "Inserted with \(String(describing: rowID))")
		}
		guard let id = rowID else {
			throw SQLDataStoreError.invalidRowID
		}
		let filter = self.table.filter(self.keyColumn == id)
		guard let value = try select(using: db, filteredUsing: filter).first else {
			throw SQLDataStoreError.couldNotFindGuideAfterInsert
		}
		return value
	}

	public func delete(using db: Connection, entries: GuideEntry...) throws {
		try delete(using: db, entries: entries)
	}

	public func delete(using db: Connection, entries: [GuideEntry]) throws {
		try db.transaction {
			for entry in entries {
				guard let guide = entry as? SQLGuideEntry else {
					throw SQLDataStoreError.invalidGuideImplementation(element: entry)
				}
				let filter = self.table.filter(self.keyColumn == guide.key)
				guard try db.run(filter.delete()) == 0 else {
					continue
				}
				throw SQLDataStoreError.couldNotDeleteGuide(element: entry)
			}
		}
	}

	public func select(using db: Connection, filteredUsing filter: Table) throws -> [GuideEntry] {
		var entries: [GuideEntry] = []
		for entry in try db.prepare(filter) {
			guard let type = GuideEntryType(rawValue: Int(entry[typeColumn])) else {
				throw SQLDataStoreError.invalidGuideType(value: entry[typeColumn])
			}
			entries.append(
				SQLGuideEntry(
					key: entry[keyColumn],
					name: entry[nameColumn],
					id: entry[idColumn],
					type: type,
					lastGrab: entry[lastGrabColumn])
			)
		}
		return entries
	}

	public func select(using db: Connection) throws -> [GuideEntry] {
		return try select(using: db, filteredUsing: table)
	}

	public func update(using db: Connection, entries: GuideEntry...) throws {
		try update(using: db, entries: entries)
	}
	
	public func update(using db: Connection, entries: [GuideEntry]) throws {
		try db.transaction {
			for entry in entries {
				guard let mutabled = entry as? SQLGuideEntry else {
					throw SQLDataStoreError.invalidGuideImplementation(element: entry)
				}
				log(debug: "Updating guide entry with key \(mutabled.key)")
				let filter = self.table.filter(self.keyColumn == mutabled.key)
				let parameters = [
					self.nameColumn <- entry.name,
					self.idColumn <- entry.id,
					self.typeColumn <- entry.type.rawValue,
					self.lastGrabColumn <- entry.lastGrab
				]
				guard try db.run(filter.update(parameters)) == 0 else {
					continue
				}
				throw SQLDataStoreError.couldNotUpdateGuide(element: entry)
			}
		}
	}

}

public class SQLGuideEntry: GuideEntry {
	
	var key: Int64
	public var name: String
	public var id: String
	public var type: GuideEntryType
	public var lastGrab: Date?
	
	init(key: Int64, name: String, id: String, type: GuideEntryType, lastGrab: Date? = nil) {
		self.key = key
		self.name = name
		self.id = id
		self.type = type
		self.lastGrab = lastGrab
	}
	
}

