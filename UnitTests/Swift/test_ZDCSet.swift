/**
 * ZDCSyncable
 * <GitHub URL goes here>
**/

import XCTest
import ZDCSyncable

class test_ZDCSet: XCTestCase {
	
	func randomLetters(_ length: UInt) -> String {
		
		let alphabet = "abcdefghijklmnopqrstuvwxyz"
		return String((0..<length).map{ _ in alphabet.randomElement()! })
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK:- Fuzz
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	func test_undo_fuzz_everything() {
		
		let DEBUG_THIS_METHOD = false
	
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var set_a: ZDCSet<String>?
			var set_b: ZDCSet<String>?
			
			let set = ZDCSet<String>()
			
			// Start with an object that has a random number of objects [20 - 30)
			do {
				
				var startCount: UInt!
				if (DEBUG_THIS_METHOD) {
					startCount = 5
				} else {
					startCount = 20 + UInt(arc4random_uniform(UInt32(10)))
				}
				
				for _ in 0 ..< startCount {
					
					let key = self.randomLetters(8)
					set.insert(key)
				}
			}
			
			set.clearChangeTracking()
			set_a = set.immutableCopy() as? ZDCSet<String>
			
			// Now make a random number of changes: [1 - 30)
			
			var changeCount: UInt!
			if (DEBUG_THIS_METHOD) {
				changeCount = 1
			} else {
				changeCount = 1 + UInt(arc4random_uniform(UInt32(29)))
			}
			
			for _ in 0 ..< changeCount {
				
				let random = arc4random_uniform(UInt32(2))
				
				if (random == 0)
				{
					// Add an item
					
					let key = self.randomLetters(8)
					
					if DEBUG_THIS_METHOD {
						print("addObject: \(key)");
					}
					set.insert(key)
				}
				else if (random == 1)
				{
					// Remove an item
					
					let idx = arc4random_uniform(UInt32(set.count))
					
					var key: String?
					var i = 0
					for obj in set.rawSet {
						
						if (i == idx) {
							key = obj
							break;
						}
						i += 1
					}
					
					if DEBUG_THIS_METHOD {
						print("removeObject: \(key ?? "<nil>")")
					}
					if key != nil {
						set.remove(key!)
					}
					
				}
			}
			
			let changeset_undo = set.changeset() ?? Dictionary()
			set_b = set.immutableCopy() as? ZDCSet<String>
			
			do {
				
				let changeset_redo = try set.undo(changeset_undo) // a <- b
				if DEBUG_THIS_METHOD && !set.isEqual(set_a) {
					print("It's going to FAIL")
				}
				XCTAssert(set.isEqual(set_a))
			
				let _ = try set.undo(changeset_redo) // a -> b
				if DEBUG_THIS_METHOD && !set.isEqual(set_b) {
					print("It's going to FAIL");
				}
				XCTAssert(set.isEqual(set_b))
				
			} catch {
				print("Threw error: \(error)")
				XCTAssert(false)
			}
			
			if DEBUG_THIS_METHOD {
				print("-------------------------------------------------");
			}
		}}
	}
	
	func test_import_fuzz_everything() {
		
		let DEBUG_THIS_METHOD = false
	
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var set_a: ZDCSet<String>?
			var set_b: ZDCSet<String>?
			
			let set = ZDCSet<String>()
			var changesets = Array<Dictionary<String, Any>>()
	
			// Start with an object that has a random number of objects [20 - 30)
			do {
	
				var startCount: UInt!
				if DEBUG_THIS_METHOD {
					startCount = 5
				} else {
					startCount = 20 + UInt(arc4random_uniform(UInt32(10)));
				}
				
				for _ in 0 ..< startCount {
					
					let key = self.randomLetters(8)
					set.insert(key)
				}
			}
			
			set.clearChangeTracking()
			set_a = set.immutableCopy() as? ZDCSet<String>
			
			// Make a random number of changesets: [1 - 10)
			
			var changesetCount: UInt!
			if DEBUG_THIS_METHOD {
				changesetCount = 2
			} else {
				changesetCount = 1 + UInt(arc4random_uniform(UInt32(9)))
			}
			
			for _ in 0 ..< changesetCount {
				
				// Make a random number of changes: [1 - 30)
				
				var changeCount: UInt!
				if DEBUG_THIS_METHOD {
					changeCount = 2
				} else {
					changeCount = 1 + UInt(arc4random_uniform(UInt32(29)))
				}
				
				for _ in 0 ..< changeCount {
					
					let random = arc4random_uniform(UInt32(2))
					
					if (random == 0)
					{
						// Add an item
						
						let key = self.randomLetters(8)
						
						if DEBUG_THIS_METHOD {
							print("addObject: \(key)")
						}
						set.insert(key)
					}
					else if (random == 1)
					{
						// Remove an item
						
						let idx = UInt(arc4random_uniform(UInt32(set.count)))
						
						var key: String?
						var i = UInt(0)
						for obj in set.rawSet {
							
							if i == idx {
								key = obj
								break;
							}
							i+=1
						}
						
						if DEBUG_THIS_METHOD {
							print("removeObject: \(key ?? "<nil>")")
						}
						if key != nil {
							set.remove(key!)
						}
					}
				}
				
				let changeset = set.changeset() ?? Dictionary()
				changesets.append(changeset)
				
				if DEBUG_THIS_METHOD {
					print("********************");
				}
			}
			
			set_b = set.immutableCopy() as? ZDCSet<String>
			
			do {
				
				try set.importChangesets(changesets)
				XCTAssert(set.isEqual(set_b))
				
				let changeset_merged = set.changeset() ?? Dictionary()
				
				let changeset_redo = try set.undo(changeset_merged)
				if DEBUG_THIS_METHOD && !set.isEqual(set_a) {
					print("It's going to FAIL")
				}
				XCTAssert(set.isEqual(set_a))
				
				let _ = try set.undo(changeset_redo)
				if DEBUG_THIS_METHOD && !set.isEqual(set_b) {
					print("It's going to FAIL")
				}
				XCTAssert(set.isEqual(set_b))
				
				if DEBUG_THIS_METHOD {
					print("-------------------------------------------------")
				}
			} catch {
				XCTAssert(false, "Threw error: \(error)")
			}
		}}
	}
	
	func test_merge_fuzz_everything() {
		
		let DEBUG_THIS_METHOD = false
		
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var changesets = Array<Dictionary<String, Any>>()
			
			var set = ZDCSet<String>()
			
			// Start with an object that has a random number of objects [20 - 30)
			do {
				
				var startCount: UInt!
				if DEBUG_THIS_METHOD {
					startCount = 5
				} else {
					startCount = 20 + UInt(arc4random_uniform(UInt32(10)))
				}
				
				for _ in 0 ..< startCount {
					
					let key = self.randomLetters(8)
					set.insert(key)
				}
			}
			
			set.clearChangeTracking()
			var set_cloud = set.immutableCopy() as! ZDCSet<String> // sanity check: don't allow modification (for now)
			
			// Make a random number of changesets: [1 - 10)
			
			var changesetCount: UInt!
			if DEBUG_THIS_METHOD {
				changesetCount = 2
			} else {
				changesetCount = 1 + UInt(arc4random_uniform(UInt32(9)))
			}
			
			for _ in 0 ..< changesetCount {
				
				// Make a random number of changes (to localSet): [1 - 30)
				
				var changeCount: UInt!
				if DEBUG_THIS_METHOD {
					changeCount = 2
				} else {
					changeCount = 1 + UInt(arc4random_uniform(UInt32(29)))
				}
				
				for _ in 0 ..< changeCount {
					
					let random = arc4random_uniform(UInt32(2))
					
					if (random == 0)
					{
						// Add an item
						
						let key = self.randomLetters(8)
						if DEBUG_THIS_METHOD {
							print("local: addObject: \(key)")
						}
						set.insert(key)
					}
					else if (random == 1)
					{
						// Remove an item
	
						let idx = UInt(arc4random_uniform(UInt32(set.count)))
						
						var key: String?
						var i = UInt(0)
						for obj in set.rawSet {
							
							if (i == idx) {
								key = obj
								break;
							}
							i+=1
						}
						
						if DEBUG_THIS_METHOD {
							print("local: removeObject: \(key ?? "<nil>")")
						}
						if key != nil {
							set.remove(key!)
						}
					}
				}
				
				changesets.append(set.changeset() ?? Dictionary())
				
				if DEBUG_THIS_METHOD {
					print("********************")
				}
			}
			
			set.makeImmutable()                             // sanity check: don't allow modification (for now)
			set_cloud = set_cloud.copy() as! ZDCSet<String> // sanity check: allow modification again
	
			do {
				// Make a random number of changes (to cloudSet): [1 - 30)
				
				var changeCount: UInt
				if DEBUG_THIS_METHOD {
					changeCount = 2
				} else {
					changeCount = 1 + UInt(arc4random_uniform(UInt32(29)))
				}
				
				for _ in 0 ..< changeCount {
					
					let random = arc4random_uniform(UInt32(2))
					
					if (random == 0)
					{
						// Add an item
	
						let key = self.randomLetters(8)
						
						if DEBUG_THIS_METHOD {
							print("cloud: addObject: \(key)")
						}
						set_cloud.insert(key)
					}
					else if (random == 1)
					{
						// Remove an item
	
						let idx = UInt(arc4random_uniform(UInt32(set.count)))
						
						var key: String?
						var i = UInt(0)
						for obj in set.rawSet {
							
							if (i == idx) {
								key = obj
								break
							}
							i+=1
						}
						
						if DEBUG_THIS_METHOD {
							print("cloud: removeObject: \(key ?? "<nil>")")
						}
						if key != nil {
							set_cloud.remove(key!)
						}
					}
				}
			}
	
			set = set.copy() as! ZDCSet<String> // sanity check: allow modification again
			set_cloud.makeImmutable()           // sanity check: don't allow modification anymore
			
			let set_preMerge = set.immutableCopy() as! ZDCSet<String>
			
			do {
				let redo = try set.merge(cloudVersion: set_cloud, pendingChangesets: changesets)
				
				let _ = try set.undo(redo)
				if DEBUG_THIS_METHOD {
					print("It's going to FAIL")
				}
				
				if DEBUG_THIS_METHOD && !set.isEqual(set_preMerge) {
					print("It's going to FAIL")
				}
				XCTAssert(set.isEqual(set_preMerge))
				
				if DEBUG_THIS_METHOD {
					print("-------------------------------------------------")
				}
			} catch {
				XCTAssert(false, "Threw error: \(error)")
			}
		}}
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: - Simple
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	func test_simpleMerge_1() {
		
		var changesets = Array<Dictionary<String, Any>>()
		
		let localSet = ZDCSet<String>()
		localSet.insert("alice")
		localSet.insert("bob")
		
		localSet.clearChangeTracking()
		let cloudSet = localSet.copy() as! ZDCSet<String>
	
		do { // local changes
		
			localSet.remove("alice")
			localSet.insert("carol")
			
			changesets.append(localSet.changeset() ?? Dictionary())
		}
		
		do { // cloud changes
			
			cloudSet.remove("bob")
			cloudSet.insert("dave")
			
			cloudSet.makeImmutable()
		}
		
		do {
			let _ = try localSet.merge(cloudVersion: cloudSet, pendingChangesets: changesets)
		} catch {
			XCTAssert(false, "Threw error: \(error)")
		}
		
		XCTAssert(!localSet.contains("alice"))
		XCTAssert(!localSet.contains("bob"))
	
		XCTAssert(localSet.contains("carol"))
		XCTAssert(localSet.contains("dave"))
	}
	
	func test_simpleMerge_2() {
		
		var changesets = Array<Dictionary<String, Any>>()
	
		let localSet = ZDCSet<String>()
		localSet.insert("alice")
		localSet.insert("bob")
		
		localSet.clearChangeTracking()
		let cloudSet = localSet.copy() as! ZDCSet<String>
	
		do { // local changes
			
			localSet.remove("alice")
			localSet.insert("carol")
			
			changesets.append(localSet.changeset() ?? Dictionary())
		}
		
		do { // cloud changes
			
			cloudSet.remove("alice")
			cloudSet.insert("dave")
			cloudSet.remove("bob")
			cloudSet.insert("emily")
			
			cloudSet.makeImmutable()
		}
		
		do {
			let _ = try localSet.merge(cloudVersion: cloudSet, pendingChangesets: changesets)
		} catch {
			XCTAssert(false, "Threw error: \(error)")
		}
	
		XCTAssert(!localSet.contains("alice"))
		XCTAssert(!localSet.contains("bob"))
	
		XCTAssert(localSet.contains("carol"))
		XCTAssert(localSet.contains("dave"))
		XCTAssert(localSet.contains("emily"))
	}
	
	func test_simpleMerge_3() {
		
		var changesets = Array<Dictionary<String, Any>>()
		
		let localSet = ZDCSet<String>()
		localSet.insert("alice")
		
		localSet.clearChangeTracking()
		let cloudSet = localSet.copy() as! ZDCSet<String>
	
		do { // local changes
	
			localSet.insert("bob")
			
			changesets.append(localSet.changeset() ?? Dictionary())
		}
		
		do { // cloud changes
			
			cloudSet.insert("carol")
			cloudSet.remove("alice")
			cloudSet.insert("dave")
			
			cloudSet.makeImmutable()
		}
		
		do {
			let _ = try localSet.merge(cloudVersion: cloudSet, pendingChangesets: changesets)
		} catch {
			XCTAssert(false, "Threw error: \(error)")
		}
	
		XCTAssert(!localSet.contains("alice"))
	
		XCTAssert(localSet.contains("bob"))
		XCTAssert(localSet.contains("carol"))
		XCTAssert(localSet.contains("dave"))
	}
	
	func test_simpleMerge_4() {
		
		var changesets = Array<Dictionary<String, Any>>()
		
		let localSet = ZDCSet<String>()
		localSet.insert("alice")
		
		localSet.clearChangeTracking()
		let cloudSet = localSet.copy() as! ZDCSet<String>
	
		do { // local changes
	
			localSet.insert("bob")
			
			changesets.append(localSet.changeset() ?? Dictionary())
		}
		
		do { // cloud changes
	
			cloudSet.remove("alice")
			cloudSet.insert("carol")
			
			cloudSet.makeImmutable()
		}
		
		do {
			let _ = try localSet.merge(cloudVersion: cloudSet, pendingChangesets: changesets)
		} catch {
			XCTAssert(false, "Threw error: \(error)")
		}
	
		XCTAssert(!localSet.contains("alice"))
	
		XCTAssert(localSet.contains("bob"))
		XCTAssert(localSet.contains("carol"))
	}
	
	func test_simpleMerge_5() {
		
		var changesets = Array<Dictionary<String, Any>>()
		
		let localSet = ZDCSet<String>()
		localSet.insert("alice")
		localSet.insert("bob")
		
		localSet.clearChangeTracking()
		let cloudSet = localSet.copy() as! ZDCSet<String>
		
		do { // local changes
	
			localSet.remove("bob")
			localSet.insert("carol")
			
			changesets.append(localSet.changeset() ?? Dictionary())
		}
		
		do { // cloud changes
			
			cloudSet.remove("alice")
			
			cloudSet.makeImmutable()
		}
		
		do {
			let _ = try localSet.merge(cloudVersion: cloudSet, pendingChangesets: changesets)
		} catch {
			XCTAssert(false, "Threw error: \(error)")
		}
	
		XCTAssert(!localSet.contains("alice"))
		XCTAssert(!localSet.contains("bob"))
	
		XCTAssert(localSet.contains("carol"))
	}
}
