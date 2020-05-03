/// ZDCSyncable
/// https://github.com/4th-ATechnologies/ZDCSyncable
///
/// Undo, redo & merge capabilities for structs & classes in pure Swift.

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
		
		var changesets: [ZDCChangeset] = []
	
		var localStruct = SimpleStruct(someString: "abc123", someInteger: 42)
	
		localStruct.clearChangeTracking()
		var cloudStruct = localStruct
	
		do { // local changes
	
			localStruct.someString = "def456"
			changesets.append(localStruct.changeset() ?? Dictionary())
		}
		do { // cloud changes
	
			cloudStruct.someInteger = 43
		}
	
		do {
			let _ =  try localStruct.merge(cloudVersion: cloudStruct, pendingChangesets: changesets)
		}
		catch {
			XCTAssert(false, "Threw error: \(error)")
		}
	
		XCTAssert(localStruct.someString == "def456")
		XCTAssert(localStruct.someInteger == 43)
	}
	
	func test_simpleMerge_2() {
		
		var changesets: [ZDCChangeset] = []
	
		var localStruct = SimpleStruct(someString: "abc123", someInteger: 42)
	
		localStruct.clearChangeTracking()
		var cloudStruct = localStruct
	
		do { // local changes
	
			localStruct.someString = "def456"
			changesets.append(localStruct.changeset() ?? Dictionary())
		}
		do { // cloud changes
	
			cloudStruct.someString = "xyz789"
			cloudStruct.someInteger = 43
		}
	
		do {
			let _ =  try localStruct.merge(cloudVersion: cloudStruct, pendingChangesets: changesets)
		}
		catch {
			XCTAssert(false, "Threw error: \(error)")
		}
	
		XCTAssert(localStruct.someString == "xyz789")
		XCTAssert(localStruct.someInteger == 43)
	}

	func test_simpleMerge_3() {
		
		var changesets: [ZDCChangeset] = []
	
		var localStruct = SimpleStruct(someString: "abc123", someInteger: 42)
	
		localStruct.clearChangeTracking()
		var cloudStruct = localStruct
	
		do { // local changes
	
			localStruct.someString = "def456"
			changesets.append(localStruct.changeset() ?? Dictionary())
		}
		do { // cloud changes
	
			cloudStruct.someString = "xyz789"
			cloudStruct.someInteger = 43
		}
	
		do {
			let _ =  try localStruct.merge(cloudVersion: cloudStruct, pendingChangesets: changesets)
		}
		catch {
			XCTAssert(false, "Threw error: \(error)")
		}
	
		XCTAssert(localStruct.someString == "xyz789")
		XCTAssert(localStruct.someInteger == 43)
	}

	func test_simpleMerge_4() {
		
		var changesets: [ZDCChangeset] = []
	
		var localStruct = SimpleStruct(someString: "abc123", someInteger: 42)
	
		localStruct.clearChangeTracking()
		var cloudStruct = localStruct
	
		do { // local changes
	
			localStruct.someString = "def456"
			changesets.append(localStruct.changeset() ?? Dictionary())
		}
		do { // cloud changes
	
			cloudStruct.someInteger = 43
		}
		
		do {
			let _ =  try localStruct.merge(cloudVersion: cloudStruct, pendingChangesets: changesets)
		}
		catch {
			XCTAssert(false, "Threw error: \(error)")
		}
	
		XCTAssert(localStruct.someString == "def456")
		XCTAssert(localStruct.someInteger == 43)
	}

	func test_simpleMerge_5() {
		
		var changesets: [ZDCChangeset] = []
	
		var localStruct = SimpleStruct(someString: "abc123", someInteger: 42)
	
		localStruct.clearChangeTracking()
		var cloudStruct = localStruct
	
		do { // local changes
	
			localStruct.someInteger = 43;
			changesets.append(localStruct.changeset() ?? Dictionary())
		}
		do { // cloud changes
	
			cloudStruct.someString = "xyz789"
		}
	
		do {
			let _ =  try localStruct.merge(cloudVersion: cloudStruct, pendingChangesets: changesets)
		}
		catch {
			XCTAssert(false, "Threw error: \(error)")
		}
	
		XCTAssert(localStruct.someString == "xyz789")
		XCTAssert(localStruct.someInteger == 43)
	}

	
	// ====================================================================================================
	// MARK: Merge: Complex
	// ====================================================================================================

	func test_complexMerge_1() {
		
		var changesets: [ZDCChangeset] = []
	
		var localStruct = ComplexStruct(someString: "abc123", someInteger: 42)
		localStruct.dict["dog"] = "bark"
	
		localStruct.clearChangeTracking()
		XCTAssert(!localStruct.hasChanges)
		
		var cloudStruct = localStruct
	
		do { // local changes
	
			localStruct.someString = "abc123"
			localStruct.dict["cat"] = "meow"
			changesets.append(localStruct.changeset() ?? Dictionary())
		}
		do { // cloud changes
	
			cloudStruct.someInteger = 43
			cloudStruct.dict["duck"] = "quack"
		}
		
		XCTAssert(localStruct.dict["duck"] == nil, "Shallow copy")
		
		do {
			let _ =  try localStruct.merge(cloudVersion: cloudStruct, pendingChangesets: changesets)
		}
		catch {
			XCTAssert(false, "Threw error: \(error)")
		}
	
		XCTAssert(localStruct.someString == "abc123")
		XCTAssert(localStruct.someInteger == 43)
	
		XCTAssert(localStruct.dict["dog"]  == "bark")
		XCTAssert(localStruct.dict["cat"]  == "meow")
		XCTAssert(localStruct.dict["duck"] == "quack")
	}
}
