//
//  TestUtilities.swift
//  SQLiteMIVRKit-macOS
//
//  Created by Shane Whitehead on 21/9/17.
//  Copyright © 2017 SQLiteMIVRKit. All rights reserved.
//

import Foundation
import SQLite
import MIVRKit
import SQLiteMIVRKit

struct TestUtilities {
	
	static func setupDataStore() throws {
		#if os(OSX)
			try SQLDataStore.configure(productName: "SQLiteMIVRKit", databaseName: "MIVR.db")
		#else
			try SQLDataStore.configure(databaseName: "MIVR.db")
		#endif
	}
	
}
