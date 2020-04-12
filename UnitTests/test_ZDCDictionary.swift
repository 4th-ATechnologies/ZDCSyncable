/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

import XCTest
import ZDCSyncable

class test_ZDCDictionary: XCTestCase {
	
	func randomLetters(_ length: UInt) -> String {
		
		let alphabet = "abcdefghijklmnopqrstuvwxyz"
		return String((0..<length).map{ _ in alphabet.randomElement()! })
	}
	
	// ====================================================================================================
	// MARK:- Basic
	// ====================================================================================================
	
	func test_undo_basic_1() {
		
		var dict_a: ZDCDictionary<String, String>? = nil
		var dict_b: ZDCDictionary<String, String>? = nil
		
		// Basic undo/redo functionality.
		//
		// - add
		
		var dict = ZDCDictionary<String, String>()
		
		// Empty dictionary will be starting state
		//
		dict_a = dict
		
		dict["cow"] = "moo"
		dict["duck"] = "quack"
		
		XCTAssert(dict.count == 2);
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict
		
		do {
			let changeset_redo = try dict.undo(changeset_undo)
			XCTAssert(dict == dict_a)
			
			let _ = try dict.undo(changeset_redo)
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_undo_basic_2() {
		
		var dict_a: ZDCDictionary<String, String>? = nil
		var dict_b: ZDCDictionary<String, String>? = nil
		
		// Basic undo/redo functionality.
		//
		// - remove
		
		var dict = ZDCDictionary<String, String>()
		
		dict["cow"] = "moo"
		dict["duck"] = "quack"
		
		dict.clearChangeTracking()
		dict_a = dict
		
		dict["cow"] = nil
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict
		
		do {
			let changeset_redo = try dict.undo(changeset_undo)
			XCTAssert(dict == dict_a)
			
			let _ = try dict.undo(changeset_redo)
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_undo_basic_3() {
		
		var dict_a: ZDCDictionary<String, String>? = nil
		var dict_b: ZDCDictionary<String, String>? = nil
		
		// Basic undo/redo functionality.
		//
		// - modify
		
		var dict = ZDCDictionary<String, String>()
		
		dict["cow"] = "moo"
		dict["duck"] = "quack"
		
		dict.clearChangeTracking()
		dict_a = dict
		
		dict["cow"] = "mooo"
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict
		
		do {
			let changeset_redo = try dict.undo(changeset_undo)
			XCTAssert(dict == dict_a)
			
			let _ = try dict.undo(changeset_redo)
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	// ====================================================================================================
	// MARK:- Fuzz
	// ====================================================================================================

	func test_undo_fuzz_everything() {
		
		let DEBUG_THIS_METHOD = false
		
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var dict_a: ZDCDictionary<String, String>? = nil
			var dict_b: ZDCDictionary<String, String>? = nil
			
			var dict = ZDCDictionary<String, String>()
			
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
					dict[key] = self.randomLetters(4)
				}
			}
			
			dict.clearChangeTracking()
			dict_a = dict
			
			// Now make a random number of changes: [1 - 30)
			
			var changeCount: Int!
			if DEBUG_THIS_METHOD {
				changeCount = 4
			} else {
				changeCount = 1 + Int(arc4random_uniform(UInt32(29)))
			}
			
			for _ in 0 ..< changeCount {
				
				let random = arc4random_uniform(UInt32(3))
				
				if (random == 0)
				{
					// Add an item
					
					let key = self.randomLetters(8)
					let value = self.randomLetters(4)
					
					if DEBUG_THIS_METHOD {
						print("add: key(\(key)) = \(value)")
					}
					dict[key] = value
				}
				else if (random == 1)
				{
					// Remove an item
					
					if let (key, _) = dict.randomElement() {
						
						if DEBUG_THIS_METHOD {
							print("remove: key(\(key))")
						}
						dict[key] = nil
					}
				}
				else
				{
					// Modify an item
					
					if let (key, _) = dict.randomElement() {
						
						let newValue = self.randomLetters(4)
						
						if DEBUG_THIS_METHOD {
							print("modify: key(\(key)) = \(newValue)")
						}
						dict[key] = newValue
					}
				}
			}
			
			let changeset_undo = dict.changeset() ?? Dictionary()
			dict_b = dict
			
			do {
				let changeset_redo = try dict.undo(changeset_undo) // a <- b
				
				if DEBUG_THIS_METHOD && (dict != dict_a) {
					print("It's going to FAIL")
				}
				XCTAssert(dict == dict_a)
	
				let _ = try dict.undo(changeset_redo) // a -> b
				
				if DEBUG_THIS_METHOD && (dict != dict_b) {
					print("It's going to FAIL")
				}
				XCTAssert(dict == dict_b)
			}
			catch {
				XCTAssert(false)
				print("Threw error: \(error)")
			}
			
			if DEBUG_THIS_METHOD {
				print("-------------------------------------------------")
			}
		}}
	}

	func test_import_fuzz_everything() {
		
		let DEBUG_THIS_METHOD = false
		
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var changesets = Array<Dictionary<String, Any>>()
			
			var dict_a: ZDCDictionary<String, String>? = nil
			var dict_b: ZDCDictionary<String, String>? = nil
			
			var dict = ZDCDictionary<String, String>()
				
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
					dict[key] = ""
				}
			}
			
			dict.clearChangeTracking()
			dict_a = dict
			
			// Make a random number of changesets: [1 - 10)
			
			var changesetCount: Int!
			if DEBUG_THIS_METHOD {
				changesetCount = 2
			} else {
				changesetCount = 1 + Int(arc4random_uniform(UInt32(9)))
			}
			
			for _ in 0 ..< changesetCount {
				
				// Make a random number of changes: [1 - 30)
				
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
						let value = self.randomLetters(4)
						
						if DEBUG_THIS_METHOD {
							print("add: key(\(key)) = \(value)")
						}
						dict[key] = value
					}
					else if (random == 1)
					{
						// Remove an item
						
						if let (key, _) = dict.randomElement() {
							
							if DEBUG_THIS_METHOD {
								print("remove: key(\(key))")
							}
							dict[key] = nil
						}
					}
					else
					{
						// Modify an item
						
						if let (key, _) = dict.randomElement() {
							
							let newValue = self.randomLetters(4)
							
							if DEBUG_THIS_METHOD {
								print("modify: key(\(key)) = \(newValue)")
							}
							dict[key] = newValue
						}
					}
				}
				
				changesets.append(dict.changeset() ?? Dictionary())
				
				if DEBUG_THIS_METHOD {
					print("********************")
				}
			}
			
			dict_b = dict
			
			do {
				try dict.importChangesets(changesets)
				XCTAssert(dict == dict_b)
				
				let changeset_merged = dict.changeset() ?? Dictionary()
				
				let changeset_redo = try dict.undo(changeset_merged)
				if DEBUG_THIS_METHOD && (dict != dict_a) {
					print("It's going to FAIL")
				}
				XCTAssert(dict == dict_a)
				
				let _ = try dict.undo(changeset_redo)
				if DEBUG_THIS_METHOD && (dict != dict_b) {
					print("It's going to FAIL")
				}
				XCTAssert(dict == dict_b)
			}
			catch {
				XCTAssert(false)
				print("Threw error: \(error)")
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
		
		var changesets = Array<Dictionary<String, Any>>()
		
		var local = ZDCDictionary<String, Int>()
		local["alice"] = 1
		local["bob"] = 1
		
		local.clearChangeTracking()
		var cloud = local
		
		do { // local changes
			
			local["alice"] = 2
			
			changesets.append(local.changeset() ?? Dictionary())
		}
		
		do { // cloud changes
			
			cloud["bob"] = 2
		}
		
		do {
			let _ = try local.merge(cloudVersion: cloud, pendingChangesets: changesets)
			
			XCTAssert(local["alice"] == 2)
			XCTAssert(local["bob"] == 2)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_simpleMerge_2() {
		
		var changesets = Array<Dictionary<String, Any>>()
		
		var local = ZDCDictionary<String, Int>()
		local["alice"] = 1
		local["bob"] = 1
		
		local.clearChangeTracking()
		var cloud = local
		
		do { // local changes
			
			local["alice"] = 2
			
			changesets.append(local.changeset() ?? Dictionary())
		}
		
		do { // cloud changes
			
			cloud["alice"] = 3
			cloud["bob"] = 2
		}
		
		do {
			let _ = try local.merge(cloudVersion: cloud, pendingChangesets: changesets)
			
			XCTAssert(local["alice"] == 3)
			XCTAssert(local["bob"] == 2)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_simpleMerge_3() {
		
		var changesets = Array<Dictionary<String, Any>>()
		
		var local = ZDCDictionary<String, Int>()
		local["bob"] = 1
		
		local.clearChangeTracking()
		var cloud = local
		
		do { // local changes
			
			local["alice"] = 1
			
			changesets.append(local.changeset() ?? Dictionary())
		}
		
		do { // cloud changes
			
			cloud["alice"] = 2
			cloud["bob"] = 2
		}
	
		do {
			let _ = try local.merge(cloudVersion: cloud, pendingChangesets: changesets)
			
			XCTAssert(local["alice"] == 2)
			XCTAssert(local["bob"] == 2)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_simpleMerge_4() {
		
		var changesets = Array<Dictionary<String, Any>>()
		
		var local = ZDCDictionary<String, Int>()
		local["bob"] = 1
		
		local.clearChangeTracking()
		var cloud = local
		
		do { // local changes
			
			local["alice"] = 1
			
			changesets.append(local.changeset() ?? Dictionary())
		}
		
		do { // cloud changes
			
			cloud["bob"] = 2
		}
		
		do {
			let _ = try local.merge(cloudVersion: cloud, pendingChangesets: changesets)
			
			XCTAssert(local["alice"] == 1)
			XCTAssert(local["bob"] == 2)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_simpleMerge_5() {
		
		var changesets = Array<Dictionary<String, Any>>()
		
		var local = ZDCDictionary<String, Int>()
		local["alice"] = 1
		local["bob"] = 1
		
		local.clearChangeTracking()
		var cloud = local
		
		do { // local changes
			
			local["bob"] = 2
			
			changesets.append(local.changeset() ?? Dictionary())
		}
		
		do { // cloud changes
			
			cloud["alice"] = nil
		}
		
		do {
			let _ = try local.merge(cloudVersion: cloud, pendingChangesets: changesets)
			
			XCTAssert(local["alice"] == nil)
			XCTAssert(local["bob"] == 2)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	// ====================================================================================================
	// MARK:- Complex
	// ====================================================================================================

	func test_complexMerge_1() {
		
		var changesets = Array<Dictionary<String, Any>>()

		var local = ZDCDictionary<String, ZDCDictionary<String, String>>()
		local["pets"] = ZDCDictionary<String, String>()
		local["farm"] = ZDCDictionary<String, String>()
		local["pets"]?["dog"] = "bark"

		local.clearChangeTracking()
		XCTAssert(local.hasChanges == false)
		
		var cloud = local

		do { // local changes

			local["pets"]?["cat"] = "meow"
			local["farm"]?["cow"] = "moo"

			changesets.append(local.changeset() ?? Dictionary())
		}

		do { // cloud changes

			cloud["farm"]?["horse"] = "nay"
			cloud["farm"]?["duck"] = "quack"
		}

		XCTAssert(local["farm"]?["horse"] == nil)

		do {
			let _ = try local.merge(cloudVersion: cloud, pendingChangesets: changesets)

			XCTAssert(local["pets"]?["dog"] == "bark")
			XCTAssert(local["pets"]?["cat"] == "meow")

			XCTAssert(local["farm"]?["cow"] == "moo")
			XCTAssert(local["farm"]?["horse"] == "nay")
			XCTAssert(local["farm"]?["duck"] == "quack")
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

}
