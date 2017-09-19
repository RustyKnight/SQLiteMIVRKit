//
//  DataStore.swift
//  SQLiteMIVRKit-macOS
//
//  Created by Shane Whitehead on 19/9/17.
//  Copyright © 2017 SQLiteMIVRKit. All rights reserved.
//

import Foundation
import MIVRKit
import SQLite
import KZSimpleLogger

public enum SQLDataStoreError: Error {
	case noPathAvaliable
	case couldNotFindGuideAfterInsert
	case couldNotFindHistoryAfterInsert
	case invalidRowID
	case invalidGuideType(value: Int)
	case invalidQueueStatus(value: Int)
	case couldNotDeleteGuide(element: GuideEntry)
	case couldNotDeleteHistory(element: HistoryEntry)
	case couldNotDeleteQueueEntry(element: QueueEntry)
	case invalidGuideImplementation(element: GuideEntry)
	case invalidHistoryImplementation(element: HistoryEntry)
	case invalidQueueImplementation(element: QueueEntry)
	case couldNotUpdateGuide(element: GuideEntry)
	case couldNotUpdateHistory(element: HistoryEntry)
	case couldNotUpdateQueueEntry(element: QueueEntry)
	case couldNotFindQueueEntryAfterInsert
}

public class SQLDataStore: DefaultDataStore {
	
	private let productName: String?
	private let databaseName: String

	let guideTable: GuideTable = GuideTable()
	let historyTable: HistoryTable = HistoryTable()
	let queueTable: QueueTable = QueueTable()
	
	var databasePath: URL? {
		var searchPath: FileManager.SearchPathDirectory = .documentDirectory
		#if os(OSX)
			searchPath = .applicationSupportDirectory
		#endif
		let urls: [URL] = FileManager.default.urls(for: searchPath, in: .userDomainMask)
		guard var url = urls.first else {
			return nil
		}
		if let productName = productName, !productName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
			url = url.appendingPathComponent(productName, isDirectory: true)
		}
		do {
			try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
		} catch let error {
			log(error: "\(error)")
		}
		url = url.appendingPathComponent(databaseName, isDirectory: false)
		log(debug: "DatabasePath = \(url.path)")
		return url
	}
	
	init(productName: String? = nil, databaseName: String) throws {
		self.productName = productName
		self.databaseName = databaseName
		
		super.init()
		
		try createTables()
	}
	
	public static func configure(productName: String? = nil, databaseName: String) throws {
		let instance = try SQLDataStore(productName: productName, databaseName: databaseName)
		MutableDataStoreService.shared = instance
	}
	
	func connection() throws -> Connection {
		guard let path = databasePath else {
			throw SQLDataStoreError.noPathAvaliable
		}
		let db = try Connection(path.path)
		db.busyTimeout = 5
		return db
	}

	func createTables() throws {
		try createGuideEntriesTable()
		try createHistoryEntriesTable()
		try createQueueEntriesTable()
	}
	
	func createGuideEntriesTable() throws {
		let connection = try self.connection()
		try guideTable.create(using: connection)
	}

	func createHistoryEntriesTable() throws {
		let connection = try self.connection()
		try historyTable.create(using: connection)
	}

	func createQueueEntriesTable() throws {
		let connection = try self.connection()
		try queueTable.create(using: connection)
	}

	// MARK: Guide Entries
	
	public override func guide() throws -> [GuideEntry] {
		return try guideTable.select(using: try connection())
	}
	
	public override func addToGuide(named: String, id: String, type: GuideEntryType, lastGrab: Date?) throws -> GuideEntry {
		let db = try connection()
		return try guideTable.insert(name: named, id: id, type: type, lastGrab: lastGrab, using: db)
	}
	
	public override func remove(_ entries: [GuideEntry]) throws {
		try guideTable.delete(using: try connection(), entries: entries)
	}
	
	public override func update(_ entries: [GuideEntry]) throws {
		try guideTable.update(using: try connection(), entries: entries)
	}

	// MARK: History Entries

	public override func history() throws -> [HistoryEntry] {
		return try historyTable.select(using: try connection())
	}

	public override func addToHistory(guid: String, ignored: Bool, score: Int) throws -> HistoryEntry {
		let db = try connection()
		return try historyTable.insert(guid: guid, ignored: ignored, score: score, using: db)
		}
	
	public override func remove(_ entries: [HistoryEntry]) throws {
		try historyTable.delete(using: try connection(), entries: entries)
	}
	
	public override func update(_ entries: [HistoryEntry]) throws {
		try historyTable.update(using: try connection(), entries: entries)
	}
	
	// MARK: Queue Entries

	public override func queue() throws -> [QueueEntry] {
		return try queueTable.select(using: try connection())
	}

	public override func addToQueue(guid: String, id: String, name: String, status: QueueEntryStatus, score: Int) throws -> QueueEntry {
		let db = try connection()
		return try queueTable.insert(guid: guid, id: id, name: name, status: status, score: score, using: db)
	}
	
	public override func remove(_ entries: [QueueEntry]) throws {
		try queueTable.delete(using: try connection(), entries: entries)
	}
	
	public override func update(_ entries: [QueueEntry]) throws {
		try queueTable.update(using: try connection(), entries: entries)
	}
}
