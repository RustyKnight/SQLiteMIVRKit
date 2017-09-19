//
//  TestDataStore.swift
//  SQLiteMIVRKit-macOS Tests
//
//  Created by Shane Whitehead on 19/9/17.
//  Copyright © 2017 SQLiteMIVRKit. All rights reserved.
//

import XCTest
import SQLiteMIVRKit
import MIVRKit

class TestDataStore: XCTestCase {
	
	override func setUp() {
			super.setUp()
			// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
			// Put teardown code here. This method is called after the invocation of each test method in the class.
			super.tearDown()
	}
	
	static func configure() throws {
		#if os(OSX)
			try SQLDataStore.configure(productName: "SQLiteMIVRKit", databaseName: "MIVR.db")
		#else
			try SQLDataStore.configure(databaseName: "MIVR.db")
		#endif
	}
	
	func testConfiguration() {
		do {
			try TestDataStore.configure()
			guard let _ = DataStoreService.shared as? SQLDataStore else {
				XCTFail("DataStore is not an instance of SQLDataStore")
				return
			}
		} catch let error {
			XCTFail("\(error)")
		}
	}
	
	func testGuideTable() {
		do {
			try TestDataStore.configure()
			let dataStore = DataStoreService.shared
			
			var entries = try dataStore.guide()
			if entries.count > 0 {
				print("Remove \(entries.count) guide entries")
				try dataStore.remove(entries)
			}
			
			var guide = try dataStore.addToGuide(named: "Guide Test", id: "1234", type: .tvSeries, lastGrab: nil)
			assert(guide.id == "1234", "Invalid guide id, expecting 1234, got \(guide.id)")
			assert(guide.name == "Guide Test", "Invalid guide name, expecting \"Guide Test\", got \"\(guide.name)\"")
			assert(guide.type == .tvSeries, "Invalid guide type, expecting \(GuideEntryType.tvSeries), got \(guide.type)")
			
			guide.id = "5678"
			guide.name = "Update"
			guide.type = .movie
			
			try dataStore.update(guide)
			assert(guide.id == "5678", "Invalid guide id, expecting 5678, got \(guide.id)")
			assert(guide.name == "Update", "Invalid guide name, expecting \"Update\", got \"\(guide.name)\"")
			assert(guide.type == .movie, "Invalid guide type, expecting \(GuideEntryType.movie), got \(guide.type)")

			entries = try dataStore.guide()
			if entries.count > 0 {
				print("Remove \(entries.count) guide entries")
				try dataStore.remove(entries)
			}
		} catch let error {
			XCTFail("\(error)")
		}
	}
	
	func testHistoryTable() {
		do {
			try TestDataStore.configure()
			let dataStore = DataStoreService.shared
			
			var entries = try dataStore.history()
			if entries.count > 0 {
				print("Remove \(entries.count) history entries")
				try dataStore.remove(entries)
			}
			
			var history = try dataStore.addToHistory(guid: "1234", ignored: false, score: 1)
			assert(history.guid == "1234", "Invalid guide id, expecting 1234, got \(history.guid)")
			assert(history.isIgnored == false, "Invalid guide name, expecting false, got \"\(history.isIgnored)\"")
			assert(history.score == 1, "Invalid guide type, expecting 1, got \(history.score)")
			
			history.guid = "5678"
			history.isIgnored = true
			history.score = 100
			
			try dataStore.update(history)
			assert(history.guid == "5678", "Invalid guide id, expecting 5678, got \(history.guid)")
			assert(history.isIgnored == true, "Invalid guide name, expecting true, got \"\(history.isIgnored)\"")
			assert(history.score == 100, "Invalid guide type, expecting 100, got \(history.score)")

			entries = try dataStore.history()
			if entries.count > 0 {
				print("Remove \(entries.count) history entries")
				try dataStore.remove(entries)
			}
		} catch let error {
			XCTFail("\(error)")
		}
	}

	func testQueueTable() {
		do {
			try TestDataStore.configure()
			let dataStore = DataStoreService.shared
			
			var entries = try dataStore.queue()
			if entries.count > 0 {
				print("Remove \(entries.count) queue entries")
				try dataStore.remove(entries)
			}
			
			var history = try dataStore.addToQueue(guid: "1234", id: "5678", name: "Test", status: .queued, score: 1)
			assert(history.guid == "1234", "Invalid guide id, expecting \"1234\", got \"\(history.guid)\"")
			assert(history.id == "5678", "Invalid guide name, expecting \"5678\", got \"\(history.id)\"")
			assert(history.name == "Test", "Invalid guide type, expecting \"Test\", got \"\(history.name)\"")
			assert(history.status == .queued, "Invalid guide type, expecting \"\(QueueEntryStatus.queued)\", got \"\(history.status)\"")
			assert(history.score == 1, "Invalid guide type, expecting 1, got \(history.score)")
			
			history.guid = "5678"
			history.id = "1234"
			history.name = "Testing"
			history.status = .active
			history.score = 100
			
			try dataStore.update(history)
			assert(history.guid == "5678", "Invalid guide id, expecting \"5678\", got \"\(history.guid)\"")
			assert(history.id == "1234", "Invalid guide name, expecting \"1234\", got \"\(history.id)\"")
			assert(history.name == "Testing", "Invalid guide type, expecting \"Testing\", got \"\(history.name)\"")
			assert(history.status == .active, "Invalid guide type, expecting \"\(QueueEntryStatus.active)\", got \"\(history.status)\"")
			assert(history.score == 100, "Invalid guide type, expecting 1, got \(history.score)")

			entries = try dataStore.queue()
			if entries.count > 0 {
				print("Remove \(entries.count) queue entries")
				try dataStore.remove(entries)
			}
		} catch let error {
			XCTFail("\(error)")
		}
	}
	

}
