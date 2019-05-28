/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

import XCTest

class test_ZDCRecord: XCTestCase {

//	override func setUp() {
//	}

//	override func tearDown() {
//	}
	
	func test_undo() {
		
		var sr_a: SimpleRecord?
		var sr_b: SimpleRecord?
		
		let sr = SimpleRecord()
		
		sr.someString = "abc123"
		sr.someInteger = 42
		
		sr.clearChangeTracking()
		sr_a = sr.immutableCopy() as? SimpleRecord
		
		sr.someString = "def456"
		sr.someInteger = 23
		
		let changeset_undo = sr.changeset() ?? Dictionary()
		sr_b = sr.immutableCopy() as? SimpleRecord
		
		do {
			let changeset_redo = try sr.undo(changeset_undo)
			XCTAssert(sr.isEqual(sr_a))
			
			let _ = try sr.undo(changeset_redo)
			XCTAssert(sr.isEqual(sr_b))
			
		} catch {
			XCTAssert(false, "Threw error: \(error)")
		}
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK:- Merge: Simple
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	func test_simpleMerge_1() {
		
		var changesets = Array<Dictionary<String, Any>>()
	
		let localRecord = SimpleRecord()
		localRecord.someString = "abc123"
		localRecord.someInteger = 42
	
		localRecord.clearChangeTracking()
		let cloudRecord = localRecord.copy() as! SimpleRecord
	
		do { // local changes
	
			localRecord.someString = "def456"
			changesets.append(localRecord.changeset() ?? Dictionary())
		}
		do { // cloud changes
	
			cloudRecord.someInteger = 43;
			cloudRecord.makeImmutable()
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

	func test_simpleMerge_2() {
		
		var changesets = Array<Dictionary<String, Any>>()
	
		let localRecord = SimpleRecord()
		localRecord.someString = "abc123"
		localRecord.someInteger = 42
	
		localRecord.clearChangeTracking()
		let cloudRecord = localRecord.copy() as! SimpleRecord
	
		do { // local changes
	
			localRecord.someString = "def456"
			changesets.append(localRecord.changeset() ?? Dictionary())
		}
		do { // cloud changes
	
			cloudRecord.someString = "xyz789"
			cloudRecord.someInteger = 43
			cloudRecord.makeImmutable()
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
	
		let localRecord = SimpleRecord()
		localRecord.someString = nil
		localRecord.someInteger = 42
	
		localRecord.clearChangeTracking()
		let cloudRecord = localRecord.copy() as! SimpleRecord
	
		do { // local changes
	
			localRecord.someString = "def456"
			changesets.append(localRecord.changeset() ?? Dictionary())
		}
		do { // cloud changes
	
			cloudRecord.someString = "xyz789"
			cloudRecord.someInteger = 43
			cloudRecord.makeImmutable()
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
	
		let localRecord = SimpleRecord()
		localRecord.someString = nil
		localRecord.someInteger = 42
	
		localRecord.clearChangeTracking()
		let cloudRecord = localRecord.copy() as! SimpleRecord
	
		do { // local changes
	
			localRecord.someString = "def456"
			changesets.append(localRecord.changeset() ?? Dictionary())
		}
		do { // cloud changes
	
			cloudRecord.someInteger = 43;
			cloudRecord.makeImmutable()
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
	
		let localRecord = SimpleRecord()
		localRecord.someString = "abc123"
		localRecord.someInteger = 42
	
		localRecord.clearChangeTracking()
		let cloudRecord = localRecord.copy() as! SimpleRecord
	
		do { // local changes
	
			localRecord.someInteger = 43;
			changesets.append(localRecord.changeset() ?? Dictionary())
		}
		do { // cloud changes
	
			cloudRecord.someString = nil;
			cloudRecord.makeImmutable()
		}
	
		do {
			let _ =  try localRecord.merge(cloudVersion: cloudRecord, pendingChangesets: changesets)
		}
		catch {
			XCTAssert(false, "Threw error: \(error)")
		}
	
		XCTAssert(localRecord.someString == nil)
		XCTAssert(localRecord.someInteger == 43)
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Merge: Complex
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	func test_enumeration() {
		
		let record = ComplexRecord()
		
		var count = 0
		record.enumerateProperties { (key: String, value: Any?) in
			
			print("key: \(key)")
			count += 1
		}
		
		XCTAssert(count == 3)
	}
	
	func test_complexMerge_1() {
		
		var changesets = Array<Dictionary<String, Any>>()
	
		let localRecord = ComplexRecord()
		localRecord.dict["dog"] = "bark"
	
		localRecord.clearChangeTracking()
		let cloudRecord = localRecord.copy() as! ComplexRecord
	
		do { // local changes
	
			localRecord.someString = "abc123"
			localRecord.dict["cat"] = "meow"
			changesets.append(localRecord.changeset() ?? Dictionary())
		}
		do { // cloud changes
	
			cloudRecord.someInteger = 43
			cloudRecord.dict["duck"] = "quack"
			cloudRecord.makeImmutable()
		}
		
		XCTAssert(localRecord.dict["duck"] == nil, "Shallow copy")
		
		do {
			let _ =  try localRecord.merge(cloudVersion: cloudRecord, pendingChangesets: changesets)
		}
		catch {
			XCTAssert(false, "Threw error: \(error)")
		}
	
		XCTAssert(localRecord.someString == "abc123")
		XCTAssert(localRecord.someInteger == 43)
	
		XCTAssert(localRecord.dict["dog"]  == "bark")
		XCTAssert(localRecord.dict["cat"]  == "meow")
		XCTAssert(localRecord.dict["duck"] == "quack")
	}

}
