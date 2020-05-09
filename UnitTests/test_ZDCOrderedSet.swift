/// ZDCSyncable
/// https://github.com/4th-ATechnologies/ZDCSyncable
///
/// Undo, redo & merge capabilities for structs & classes in pure Swift.

import XCTest
import ZDCSyncable

class test_ZDCOrderedSet: XCTestCase {

	func randomLetters(_ length: UInt) -> String {
		
		let alphabet = "abcdefghijklmnopqrstuvwxyz"
		return String((0..<length).map{ _ in alphabet.randomElement()! })
	}
	
	// ====================================================================================================
	// MARK:- Basic
	// ====================================================================================================
	
	func test_undo_basic_1() {
		
		var orderedSet_a: ZDCOrderedSet<String>? = nil
		var orderedSet_b: ZDCOrderedSet<String>? = nil
		
		// Basic undo/redo functionality.
		//
		// - add
		
		var orderedSet = ZDCOrderedSet<String>()
		
		// Empty dictionary will be starting state
		//
		orderedSet_a = orderedSet
		
		orderedSet.insert("alice")
		orderedSet.insert("bob")
		
		XCTAssert(orderedSet.count == 2)
		
		let changeset_undo = orderedSet.changeset() ?? Dictionary()
		orderedSet_b = orderedSet
		
		do {
			let changeset_redo = try orderedSet.undo(changeset_undo)
			XCTAssert(orderedSet == orderedSet_a)
			
			let _ = try orderedSet.undo(changeset_redo)
			XCTAssert(orderedSet == orderedSet_b)
			
		} catch {
			XCTAssert(false, "Caught error: \(error)")
		}
	}
	
	func test_undo_basic_2() {
		
		var orderedSet_a: ZDCOrderedSet<String>? = nil
		var orderedSet_b: ZDCOrderedSet<String>? = nil
		
		// Basic undo/redo functionality.
		//
		// - remove
		
		var orderedSet = ZDCOrderedSet<String>()
		
		orderedSet.insert("alice")
		orderedSet.insert("bob")
		
		orderedSet.clearChangeTracking()
		orderedSet_a = orderedSet
		
		orderedSet.remove("alice")
		
		let changeset_undo = orderedSet.changeset() ?? Dictionary()
		orderedSet_b = orderedSet
		
		do {
			let changeset_redo = try orderedSet.undo(changeset_undo)
			XCTAssert(orderedSet == orderedSet_a)
			
			let _ = try orderedSet.undo(changeset_redo)
			XCTAssert(orderedSet == orderedSet_b)
		
		} catch {
			XCTAssert(false, "Caught error: \(error)")
		}
	}
	
	func test_undo_basic_3() {
		
		var orderedSet_a: ZDCOrderedSet<String>? = nil
		var orderedSet_b: ZDCOrderedSet<String>? = nil
		
		// Basic undo/redo functionality.
		//
		// - move
		
		var orderedSet = ZDCOrderedSet<String>()
		
		orderedSet.insert("alice")
		orderedSet.insert("bob")
		
		orderedSet.clearChangeTracking()
		orderedSet_a = orderedSet
		
		orderedSet.move(fromIndex:0, toIndex:1)
		
		XCTAssert(orderedSet[0] == "bob")
		XCTAssert(orderedSet[1] == "alice")
		
		let changeset_undo = orderedSet.changeset() ?? Dictionary()
		orderedSet_b = orderedSet
		
		do {
			let changeset_redo = try orderedSet.undo(changeset_undo)
			XCTAssert(orderedSet == orderedSet_a)
			
			let _ = try orderedSet.undo(changeset_redo)
			XCTAssert(orderedSet == orderedSet_b)
			
		} catch {
			XCTAssert(false, "Caught error: \(error)")
		}
	}
	
	// ====================================================================================================
	// MARK:- Fuzz
	// ====================================================================================================
	
	func test_undo_fuzz_everything() {
		
		let DEBUG_THIS_METHOD = false
	
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var orderedSet_a: ZDCOrderedSet<String>? = nil
			var orderedSet_b: ZDCOrderedSet<String>? = nil
			
			var orderedSet = ZDCOrderedSet<String>()
			
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
					orderedSet.insert(key)
				}
			}
			
			orderedSet.clearChangeTracking()
			orderedSet_a = orderedSet
			
			// Now make a random number of changes: [1 - 30)
			
			var changeCount: UInt!
			if (DEBUG_THIS_METHOD) {
				changeCount = 4
			} else {
				changeCount = 1 + UInt(arc4random_uniform(UInt32(29)))
			}
			
			for _ in 0 ..< changeCount {
				
				let random = arc4random_uniform(UInt32(3))
				
				if (random == 0)
				{
					// Add an item
					
					let key = self.randomLetters(8)
					
					if (DEBUG_THIS_METHOD) {
						print("insert: \(key)")
					}
					orderedSet.insert(key)
				}
				else if (random == 1)
				{
					// Remove an item
	
					let idx = Int(arc4random_uniform(UInt32(orderedSet.count)))
					
					if (DEBUG_THIS_METHOD) {
						print("remove(at: \(idx)): \(orderedSet[idx])")
					}
					if orderedSet.count > 0 {
						orderedSet.remove(at: idx)
					}
				}
				else
				{
					// Move an item
					
					let oldIdx = Int(arc4random_uniform(UInt32(orderedSet.count)))
					let newIdx = Int(arc4random_uniform(UInt32(orderedSet.count)))
					
					if (DEBUG_THIS_METHOD) {
						print("move(from: \(oldIdx) to: \(newIdx)")
					}
					if orderedSet.count > 0 {
						orderedSet.move(fromIndex: oldIdx, toIndex: newIdx)
					}
				}
			}
			
			let changeset_undo = orderedSet.changeset() ?? Dictionary()
			orderedSet_b = orderedSet
			
			do {
				let changeset_redo = try orderedSet.undo(changeset_undo) // a <- b
				if DEBUG_THIS_METHOD && (orderedSet != orderedSet_a) {
					print("It's going to FAIL")
				}
				XCTAssert(orderedSet == orderedSet_a)
				
				let _ = try orderedSet.undo(changeset_redo) // a -> b
				if DEBUG_THIS_METHOD && (orderedSet != orderedSet_b) {
					print("It's going to FAIL")
				}
				XCTAssert(orderedSet == orderedSet_b)
			
			} catch {
				print("Threw error: \(error)")
				XCTAssert(false)
			}
			
			if (DEBUG_THIS_METHOD) {
				print("-------------------------------------------------")
			}
		}}
	}
	
	func test_import_fuzz_everything() {
		
		let DEBUG_THIS_METHOD = false
		
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var orderedSet_a: ZDCOrderedSet<String>? = nil
			var orderedSet_b: ZDCOrderedSet<String>? = nil
			
			var orderedSet = ZDCOrderedSet<String>()
			var changesets: [ZDCChangeset] = []
			
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
					orderedSet.insert(key)
				}
			}
			
			orderedSet.clearChangeTracking()
			orderedSet_a = orderedSet
			
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
					
					let random = arc4random_uniform(UInt32(3))
					
					if (random == 0)
					{
						// Add an item
						
						let key = self.randomLetters(8)
						
						if DEBUG_THIS_METHOD {
							print("insert \(key)")
						}
						orderedSet.insert(key)
					}
					else if (random == 1)
					{
						// Remove an item
						
						let idx = Int(arc4random_uniform(UInt32(orderedSet.count)))
						
						if DEBUG_THIS_METHOD {
							print("remove(at: \(idx)): \(orderedSet[idx])");
						}
						if orderedSet.count > 0 {
							orderedSet.remove(at: idx)
						}
					}
					else
					{
						// Move an item
						
						let oldIdx = Int(arc4random_uniform(UInt32(orderedSet.count)))
						let newIdx = Int(arc4random_uniform(UInt32(orderedSet.count)))
						
						if DEBUG_THIS_METHOD {
							print("move(fromIndex: \(oldIdx), toIndex: \(newIdx)")
						}
						if orderedSet.count > 0 {
							orderedSet.move(fromIndex: oldIdx, toIndex: newIdx)
						}
					}
				}
				
				changesets.append(orderedSet.changeset() ?? Dictionary())
				
				if DEBUG_THIS_METHOD {
					print("********************")
				}
			}
			
			orderedSet_b = orderedSet
			
			do {
				
				try orderedSet.importChangesets(changesets)
				XCTAssert(orderedSet == orderedSet_b)
				
				let changeset_merged = orderedSet.changeset() ?? Dictionary()
				
				let changeset_redo = try orderedSet.undo(changeset_merged)
				if DEBUG_THIS_METHOD && (orderedSet != orderedSet_a) {
					print("It's going to FAIL")
				}
				XCTAssert(orderedSet == orderedSet_a)
				
				let _ = try orderedSet.undo(changeset_redo)
				if DEBUG_THIS_METHOD && (orderedSet != orderedSet_b) {
					print("It's going to FAIL")
				}
				XCTAssert(orderedSet == orderedSet_b)
			
			} catch {
				print("Threw error: \(error)")
				XCTAssert(false)
			}
			
			if (DEBUG_THIS_METHOD) {
				print("-------------------------------------------------")
			}
		}}
	}
	
	func test_merge_fuzz_everything() {
		
		let DEBUG_THIS_METHOD = false
		
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var orderedSet = ZDCOrderedSet<String>()
			var changesets: [ZDCChangeset] = []
			
			// Start with an object that has a random number of objects [20 - 30)
			do {
				
				var startCount: Int!
				if DEBUG_THIS_METHOD {
					startCount = 5
				} else {
					startCount = 20 + Int(arc4random_uniform(UInt32(10)))
				}
				
				for _ in 0 ..< startCount {
					
					let key = self.randomLetters(8)
					orderedSet.insert(key)
				}
			}
			
			orderedSet.clearChangeTracking()
			var orderedSet_cloud = orderedSet
			
			if DEBUG_THIS_METHOD {
				print("Start: \(orderedSet.rawOrder)")
				print("********************")
			}
			
			// Make a random number of changesets: [1 - 10)
			
			var changesetCount: Int!
			if DEBUG_THIS_METHOD {
				changesetCount = 2
			} else {
				changesetCount = 1 + Int(arc4random_uniform(UInt32(9)))
			}
			
			for _ in 0 ..< changesetCount {
				
				// Make a random number of changes (to dict): [1 - 30)
				
				var changeCount: Int!
				if DEBUG_THIS_METHOD {
					changeCount = 2
				} else {
					changeCount = 1 + Int(arc4random_uniform(UInt32(29)))
				}
				
				for _ in 0 ..< changeCount {
					
					let random = arc4random_uniform(UInt32(3))
					
					if (random == 0)
					{
						// Add an item
						
						let key = self.randomLetters(8)
						
						if DEBUG_THIS_METHOD {
							print("local: inert: \(key)")
						}
						orderedSet.insert(key)
					}
					else if (random == 1)
					{
						// Remove an item
						
						let idx = Int(arc4random_uniform(UInt32(orderedSet.count)))
						
						if DEBUG_THIS_METHOD {
							print("local: remove(at: \(idx)): \(orderedSet[idx])")
						}
						if orderedSet.count > 0 {
							orderedSet.remove(at: idx)
						}
					}
					else
					{
						// Move an item
						
						let oldIdx = Int(arc4random_uniform(UInt32(orderedSet.count)))
						let newIdx = Int(arc4random_uniform(UInt32(orderedSet.count)))
						
						if DEBUG_THIS_METHOD {
							print("local: move(fromIndex: \(oldIdx), toIndex: \(newIdx))");
						}
						if orderedSet.count > 0 {
							orderedSet.move(fromIndex: oldIdx, toIndex: newIdx)
						}
					}
				}
				
				changesets.append(orderedSet.changeset() ?? Dictionary())
				
				if DEBUG_THIS_METHOD {
					print("********************")
				}
			}
	
			do {
				// Make a random number of changes (to dict_cloud): [1 - 30)
				
				var changeCount: Int!
				if DEBUG_THIS_METHOD {
					changeCount = 2
				} else {
					changeCount = 1 + Int(arc4random_uniform(UInt32(29)))
				}
				
				for _ in 0 ..< changeCount {
					
					let random = arc4random_uniform(UInt32(3))
					
					if (random == 0)
					{
						// Add an item
						
						let key = self.randomLetters(8)
						
						if DEBUG_THIS_METHOD {
							print("cloud: insert: \(key)")
						}
						orderedSet_cloud.insert(key)
					}
					else if (random == 1)
					{
						// Remove an item
						
						let idx = Int(arc4random_uniform(UInt32(orderedSet_cloud.count)))
						
						if DEBUG_THIS_METHOD {
							print("cloud: remove(at: \(idx)): \(orderedSet_cloud[idx])")
						}
						if orderedSet_cloud.count > 0 {
							orderedSet_cloud.remove(at: idx)
						}
					}
					else
					{
						// Move an item
						
						let oldIdx = Int(arc4random_uniform(UInt32(orderedSet_cloud.count)))
						let newIdx = Int(arc4random_uniform(UInt32(orderedSet_cloud.count)))
						
						if DEBUG_THIS_METHOD {
							print("cloud: move(fromIndex: \(oldIdx), toIndex: \(newIdx))");
						}
						if orderedSet_cloud.count > 0 {
							orderedSet_cloud.move(fromIndex: oldIdx, toIndex: newIdx)
						}
					}
				}
			}
			
			if DEBUG_THIS_METHOD {
				print("********************")
			}
			
			let orderedSet_preMerge = orderedSet
			
			do {
				let changeset_redo = try orderedSet.merge(cloudVersion: orderedSet_cloud, pendingChangesets: changesets)
				
				let _ = try orderedSet.undo(changeset_redo)
				
				if DEBUG_THIS_METHOD && (orderedSet != orderedSet_preMerge) {
					print("It's going to FAIL")
				}
				XCTAssert(orderedSet == orderedSet_preMerge)
			
			} catch {
				print("Threw error: \(error)")
				XCTAssert(false)
			}
			
			if DEBUG_THIS_METHOD {
				print("-------------------------------------------------")
			}
		}}
	}
	
	// ====================================================================================================
	// MARK:- Merge - Simple
	// ====================================================================================================
	
	func test_simpleMerge_1() {
		
		var changesets: [ZDCChangeset] = []
		
		var local = ZDCOrderedSet<String>()
		local.insert("alice")
		local.insert("bob")
		
		local.clearChangeTracking()
		var cloud = local
	
		do { // local changes
		
			local.remove("alice") // -alice
			local.insert("carol") // +carol
			
			changesets.append(local.changeset() ?? Dictionary())
		}
		
		do { // cloud changes
			
			cloud.remove("bob")   // -bob
			cloud.insert("dave")  // +dave
		}
	
		do {
			let _ = try local.merge(cloudVersion: cloud, pendingChangesets: changesets)
			
			XCTAssert(!local.contains("alice"))
			XCTAssert(!local.contains("bob"))
			
			XCTAssert(local.contains("carol"))
			XCTAssert(local.contains("dave"))
			
		} catch {
			print("Threw error: \(error)")
			XCTAssert(false)
		}
	}
	
	func test_simpleMerge_2() {
		
		var changesets: [ZDCChangeset] = []
		
		var local = ZDCOrderedSet<String>()
		local.insert("alice")
		local.insert("bob")
		
		local.clearChangeTracking()
		var cloud = local
		
		do { // local changes
		
			local.remove("alice") // -alice
			local.insert("carol") // +carol
			
			changesets.append(local.changeset() ?? Dictionary())
		}
		
		do { // cloud changes
		
			cloud.remove("alice") // -alice
			cloud.remove("bob")   // -bob
			cloud.insert("dave")  // +dave
			cloud.insert("emily") // +emily
		}
		
		do {
			let _ = try local.merge(cloudVersion: cloud, pendingChangesets: changesets)
			
			XCTAssert(!local.contains("alice"))
			XCTAssert(!local.contains("bob"))
			
			XCTAssert(local.contains("carol"))
			XCTAssert(local.contains("dave"))
			XCTAssert(local.contains("emily"))
			
		} catch {
			print("Threw error: \(error)")
			XCTAssert(false)
		}
	}
	
	func test_simpleMerge_3() {
		
		var changesets: [ZDCChangeset] = []
		
		var local = ZDCOrderedSet<String>()
		local.insert("alice")
		
		local.clearChangeTracking()
		var cloud = local
		
		do { // local changes
		
			local.insert("bob") // +bob
			
			changesets.append(local.changeset() ?? Dictionary())
		}
		
		do { // cloud changes
		
			cloud.insert("carol") // +carol
			cloud.remove("alice") // -alice
			cloud.insert("dave")  // +dave
		}
	
		do {
			let _ = try local.merge(cloudVersion: cloud, pendingChangesets: changesets)
			
			XCTAssert(!local.contains("alice"))
			
			XCTAssert(local.contains("bob"))
			XCTAssert(local.contains("carol"))
			XCTAssert(local.contains("dave"))
			
		} catch {
			print("Threw error: \(error)")
			XCTAssert(false)
		}
	}
	
	func test_simpleMerge_4() {
		
		var changesets: [ZDCChangeset] = []
		
		var local = ZDCOrderedSet<String>()
		local.insert("alice")
		
		local.clearChangeTracking()
		var cloud = local
	
		do { // local changes
		
			local.insert("bob")
			
			changesets.append(local.changeset() ?? Dictionary())
		}
		
		do { // cloud changes
		
			cloud.remove("alice")
			cloud.insert("carol")
		}
		
		do {
			let _ = try local.merge(cloudVersion: cloud, pendingChangesets: changesets)
		
			XCTAssert(!local.contains("alice"))
		
			XCTAssert(local.contains("bob"))
			XCTAssert(local.contains("carol"))
		
		} catch {
			print("Threw error: \(error)")
			XCTAssert(false)
		}
	}
	
	func test_simpleMerge_5() {
		
		var changesets: [ZDCChangeset] = []
		
		var local = ZDCOrderedSet<String>()
		local.insert("alice")
		local.insert("bob")
		
		local.clearChangeTracking()
		var cloud = local
	
		do { // local changes
		
			local.remove("bob")
			local.insert("carol")
			
			changesets.append(local.changeset() ?? Dictionary())
		}
		
		do { // cloud changes
		
			cloud.remove("alice")
		}
		
		do {
			let _ = try local.merge(cloudVersion: cloud, pendingChangesets: changesets)
			
			XCTAssert(!local.contains("alice"))
			XCTAssert(!local.contains("bob"))
			
			XCTAssert(local.contains("carol"))
			
		} catch {
			print("Threw error: \(error)")
			XCTAssert(false)
		}
	}
	
	// ====================================================================================================
	// MARK:- Codable
	// ====================================================================================================

	func test_codable_1() {
		
		let type = ZDCOrderedSet<String>.self
		
		var set = type.init()
		set.insert("goats")
		set.insert("sheep")
		
		do {
			let encoder = JSONEncoder()
			let encoded = try encoder.encode(set)
			
			let decoder = JSONDecoder()
			let decoded = try decoder.decode(type, from: encoded)
			
			XCTAssert(set == decoded)
			
		} catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_codable_2() {
		
		// A ZDCOrderedSet should be decodable from a standard JSON array.
		
		let json_str = """
		[
		  "apple",
		  "banana"
		]
		"""
		let json_data = json_str.data(using: .utf8)!
		
		do {
			let decoder = JSONDecoder()
			let _ = try decoder.decode(ZDCOrderedSet<String>.self, from: json_data)
			
		} catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
}
