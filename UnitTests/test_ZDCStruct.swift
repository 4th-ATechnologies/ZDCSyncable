/// ZDCSyncable
/// https://github.com/4th-ATechnologies/ZDCSyncable
///
/// Undo, redo & merge capabilities for structs & objects in pure Swift.

import XCTest

class test_ZDCStruct: XCTestCase {

	func test_undo() {
		
		var sr_a: SimpleStruct?
		var sr_b: SimpleStruct?
		
		var sr = SimpleStruct(someString: "abc123", someInteger: 42)
		
		sr.clearChangeTracking()
		sr_a = sr
		
		sr.someString = "def456"
		sr.someInteger = 23
		
		let changeset_undo = sr.changeset() ?? Dictionary()
		sr_b = sr
		
		do {
			let changeset_redo = try sr.undo(changeset_undo)
			XCTAssert(sr == sr_a)
			
			let _ = try sr.undo(changeset_redo)
			XCTAssert(sr == sr_b)
			
		} catch {
			XCTAssert(false, "Threw error: \(error)")
		}
	}
	
	// ====================================================================================================
	// MARK:- Merge: Simple
	// ====================================================================================================

	func test_simpleMerge_1() {
		
		var changesets = Array<Dictionary<String, Any>>()
	
		var localRecord = SimpleStruct(someString: "abc123", someInteger: 42)
	
		localRecord.clearChangeTracking()
		var cloudRecord = localRecord
	
		do { // local changes
	
			localRecord.someString = "def456"
			changesets.append(localRecord.changeset() ?? Dictionary())
		}
		do { // cloud changes
	
			cloudRecord.someInteger = 43
		}
	
		do {
			let _ =  try localRecord.merge(cloudVersion: cloudRecord, pendingChangesets: changesets)
		}
		catch {
			XCTAssert(false, "Threw error: \(error)")
		}
	
		XCTAssert(localRecord.someString == "def456")
		XCTAssert(localRecord.someInteger == 43)
	}
/*
	func test_simpleMerge_2() {
		
		var changesets = Array<Dictionary<String, Any>>()
	
		var localRecord = SimpleStruct(someString: "abc123", someInteger: 42)
	
		localRecord.clearChangeTracking()
		var cloudRecord = localRecord
	
		do { // local changes
	
			localRecord.someString = "def456"
			changesets.append(localRecord.changeset() ?? Dictionary())
		}
		do { // cloud changes
	
			cloudRecord.someString = "xyz789"
			cloudRecord.someInteger = 43
		}
	
		do {
			let _ =  try localRecord.merge(cloudVersion: cloudRecord, pendingChangesets: changesets)
		}
		catch {
			XCTAssert(false, "Threw error: \(error)")
		}
	
		XCTAssert(localRecord.someString == "xyz789")
		XCTAssert(localRecord.someInteger == 43)
	}

	func test_simpleMerge_3() {
		
		var changesets = Array<Dictionary<String, Any>>()
	
		var localRecord = SimpleStruct(someString: "abc123", someInteger: 42)
	
		localRecord.clearChangeTracking()
		var cloudRecord = localRecord
	
		do { // local changes
	
			localRecord.someString = "def456"
			changesets.append(localRecord.changeset() ?? Dictionary())
		}
		do { // cloud changes
	
			cloudRecord.someString = "xyz789"
			cloudRecord.someInteger = 43
		}
	
		do {
			let _ =  try localRecord.merge(cloudVersion: cloudRecord, pendingChangesets: changesets)
		}
		catch {
			XCTAssert(false, "Threw error: \(error)")
		}
	
		XCTAssert(localRecord.someString == "xyz789")
		XCTAssert(localRecord.someInteger == 43)
	}

	func test_simpleMerge_4() {
		
		var changesets = Array<Dictionary<String, Any>>()
	
		var localRecord = SimpleStruct(someString: "abc123", someInteger: 42)
	
		localRecord.clearChangeTracking()
		var cloudRecord = localRecord
	
		do { // local changes
	
			localRecord.someString = "def456"
			changesets.append(localRecord.changeset() ?? Dictionary())
		}
		do { // cloud changes
	
			cloudRecord.someInteger = 43
		}
		
		do {
			let _ =  try localRecord.merge(cloudVersion: cloudRecord, pendingChangesets: changesets)
		}
		catch {
			XCTAssert(false, "Threw error: \(error)")
		}
	
		XCTAssert(localRecord.someString == "def456")
		XCTAssert(localRecord.someInteger == 43)
	}

	func test_simpleMerge_5() {
		
		var changesets = Array<Dictionary<String, Any>>()
	
		var localRecord = SimpleStruct(someString: "abc123", someInteger: 42)
	
		localRecord.clearChangeTracking()
		var cloudRecord = localRecord
	
		do { // local changes
	
			localRecord.someInteger = 43;
			changesets.append(localRecord.changeset() ?? Dictionary())
		}
		do { // cloud changes
	
			cloudRecord.someString = "xyz789"
		}
	
		do {
			let _ =  try localRecord.merge(cloudVersion: cloudRecord, pendingChangesets: changesets)
		}
		catch {
			XCTAssert(false, "Threw error: \(error)")
		}
	
		XCTAssert(localRecord.someString == "xyz789")
		XCTAssert(localRecord.someInteger == 43)
	}
*/
}
