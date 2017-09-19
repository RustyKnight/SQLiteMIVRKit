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
	case couldNotDeleteGuide(element: GuideItem)
	case couldNotDeleteHistory(element: HistoryItem)
	case couldNotDeleteQueueItem(element: QueueItem)
	case invalidGuideImplementation(element: GuideItem)
	case invalidHistoryImplementation(element: HistoryItem)
	case invalidQueueImplementation(element: QueueItem)
	case couldNotUpdateGuide(element: GuideItem)
	case couldNotUpdateHistory(element: HistoryItem)
	case couldNotUpdateQueueItem(element: QueueItem)
	case couldNotFindQueueItemAfterInsert
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
	
	public override func guide() throws -> [GuideItem] {
		return try guideTable.select(using: try connection())
	}
	
	public override func addToGuide(named: String, id: String, type: GuideItemType, lastGrab: Date?) throws -> GuideItem {
		let db = try connection()
		return try guideTable.insert(name: named, id: id, type: type, lastGrab: lastGrab, using: db)
	}
	
	public override func remove(_ entries: [GuideItem]) throws {
		try guideTable.delete(using: try connection(), entries: entries)
	}
	
	public override func update(_ entries: [GuideItem]) throws {
		try guideTable.update(using: try connection(), entries: entries)
	}

	// MARK: History Entries

	public override func history() throws -> [HistoryItem] {
		return try historyTable.select(using: try connection())
	}

  public override func addToHistory(groupID: String, guid: String, ignored: Bool, score: Int) throws -> HistoryItem {
		let db = try connection()
    return try historyTable.insert(groupID: groupID, guid: guid, ignored: ignored, score: score, using: db)
		}
	
	public override func remove(_ entries: [HistoryItem]) throws {
		try historyTable.delete(using: try connection(), entries: entries)
	}
	
	public override func update(_ entries: [HistoryItem]) throws {
		try historyTable.update(using: try connection(), entries: entries)
	}
	
	// MARK: Queue Entries

	public override func queue() throws -> [QueueItem] {
		return try queueTable.select(using: try connection())
	}

  public override func addToQueue(guid: String, id: String, name: String, status: QueueItemStatus, score: Int, link: String) throws -> QueueItem {
		let db = try connection()
    return try queueTable.insert(guid: guid, id: id, name: name, status: status, score: score, link: link, using: db)
	}
	
	public override func remove(_ entries: [QueueItem]) throws {
		try queueTable.delete(using: try connection(), entries: entries)
	}
	
	public override func update(_ entries: [QueueItem]) throws {
		try queueTable.update(using: try connection(), entries: entries)
	}
}
