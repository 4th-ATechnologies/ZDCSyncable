/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

import XCTest
import ZDCSyncable

class test_ZDCOrderedDictionary: XCTestCase {

	func randomLetters(_ length: UInt) -> String {
		
		let alphabet = "abcdefghijklmnopqrstuvwxyz"
		return String((0..<length).map{ _ in alphabet.randomElement()! })
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK:- Subclass
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	func test_subclass() {
		
		// Basic YES/NO change tracking.
		//
		// If we make changes to the dict, does [dict hasChanges] reflect those changes ?
		// i.e. make sure we didn't screw up the subclass functionality.
		
		let dict = ZDCOrderedDictionary<String, String>()
		
		dict["cow"] = "moo"
		dict["duck"] = "quack"
		
		XCTAssert(dict.hasChanges == true)
		dict.clearChangeTracking()
		XCTAssert(dict.hasChanges == false)
		
		dict["cow"] = "mooooooooo"
		
		XCTAssert(dict.hasChanges == true);
		dict.clearChangeTracking()
		XCTAssert(dict.hasChanges == false)
		
		dict.insert("bark", forKey: "dog", atIndex: 1)
		
		XCTAssert(dict.hasChanges == true)
		dict.clearChangeTracking()
		XCTAssert(dict.hasChanges == false)
		
		dict.move(fromIndex:0, toIndex:2)
		
		XCTAssert(dict.hasChanges == true)
		dict.clearChangeTracking()
		XCTAssert(dict.hasChanges == false)
		
		XCTAssert(dict.keyAtIndex(0) == "dog", "dict[0] = \( dict.keyAtIndex(0) ?? "nil" )")
		XCTAssert(dict.keyAtIndex(1) == "duck")
		XCTAssert(dict.keyAtIndex(2) == "cow")
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK:- Undo: Basic
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	func test_undo_basic_1() {
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Can we undo/redo basic `setObject:forKey:` functionality (for newly inserted items) ?
		
		let dict = ZDCOrderedDictionary<String, String>()
		
		// Empty dictionary will be starting state
		//
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		dict["cow"] = "moo"
		dict["duck"] = "quack"
		
		XCTAssert(dict.count == 2);
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
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
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Can we undo/redo basic `setObject:forKey:` functionality (for updated items) ?
		
		let dict = ZDCOrderedDictionary<String, String>()
		
		dict["cow"] = "moo"
		dict["duck"] = "quack"
		
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		dict["cow"] = "mooooooo"
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
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
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Can we undo/redo basic `removeObjectForKey:` functionality ?
		
		let dict = ZDCOrderedDictionary<String, String>()
		
		dict["cow"] = "moo"
		dict["duck"] = "quack"
		
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		dict["cow"] = nil
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
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
	
	func test_undo_basic_4() {
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Can we undo/redo basic `moveObjectAtIndex:toIndex:` functionality ?
		
		let dict = ZDCOrderedDictionary<String, String>()
		
		dict["cow"] = "moo"
		dict["duck"] = "quack"
		
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		dict.move(fromIndex: 0, toIndex: 1)
		
		XCTAssert(dict.keyAtIndex(0) == "duck")
		XCTAssert(dict.keyAtIndex(1) == "cow")
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
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
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Undo: Combo: add + X
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	func test_undo_add_add() {
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Add + Add
		
		let dict = ZDCOrderedDictionary<String, String>()
		
		dict["cow"] = "moo"
		dict["duck"] = "quack"
	
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		dict["dog"] = "bark"
		dict["cat"] = "meow"
		
		XCTAssert(dict.count == 4)
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			let changeset_redo = try dict.undo(changeset_undo) // a <- b
			XCTAssert(dict == dict_a)
			
			let _ = try dict.undo(changeset_redo) // a -> b
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_undo_add_remove() {
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Add + Remove
		
		let dict = ZDCOrderedDictionary<String, String>()
		
		dict["cow"] = "moo"
		dict["duck"] = "quack"
		
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		dict["dog"] = "bark"
		dict["cow"] = nil
		
		XCTAssert(dict.count == 2);
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			let changeset_redo = try dict.undo(changeset_undo) // a <- b
			XCTAssert(dict == dict_a)
			
			let _ = try dict.undo(changeset_redo) // a -> b
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_undo_add_insert() {
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Add + Insert
		
		let dict = ZDCOrderedDictionary<String, String>()
		
		dict["cow"] = "moo"
		dict["duck"] = "quack"
		
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		dict["dog"] = "bark"
		dict.insert("meow", forKey: "cat", atIndex: 0)
		
		XCTAssert(dict.count == 4);
		XCTAssert(dict.keyAtIndex(0) == "cat")
		XCTAssert(dict.keyAtIndex(1) == "cow")
		XCTAssert(dict.keyAtIndex(2) == "duck")
		XCTAssert(dict.keyAtIndex(3) == "dog")
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			let changeset_redo = try dict.undo(changeset_undo) // a <- b
			XCTAssert(dict == dict_a)
			
			let _ = try dict.undo(changeset_redo) // a -> b
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_undo_add_move() {
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Add + Move
		
		let dict = ZDCOrderedDictionary<String, String>()
		
		dict["cow"] = "moo"
		dict["duck"] = "quack"
		
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		dict["dog"] = "bark"
		dict.move(fromIndex: 0, toIndex: 1)
		
		XCTAssert(dict.count == 3);
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			let changeset_redo = try dict.undo(changeset_undo) // a <- b
			XCTAssert(dict == dict_a)
			
			let _ = try dict.undo(changeset_redo) // a -> b
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Undo: Combo: remove + X
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	func test_undo_remove_add() {
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Remove + Add
		
		let dict = ZDCOrderedDictionary<String, String>()
		
		dict["cow"] = "moo"
		dict["duck"] = "quack"
		
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		dict["cow"] = nil
		dict["dog"] = "bark"
		
		XCTAssert(dict.count == 2)
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			let changeset_redo = try dict.undo(changeset_undo) // a <- b
			XCTAssert(dict == dict_a)
			
			let _ = try dict.undo(changeset_redo) // a -> b
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_undo_remove_remove() {
	
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Remove + Remove
		
		let dict = ZDCOrderedDictionary<String, String>()
		
		dict["cow"] = "moo"
		dict["duck"] = "quack"
		
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		dict["cow"] = nil
		dict["duck"] = nil
		
		XCTAssert(dict.count == 0);
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			let changeset_redo = try dict.undo(changeset_undo) // a <- b
			XCTAssert(dict == dict_a)
			
			let _ = try dict.undo(changeset_redo) // a -> b
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_undo_remove_insert() {
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Remove + Insert
		
		let dict = ZDCOrderedDictionary<String, String>()
		
		dict["cow"] = "moo"
		dict["duck"] = "quack"
		
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		dict["cow"] = nil
		dict.insert("bark", forKey: "dog", atIndex: 0)
		
		XCTAssert(dict.count == 2);
		XCTAssert(dict.keyAtIndex(0) == "dog")
		XCTAssert(dict.keyAtIndex(1) == "duck")
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			let changeset_redo = try dict.undo(changeset_undo) // a <- b
			XCTAssert(dict == dict_a)
			
			let _ = try dict.undo(changeset_redo) // a -> b
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_undo_remove_move() {
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Remove + Move
		
		let dict = ZDCOrderedDictionary<String, String>()
		
		dict["cow"] = "moo"
		dict["duck"] = "quack"
		dict["dog"] = "bark"
		
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		dict["cow"] = nil
		dict.move(fromIndex: 0, toIndex: 1)
		
		XCTAssert(dict.count == 2);
		XCTAssert(dict.keyAtIndex(0) == "dog")
		XCTAssert(dict.keyAtIndex(1) == "duck")
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			let changeset_redo = try dict.undo(changeset_undo) // a <- b
			XCTAssert(dict == dict_a)
			
			let _ = try dict.undo(changeset_redo) // a -> b
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK:- Undo: Combo: insert + X
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	func test_undo_insert_add() {
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Insert + Add
		
		let dict = ZDCOrderedDictionary<String, String>()
		
		dict["cow"] = "moo"
		dict["duck"] = "quack"
		
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		dict.insert("bark", forKey: "dog", atIndex: 1)
		dict["cat"] = "meow"
		
		XCTAssert(dict.count == 4);
		XCTAssert(dict.keyAtIndex(0) == "cow")
		XCTAssert(dict.keyAtIndex(1) == "dog")
		XCTAssert(dict.keyAtIndex(2) == "duck")
		XCTAssert(dict.keyAtIndex(3) == "cat")
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			let changeset_redo = try dict.undo(changeset_undo) // a <- b
			XCTAssert(dict == dict_a)
			
			let _ = try dict.undo(changeset_redo) // a -> b
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_undo_insert_remove() {
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Insert + Remove
		
		let dict = ZDCOrderedDictionary<String, String>()
		
		dict["cow"] = "moo"
		dict["duck"] = "quack"
		
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		dict.insert("bark", forKey: "dog", atIndex: 1)
		dict["cow"] = nil
		
		XCTAssert(dict.count == 2);
		XCTAssert(dict.keyAtIndex(0) == "dog")
		XCTAssert(dict.keyAtIndex(1) == "duck")
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			let changeset_redo = try dict.undo(changeset_undo) // a <- b
			XCTAssert(dict == dict_a);
			
			let _ = try dict.undo(changeset_redo) // a -> b
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_undo_insert_insert() {
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Insert + Insert
		
		let dict = ZDCOrderedDictionary<String, String>()
		
		dict["cow"] = "moo"
		dict["duck"] = "quack"
		
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		dict.insert("bark", forKey: "dog", atIndex: 1)
		dict.insert("meow", forKey: "cat", atIndex: 1)
		
		XCTAssert(dict.count == 4);
		XCTAssert(dict.keyAtIndex(0) == "cow")
		XCTAssert(dict.keyAtIndex(1) == "cat")
		XCTAssert(dict.keyAtIndex(2) == "dog")
		XCTAssert(dict.keyAtIndex(3) == "duck")
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			let changeset_redo = try dict.undo(changeset_undo) // a <- b
			XCTAssert(dict == dict_a)
			
			let _ = try dict.undo(changeset_redo) // a -> b
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_undo_insert_move_a() {
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Insert + Move
		
		let dict = ZDCOrderedDictionary<String, String>()
		
		dict["cow"] = "moo"
		dict["duck"] = "quack"
		
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		dict.insert("bark", forKey: "dog", atIndex: 1)
		dict.move(fromIndex: 2, toIndex: 0)
		
		XCTAssert(dict.count == 3);
		XCTAssert(dict.keyAtIndex(0) == "duck")
		XCTAssert(dict.keyAtIndex(1) == "cow")
		XCTAssert(dict.keyAtIndex(2) == "dog")
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			let changeset_redo = try dict.undo(changeset_undo) // a <- b
			XCTAssert(dict == dict_a)
			
			let _ = try dict.undo(changeset_redo) // a -> b
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_undo_insert_move_b() {
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Insert + Move
		
		let dict = ZDCOrderedDictionary<String, String>()
		
		dict["cow"] = "moo"
		dict["duck"] = "quack"
		
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		dict.insert("bark", forKey: "dog", atIndex: 1)
		dict.move(fromIndex: 0, toIndex: 2)
		
		XCTAssert(dict.count == 3);
		XCTAssert(dict.keyAtIndex(0) == "dog")
		XCTAssert(dict.keyAtIndex(1) == "duck")
		XCTAssert(dict.keyAtIndex(2) == "cow")
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			let changeset_redo = try dict.undo(changeset_undo) // a <- b
			XCTAssert(dict == dict_a)
			
			let _ = try dict.undo(changeset_redo) // a -> b
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK:- Undo: Combo: move + X
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	func test_undo_move_add() {
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Move + Add
		
		let dict = ZDCOrderedDictionary<String, String>()
		
		dict["cow"] = "moo"
		dict["duck"] = "quack"
		
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		dict.move(fromIndex: 0, toIndex: 1)
		dict["dog"] = "bark"
		
		XCTAssert(dict.count == 3);
		XCTAssert(dict.keyAtIndex(0) == "duck")
		XCTAssert(dict.keyAtIndex(1) == "cow")
		XCTAssert(dict.keyAtIndex(2) == "dog")
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			let changeset_redo = try dict.undo(changeset_undo ) // a <- b
			XCTAssert(dict == dict_a)
			
			let _ = try dict.undo(changeset_redo) // a -> b
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_undo_move_remove() {
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Move + Remove
		
		let dict = ZDCOrderedDictionary<String, String>()
		
		dict["cow"] = "moo"
		dict["duck"] = "quack"
		
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		dict.move(fromIndex: 0, toIndex: 1)
		dict["cow"] = nil;
		
		XCTAssert(dict.count == 1);
		XCTAssert(dict.keyAtIndex(0) == "duck")
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			let changeset_redo = try dict.undo(changeset_undo ) // a <- b
			XCTAssert(dict == dict_a)
		
			let _ = try dict.undo(changeset_redo) // a -> b
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_undo_move_insert() {
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Move + Insert
		
		let dict = ZDCOrderedDictionary<String, String>()
		
		dict["cow"] = "moo"
		dict["duck"] = "quack"
		
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		dict.move(fromIndex: 0, toIndex: 1)
		dict.insert("bark", forKey: "dog", atIndex: 1)
		
		XCTAssert(dict.count == 3);
		XCTAssert(dict.keyAtIndex(0) == "duck")
		XCTAssert(dict.keyAtIndex(1) == "dog")
		XCTAssert(dict.keyAtIndex(2) == "cow")
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			let changeset_redo = try dict.undo(changeset_undo ) // a <- b
			XCTAssert(dict == dict_a)
			
			let _ = try dict.undo(changeset_redo) // a -> b
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_undo_move_move_a() {
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Move + Move
		
		let dict = ZDCOrderedDictionary<String, String>()
		
		dict["cow"] = "moo"
		dict["duck"] = "quack"
		
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		dict.move(fromIndex: 0, toIndex: 1)
		dict.move(fromIndex: 0, toIndex: 1)
		
		XCTAssert(dict.keyAtIndex(0) == "cow")
		XCTAssert(dict.keyAtIndex(1) == "duck")
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			let changeset_redo = try dict.undo(changeset_undo ) // a <- b
			XCTAssert(dict == dict_a)
			
			let _ = try dict.undo(changeset_redo) // a -> b
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_undo_move_move_b() {
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Move + Move
		
		let dict = ZDCOrderedDictionary<String, String>()
		
		dict["cow"] = "moo"
		dict["duck"] = "quack"
		dict["dog"] = "bark"
		dict["cat"] = "meow"
		
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		dict.move(fromIndex: 1, toIndex: 3)
		dict.move(fromIndex: 2, toIndex: 0)
		
		XCTAssert(dict.keyAtIndex(0) == "cat")
		XCTAssert(dict.keyAtIndex(1) == "cow")
		XCTAssert(dict.keyAtIndex(2) == "dog")
		XCTAssert(dict.keyAtIndex(3) == "duck")
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			let changeset_redo = try dict.undo(changeset_undo ) // a <- b
			XCTAssert(dict == dict_a)
			
			let _ = try dict.undo(changeset_redo) // a -> b
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_undo_move_move_c() {
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Move + Move
		
		let dict = ZDCOrderedDictionary<String, String>()
		
		dict["cow"] = "moo"
		dict["duck"] = "quack"
		dict["dog"] = "bark"
		dict["cat"] = "meow"
		
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		dict.move(fromIndex: 0, toIndex: 3)
		dict.move(fromIndex: 2, toIndex: 1)
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			let changeset_redo = try dict.undo(changeset_undo ) // a <- b
			XCTAssert(dict == dict_a)
			
			let _ = try dict.undo(changeset_redo) // a -> b
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_undo_move_move_d() {
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Move + Move
		
		let dict = ZDCOrderedDictionary<String, String>()
		
		dict["cow"] = "moo"
		dict["duck"] = "quack"
		dict["dog"] = "bark"
		dict["cat"] = "meow"
		
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		dict.move(fromIndex: 0, toIndex: 3)
		dict.move(fromIndex: 1, toIndex: 2)
		
		XCTAssert(dict.keyAtIndex(0) == "duck")
		XCTAssert(dict.keyAtIndex(1) == "cat")
		XCTAssert(dict.keyAtIndex(2) == "dog")
		XCTAssert(dict.keyAtIndex(3) == "cow")
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			let changeset_redo = try dict.undo(changeset_undo ) // a <- b
			XCTAssert(dict == dict_a)
			
			let _ = try dict.undo(changeset_redo) // a -> b
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK:- Undo: Previous Failures
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	func test_undo_failure_1() {
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		let dict = ZDCOrderedDictionary<String, String>()
		
		dict["rkij"] = ""
		dict["ihns"] = ""
		
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		dict["jtyi"] = ""
		dict.move(fromIndex: 1, toIndex: 0)
		dict.move(fromIndex: 2, toIndex: 0)
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			let changeset_redo = try dict.undo(changeset_undo) // a <- b
			XCTAssert(dict == dict_a)
			
			let _ = try dict.undo(changeset_redo) // a -> b
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_undo_failure_2() {
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		let dict = ZDCOrderedDictionary<String, String>()
		
		dict["tjwi"] = ""
		dict["nwgk"] = ""
		dict["igaz"] = ""
		dict["gmmv"] = ""
		dict["lefk"] = ""
		
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		dict["leyp"] = ""
		dict.move(fromIndex: 3, toIndex: 5)
		dict["uwka"] = ""
		dict.move(fromIndex: 1, toIndex: 6)
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			let changeset_redo = try dict.undo(changeset_undo) // a <- b
			XCTAssert(dict == dict_a)
			
			let _ = try dict.undo(changeset_redo) // a -> b
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_undo_failure_3() {
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		let dict = ZDCOrderedDictionary<String, String>()
		
		dict["tnjb"] = ""
		dict["xcyu"] = ""
		dict["gkmq"] = ""
		dict["hnkg"] = ""
		dict["paxy"] = ""
		
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		dict.move(fromIndex: 2, toIndex: 4)
		dict["xsny"] = ""
		dict["kzzh"] = ""
		dict.move(fromIndex: 5, toIndex: 6)
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			let changeset_redo = try dict.undo(changeset_undo) // a <- b
			XCTAssert(dict == dict_a)
			
			let _ = try dict.undo(changeset_redo) // a -> b
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_undo_failure_4() {
	
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		let dict = ZDCOrderedDictionary<String, String>()
		
		dict["glsr"] = ""
		dict["sefo"] = ""
		dict["vkca"] = ""
		dict["izle"] = ""
		dict["pggk"] = ""
		
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		dict["ezgd"] = ""
		dict["muua"] = ""
		dict["nfjt"] = ""
		dict.move(fromIndex: 7, toIndex: 6)
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			let changeset_redo = try dict.undo(changeset_undo) // a <- b
			XCTAssert(dict == dict_a)
			
			let _ = try dict.undo(changeset_redo) // a -> b
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_undo_failure_5() {
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		let dict = ZDCOrderedDictionary<String, String>()
		
		dict["tvma"] = ""
		dict["sgkp"] = ""
		dict["erum"] = ""
		dict["pkzi"] = ""
		dict["ytfx"] = ""
		
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		dict["tzrx"] = ""
		dict["ujvd"] = ""
		dict["pmnv"] = ""
		dict.move(fromIndex: 2, toIndex: 7)
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			let changeset_redo = try dict.undo(changeset_undo) // a <- b
			XCTAssert(dict == dict_a)
			
			let _ = try dict.undo(changeset_redo) // a -> b
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_undo_failure_6() {
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		let dict = ZDCOrderedDictionary<String, String>()
		
		dict["ldnw"] = ""
		dict["llxg"] = ""
		dict["ddbx"] = ""
		dict["axxj"] = ""
		dict["vicl"] = ""
		
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		dict.move(fromIndex: 2, toIndex: 4)
		dict.remove(at: 2)
		dict.move(fromIndex: 0, toIndex: 3)
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			let changeset_redo = try dict.undo(changeset_undo) // a <- b
			XCTAssert(dict == dict_a)
			
			let _ = try dict.undo(changeset_redo) // a -> b
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_undo_failure_7() {
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		let dict = ZDCOrderedDictionary<String, String>()
		
		dict["yqbe"] = ""
		dict["wznq"] = ""
		dict["riff"] = ""
		dict["xkvu"] = ""
		dict["qqlk"] = ""
		
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		dict["hqvm"] = ""
		dict["bjqv"] = ""
		dict.move(fromIndex: 5, toIndex: 3)
		dict.move(fromIndex: 6, toIndex: 2)
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			let changeset_redo = try dict.undo(changeset_undo) // a <- b
			XCTAssert(dict == dict_a)
			
			let _ = try dict.undo(changeset_redo) // a -> b
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_undo_failure_8() {
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		let dict = ZDCOrderedDictionary<String, String>()
		
		dict["ihba"] = ""
		dict["iduf"] = ""
		dict["yzgh"] = ""
		dict["bcso"] = ""
		dict["hdsv"] = ""
		
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		dict.move(fromIndex: 3, toIndex: 2)
		dict["oohq"] = ""
		dict.move(fromIndex: 5, toIndex: 0)
		dict.move(fromIndex: 4, toIndex: 0)
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			let changeset_redo = try dict.undo(changeset_undo) // a <- b
			XCTAssert(dict == dict_a)
			
			let _ = try dict.undo(changeset_redo) // a -> b
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_undo_failure_9() {
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		let dict = ZDCOrderedDictionary<String, String>()
		
		dict["oswt"] = ""
		dict["bony"] = ""
		dict["pxgf"] = ""
		dict["bclp"] = ""
		dict["zejw"] = ""
		
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		dict["hrtm"] = ""
		dict.remove(at: 4)
		dict.move(fromIndex: 1, toIndex: 4)
		dict.remove(at: 4)
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			let changeset_redo = try dict.undo(changeset_undo) // a <- b
			XCTAssert(dict == dict_a)
			
			let _ = try dict.undo(changeset_redo) // a -> b
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_undo_failure_10() {
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		let dict = ZDCOrderedDictionary<String, String>()
		
		dict["ydlj"] = ""
		dict["oruh"] = ""
		dict["iaye"] = ""
		dict["iunc"] = ""
		dict["scvk"] = ""
		
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		dict["ggek"] = ""
		dict.move(fromIndex: 3, toIndex: 5)
		dict.move(fromIndex: 3, toIndex: 1)
		dict.remove(at: 4)
		
		let changeset_undo = dict.changeset() ?? Dictionary()
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			let changeset_redo = try dict.undo(changeset_undo) // a <- b
			XCTAssert(dict == dict_a)
			
			let _ = try dict.undo(changeset_redo) // a -> b
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK:- Undo: Fuzz: Basic
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	func test_undo_fuzz_add() {
		
		for _ in 0 ..< 1_000 { autoreleasepool {
		
			var dict_a: ZDCOrderedDictionary<String, String>? = nil
			var dict_b: ZDCOrderedDictionary<String, String>? = nil
			
			let dict = ZDCOrderedDictionary<String, String>()
			
			// Start with an object that has a random number of objects [0 - 10)
			do {
				let startCount = arc4random_uniform(UInt32(10))
				
				for _ in 0 ..< startCount {
					
					let key = self.randomLetters(8)
					dict[key] = ""
				}
			}
			
			dict.clearChangeTracking()
			dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
			// Now add a random number of object [1 - 10)
			do {
				let addCount = 1 + Int(arc4random_uniform(UInt32(9)))
				
				for _ in 0 ..< addCount {
					
					let key = self.randomLetters(8)
					dict[key] = ""
				}
			}
			
			let changeset_undo = dict.changeset() ?? Dictionary()
			dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
			do {
				let changeset_redo = try dict.undo(changeset_undo) // a <- b
				XCTAssert(dict == dict_a)
				
				let _ = try dict.undo(changeset_redo) // a -> b
				XCTAssert(dict == dict_b)
			}
			catch {
				XCTAssert(false)
				print("Threw error: \(error)")
			}
		}}
	}
	
	func test_undo_fuzz_remove() {
		
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var dict_a: ZDCOrderedDictionary<String, String>? = nil
			var dict_b: ZDCOrderedDictionary<String, String>? = nil
			
			let dict = ZDCOrderedDictionary<String, String>()
			
			// Start with an object that has a random number of objects [20 - 30)
			do {
				let startCount = 20 + Int(arc4random_uniform(UInt32(10)))
				
				for _ in 0 ..< startCount {
					
					let key = self.randomLetters(8)
					dict[key] = ""
				}
			}
			
			dict.clearChangeTracking()
			dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
			// Now remove a random number of object [1 - 15)
			do {
				let removeCount = 1 + Int(arc4random_uniform(UInt32(14)))
				
				for _ in 0 ..< removeCount {
					
					let idx = Int(arc4random_uniform(UInt32(dict.count)))
					if dict.count > 0 {
						dict.remove(at: idx)
					}
				}
			}
			
			let changeset_undo = dict.changeset() ?? Dictionary()
			dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
			do {
				let changeset_redo = try dict.undo(changeset_undo) // a <- b
				XCTAssert(dict == dict_a)
				
				let _ = try dict.undo(changeset_redo) // a -> b
				XCTAssert(dict == dict_b)
			}
			catch {
				XCTAssert(false)
				print("Threw error: \(error)")
			}
		}}
	}
	
	func test_undo_fuzz_insert() {
		
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var dict_a: ZDCOrderedDictionary<String, String>? = nil
			var dict_b: ZDCOrderedDictionary<String, String>? = nil
			
			let dict = ZDCOrderedDictionary<String, String>()
			
			// Start with an object that has a random number of objects [0 - 10)
			do {
				
				let startCount = arc4random_uniform(UInt32(10))
				
				for _ in 0 ..< startCount {
					
					let key = self.randomLetters(8)
					dict[key] = ""
				}
			}
			
			dict.clearChangeTracking()
			dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
			// Now insert a random number of object [1 - 10)
			do {
				
				let insertCount = 1 + Int(arc4random_uniform(UInt32(9)))
				
				for _ in 0 ..< insertCount {
					
					let key = self.randomLetters(8)
					let idx = Int(arc4random_uniform(UInt32(dict.count)))
					
					dict.insert("", forKey: key, atIndex: idx)
				}
			}
			
			let changeset_undo = dict.changeset() ?? Dictionary()
			dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
			do {
				let changeset_redo = try dict.undo(changeset_undo) // a <- b
				XCTAssert(dict == dict_a)
				
				let _ = try dict.undo(changeset_redo) // a -> b
				XCTAssert(dict == dict_b)
			}
			catch {
				XCTAssert(false)
				print("Threw error: \(error)")
			}
		}}
	}
	
	func test_undo_fuzz_move() {
		
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var dict_a: ZDCOrderedDictionary<String, String>? = nil
			var dict_b: ZDCOrderedDictionary<String, String>? = nil
			
			let dict = ZDCOrderedDictionary<String, String>()
			
			// Start with an object that has a random number of objects [20 - 30)
			do {
				
				let startCount = 20 + Int(arc4random_uniform(UInt32(10)))
				
				for _ in 0 ..< startCount {
					
					let key = self.randomLetters(8)
					dict[key] = ""
				}
			}
			
			dict.clearChangeTracking()
			dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
			// Now make a random number of moves: [1 - 30)
			
			let moveCount = 1 + Int(arc4random_uniform(UInt32(29)))
			
			for _ in 0 ..< moveCount {
				
				let oldIdx = Int(arc4random_uniform(UInt32(dict.count)))
				let newIdx = Int(arc4random_uniform(UInt32(dict.count)))
				
				dict.move(fromIndex: oldIdx, toIndex: newIdx)
			}
			
			let changeset_undo = dict.changeset() ?? Dictionary()
			dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
			do {
				let changeset_redo = try dict.undo(changeset_undo) // a <- b
				XCTAssert(dict == dict_a)
				
				let _ = try dict.undo(changeset_redo) // a -> b
				XCTAssert(dict == dict_b)
			}
			catch {
				XCTAssert(false)
				print("Threw error: \(error)")
			}
		}}
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK:- Undo: Fuzz: Combo: add + x
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	func test_undo_fuzz_add_remove() {
		
		let DEBUG_THIS_METHOD = false
		
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var dict_a: ZDCOrderedDictionary<String, String>? = nil
			var dict_b: ZDCOrderedDictionary<String, String>? = nil
			
			let dict = ZDCOrderedDictionary<String, String>()
			
			// Start with an object that has a random number of objects [20 - 30)
			do {
				
				var startCount: Int
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
			dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
			// Now make a random number of changes: [1 - 30)
			
			var changeCount: Int
			if DEBUG_THIS_METHOD {
				changeCount = 4
			} else {
				changeCount = 1 + Int(arc4random_uniform(UInt32(29)))
			}
			
			for _ in 0 ..< changeCount {
				
				if (arc4random_uniform(UInt32(2)) == 0)
				{
					// Add an item
					
					let key = self.randomLetters(8)
					
					if DEBUG_THIS_METHOD {
						print("setObject:withKey: \(key) (idx=\(dict.count))")
					}
					dict[key] = ""
				}
				else
				{
					// Remove an item
					
					let idx = Int(arc4random_uniform(UInt32(dict.count)))
					
					if DEBUG_THIS_METHOD {
						print("removeObjectAtIndex: \(idx)")
					}
					if dict.count > 0 {
						dict.remove(at: idx)
					}
				}
			}
			
			let changeset_undo = dict.changeset() ?? Dictionary()
			dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
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
	
	func test_undo_fuzz_add_insert() {
		
		let DEBUG_THIS_METHOD = false
		
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var dict_a: ZDCOrderedDictionary<String, String>? = nil
			var dict_b: ZDCOrderedDictionary<String, String>? = nil
			
			let dict = ZDCOrderedDictionary<String, String>()
			
			// Start with an object that has a random number of objects [20 - 30)
			do {
				var startCount: Int
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
			dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
			// Now make a random number of changes: [1 - 30)
			
			var changeCount: Int
			if DEBUG_THIS_METHOD {
				changeCount = 4
			} else {
				changeCount = 1 + Int(arc4random_uniform(UInt32(29)))
			}
			
			for _ in 0 ..< changeCount {
				
				if (arc4random_uniform(UInt32(2)) == 0)
				{
					// Add an item
					
					let key = self.randomLetters(8)
					
					if DEBUG_THIS_METHOD {
						print("setObject:withKey: \(key) (idx=\(dict.count))")
					}
					dict[key] = ""
				}
				else
				{
					// Insert an item
					
					let key = self.randomLetters(8)
					let idx = Int(arc4random_uniform(UInt32(dict.count)))
					
					if DEBUG_THIS_METHOD {
						print("insertObject:forKey:\(key) atIndex:\(idx)")
					}
					dict.insert("", forKey: key, atIndex: idx)
				}
			}
			
			let changeset_undo = dict.changeset() ?? Dictionary()
			dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
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
	
	func test_undo_fuzz_add_move() {
		
		let DEBUG_THIS_METHOD = false
		
		for _ in 0 ..< 1000 { autoreleasepool {
			
			var dict_a: ZDCOrderedDictionary<String, String>? = nil
			var dict_b: ZDCOrderedDictionary<String, String>? = nil
			
			let dict = ZDCOrderedDictionary<String, String>()
			
			// Start with an object that has a random number of objects [20 - 30)
			do {
				
				var startCount: Int
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
			dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
			// Now make a random number of changes: [1 - 30)
			
			var changeCount: Int
			if DEBUG_THIS_METHOD {
				changeCount = 4
			} else {
				changeCount = 1 + Int(arc4random_uniform(UInt32(29)))
			}
			
			for _ in 0 ..< changeCount {
				
				if (arc4random_uniform(UInt32(2)) == 0)
				{
					// Add an item
					
					let key = self.randomLetters(8)
					
					if DEBUG_THIS_METHOD {
						print("setObject:withKey: \(key) (idx=\(dict.count))")
					}
					dict[key] = ""
				}
				else
				{
					// Move an item
					
					let oldIdx = Int(arc4random_uniform(UInt32(dict.count)))
					let newIdx = Int(arc4random_uniform(UInt32(dict.count)))
					
					if DEBUG_THIS_METHOD {
						print("moveObjectAtIndex:\(oldIdx) toIndex:\(newIdx)")
					}
					dict.move(fromIndex: oldIdx, toIndex: newIdx)
				}
			}
			
			let changeset_undo = dict.changeset() ?? Dictionary()
			dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
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
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK:- Undo: Fuzz: Combo: remove + x
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	func test_undo_fuzz_remove_insert() {
		
		let DEBUG_THIS_METHOD = false
		
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var dict_a: ZDCOrderedDictionary<String, String>? = nil
			var dict_b: ZDCOrderedDictionary<String, String>? = nil
			
			let dict = ZDCOrderedDictionary<String, String>()
			
			// Start with an object that has a random number of objects [20 - 30)
			do {
				
				var startCount: Int
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
			dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
			// Now make a random number of changes: [1 - 30)
			
			var changeCount: Int
			if DEBUG_THIS_METHOD {
				changeCount = 4
			} else {
				changeCount = 1 + Int(arc4random_uniform(UInt32(29)))
			}
			
			for _ in 0 ..< changeCount {
				
				if (arc4random_uniform(UInt32(2)) == 0)
				{
					// Remove an item
					
					let idx = Int(arc4random_uniform(UInt32(dict.count)))
					
					if DEBUG_THIS_METHOD {
						print("removeObjectAtIndex: \(idx)")
					}
					if dict.count > 0 {
						dict.remove(at: idx)
					}
				}
				else
				{
					// Insert an item
					
					let key = self.randomLetters(8)
					let idx = Int(arc4random_uniform(UInt32(dict.count)))
					
					if DEBUG_THIS_METHOD {
						print("insertObject:forKey:\(key) atIndex:\(idx)")
					}
					dict.insert("", forKey: key, atIndex: idx)
				}
			}
			
			let changeset_undo = dict.changeset() ?? Dictionary()
			dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
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
	
	func test_undo_fuzz_remove_move() {
		
		let DEBUG_THIS_METHOD = false
		
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var dict_a: ZDCOrderedDictionary<String, String>? = nil
			var dict_b: ZDCOrderedDictionary<String, String>? = nil
			
			let dict = ZDCOrderedDictionary<String, String>()
			
			// Start with an object that has a random number of objects [20 - 30)
			do {
				
				var startCount: Int
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
			dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
			// Now make a random number of changes: [1 - 30)
			
			var changeCount: Int
			if DEBUG_THIS_METHOD {
				changeCount = 4
			} else {
				changeCount = 1 + Int(arc4random_uniform(UInt32(29)))
			}
			
			for _ in 0 ..< changeCount {
				
				if (arc4random_uniform(UInt32(2)) == 0)
				{
					// Remove an item
					
					let idx = Int(arc4random_uniform(UInt32(dict.count)))
					
					if DEBUG_THIS_METHOD {
						print("removeObjectAtIndex: \(idx)")
					}
					if dict.count > 0 {
						dict.remove(at: idx)
					}
				}
				else
				{
					// Move an item
					
					let oldIdx = Int(arc4random_uniform(UInt32(dict.count)))
					let newIdx = Int(arc4random_uniform(UInt32(dict.count)))
					
					if DEBUG_THIS_METHOD {
						print("move(fromIndex:\(oldIdx), toIndex:\(newIdx)")
					}
					if dict.count > 0 {
						dict.move(fromIndex: oldIdx, toIndex: newIdx)
					}
				}
			}
			
			let changeset_undo = dict.changeset() ?? Dictionary()
			dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
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
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK:- Undo: Fuzz: Combo: insert + x
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	func test_undo_fuzz_insert_move() {
		
		let DEBUG_THIS_METHOD = false
		
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var dict_a: ZDCOrderedDictionary<String, String>? = nil
			var dict_b: ZDCOrderedDictionary<String, String>? = nil
			
			let dict = ZDCOrderedDictionary<String, String>()
			
			// Start with an object that has a random number of objects [20 - 30)
			do {
				var startCount: Int
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
			dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
			// Now make a random number of changes: [1 - 30)
			
			var changeCount: Int
			if DEBUG_THIS_METHOD {
				changeCount = 4
			} else {
				changeCount = 1 + Int(arc4random_uniform(UInt32(29)))
			}
			
			for _ in 0 ..< changeCount {
				
				if (arc4random_uniform(UInt32(2)) == 0)
				{
					// Insert an item
					
					let key = self.randomLetters(8)
					let idx = Int(arc4random_uniform(UInt32(dict.count)))
					
					if DEBUG_THIS_METHOD {
						print("insertObject:forKey:\(key) atIndex:\(idx)")
					}
					dict.insert("", forKey: key, atIndex: idx)
				}
				else
				{
					// Move an item
					
					let oldIdx = Int(arc4random_uniform(UInt32(dict.count)))
					let newIdx = Int(arc4random_uniform(UInt32(dict.count)))
					
					if DEBUG_THIS_METHOD {
						print("move(fromIndex:\(oldIdx), toIndex:\(newIdx)")
					}
					dict.move(fromIndex: oldIdx, toIndex: newIdx)
				}
			}
			
			let changeset_undo = dict.changeset() ?? Dictionary()
			dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
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
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK:- Undo: Fuzz: Triplets
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	func test_undo_fuzz_add_remove_insert() {
		
		let DEBUG_THIS_METHOD = false
		
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var dict_a: ZDCOrderedDictionary<String, String>? = nil
			var dict_b: ZDCOrderedDictionary<String, String>? = nil
			
			let dict = ZDCOrderedDictionary<String, String>()
			
			// Start with an object that has a random number of objects [20 - 30)
			do {
				
				var startCount: Int
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
			dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
			// Now make a random number of changes: [1 - 30)
			
			var changeCount: Int
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
					
					if DEBUG_THIS_METHOD {
						print("setObject:withKey:\(key) (idx=\(dict.count))")
					}
					dict[key] = ""
				}
				else if (random == 1)
				{
					// Remove an item
					
					let idx = Int(arc4random_uniform(UInt32(dict.count)))
					
					if DEBUG_THIS_METHOD {
						print("removeObjectAtIndex:\(idx)")
					}
					if dict.count > 0 {
						dict.remove(at: idx)
					}
				}
				else
				{
					// Insert an item
	
					let key = self.randomLetters(8)
					let idx = Int(arc4random_uniform(UInt32(dict.count)))
					
					if DEBUG_THIS_METHOD {
						print("insertObject:forKey:\(key) atIndex:\(idx)")
					}
					dict.insert("", forKey: key, atIndex: idx)
				}
			}
			
			let changeset_undo = dict.changeset() ?? Dictionary()
			dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
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
	
	func test_undo_fuzz_add_remove_move() {
		
		let DEBUG_THIS_METHOD = false
		
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var dict_a: ZDCOrderedDictionary<String, String>? = nil
			var dict_b: ZDCOrderedDictionary<String, String>? = nil
			
			let dict = ZDCOrderedDictionary<String, String>()
			
			// Start with an object that has a random number of objects [20 - 30)
			do {
				
				var startCount: Int
				if DEBUG_THIS_METHOD {
					startCount = 5;
				} else {
					startCount = 20 + Int(arc4random_uniform(UInt32(10)))
				}
				
				for _ in 0 ..< startCount {
					
					let key = self.randomLetters(8)
					dict[key] = ""
				}
			}
			
			dict.clearChangeTracking()
			dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
			// Now make a random number of changes: [1 - 30)
			
			var changeCount: Int
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
					
					if DEBUG_THIS_METHOD {
						print("setObject:withKey:\(key) (idx=\(dict.count))")
					}
					dict[key] = ""
				}
				else if (random == 1)
				{
					// Remove an item
					
					let idx = Int(arc4random_uniform(UInt32(dict.count)))
					
					if DEBUG_THIS_METHOD {
						print("removeObjectAtIndex:\(idx)")
					}
					if dict.count > 0 {
						dict.remove(at: idx)
					}
				}
				else
				{
					// Move an item
					
					let oldIdx = Int(arc4random_uniform(UInt32(dict.count)))
					let newIdx = Int(arc4random_uniform(UInt32(dict.count)))
					
					if DEBUG_THIS_METHOD {
						print("moveObjectAtIndex:\(oldIdx) toIndex:\(newIdx)")
					}
					if dict.count > 0 {
						dict.move(fromIndex: oldIdx, toIndex: newIdx)
					}
				}
			}
			
			let changeset_undo = dict.changeset() ?? Dictionary()
			dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
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
	
	func test_undo_fuzz_add_insert_move() {
		
		let DEBUG_THIS_METHOD = false
		
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var dict_a: ZDCOrderedDictionary<String, String>? = nil
			var dict_b: ZDCOrderedDictionary<String, String>? = nil
			
			let dict = ZDCOrderedDictionary<String, String>()
			
			// Start with an object that has a random number of objects [20 - 30)
			do {
				
				var startCount: Int
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
			dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
			// Now make a random number of changes: [1 - 30)
			
			var changeCount: Int
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
					
					if DEBUG_THIS_METHOD {
						print("setObject:withKey:\(key) (idx=\(dict.count))")
					}
					dict[key] = ""
				}
				else if (random == 1)
				{
					// Insert an item
					
					let key = self.randomLetters(8)
					let idx = Int(arc4random_uniform(UInt32(dict.count)))
					
					if DEBUG_THIS_METHOD {
						print("insertObject:forKey:\(key) atIndex:\(idx)")
					}
					dict.insert("", forKey:key, atIndex:idx)
				}
				else
				{
					// Move an item
					
					let oldIdx = Int(arc4random_uniform(UInt32(dict.count)))
					let newIdx = Int(arc4random_uniform(UInt32(dict.count)))
					
					if DEBUG_THIS_METHOD {
						print("moveObjectAtIndex:\(oldIdx) toIndex:\(newIdx)")
					}
					dict.move(fromIndex: oldIdx, toIndex: newIdx)
				}
			}
			
			let changeset_undo = dict.changeset() ?? Dictionary()
			dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
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
	
	func test_undo_fuzz_remove_insert_move() {
		
		let DEBUG_THIS_METHOD = false
		
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var dict_a: ZDCOrderedDictionary<String, String>? = nil
			var dict_b: ZDCOrderedDictionary<String, String>? = nil
			
			let dict = ZDCOrderedDictionary<String, String>()
			
			// Start with an object that has a random number of objects [20 - 30)
			do {
				
				var startCount: Int
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
			dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
			// Now make a random number of changes: [1 - 30)
			
			var changeCount: Int
			if DEBUG_THIS_METHOD {
				changeCount = 4
			} else {
				changeCount = 1 + Int(arc4random_uniform(UInt32(29)))
			}
			
			for _ in 0 ..< changeCount {
				
				let random = arc4random_uniform(UInt32(3))
				
				if (random == 0)
				{
					// Remove an item
					
					let idx = Int(arc4random_uniform(UInt32(dict.count)))
					
					if DEBUG_THIS_METHOD {
						print("removeObjectAtIndex:\(idx)")
					}
					if dict.count > 0 {
						dict.remove(at: idx)
					}
				}
				else if (random == 1)
				{
					// Insert an item
					
					let key = self.randomLetters(8)
					let idx = Int(arc4random_uniform(UInt32(dict.count)))
					
					if DEBUG_THIS_METHOD {
						print("insertObject:forKey:\(key) atIndex:\(idx)")
					}
					dict.insert("", forKey: key, atIndex: idx)
				}
				else
				{
					// Move an item
					
					let oldIdx = Int(arc4random_uniform(UInt32(dict.count)))
					let newIdx = Int(arc4random_uniform(UInt32(dict.count)))
					
					if DEBUG_THIS_METHOD {
						print("move(fromIndex:\(oldIdx), toIndex:\(newIdx)")
					}
					if dict.count > 0 {
						dict.move(fromIndex: oldIdx, toIndex: newIdx)
					}
				}
			}
			
			let changeset_undo = dict.changeset() ?? Dictionary()
			dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
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
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK:- Undo: Fuzz: Everything
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	func test_undo_fuzz_everything() {
		
		let DEBUG_THIS_METHOD = false
		
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var dict_a: ZDCOrderedDictionary<String, String>? = nil
			var dict_b: ZDCOrderedDictionary<String, String>? = nil
			
			let dict = ZDCOrderedDictionary<String, String>()
			
			// Start with an object that has a random number of objects [20 - 30)
			do {
				
				var startCount: Int
				if DEBUG_THIS_METHOD {
					startCount = 5
				} else {
					startCount = 20 + Int(arc4random_uniform(UInt32(10)))
				}
				
				for _ in 0 ..< startCount
				{
					let key = self.randomLetters(8)
					let value = self.randomLetters(4)
					
					dict[key] = value;
				}
			}
			
			dict.clearChangeTracking()
			dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
			// Now make a random number of changes: [1 - 30)
			
			var changeCount: Int
			if DEBUG_THIS_METHOD {
				changeCount = 4
			} else {
				changeCount = 1 + Int(arc4random_uniform(UInt32(29)))
			}
			
			for _ in 0 ..< changeCount {
				
				let random = arc4random_uniform(UInt32(5))
				
				if (random == 0)
				{
					// Add an item
					
					let key = self.randomLetters(8)
					
					if DEBUG_THIS_METHOD {
						print("setObject:withKey:\(key) (idx=\(dict.count))")
					}
					dict[key] = ""
				}
				else if (random == 1)
				{
					// Remove an item
					
					let idx = Int(arc4random_uniform(UInt32(dict.count)))
					
					if DEBUG_THIS_METHOD {
						print("remove(at:\(idx))")
					}
					if dict.count > 0 {
						dict.remove(at: idx)
					}
				}
				else if (random == 2)
				{
					// Modify an item
					
					let idx = Int(arc4random_uniform(UInt32(dict.count)))
					
					let key = dict.keyAtIndex(idx)
					let newValue = self.randomLetters(4)
					
					if let key = key {
						
						if DEBUG_THIS_METHOD {
							print("modify: key:\(key) = \(newValue)")
						}
						dict[key] = newValue
					}
				}
				else if (random == 3)
				{
					// Insert an item
					
					let key = self.randomLetters(8)
					let idx = Int(arc4random_uniform(UInt32(dict.count)))
					
					if DEBUG_THIS_METHOD {
						print("insertObject:forKey:\(key) atIndex:\(idx)")
					}
					dict.insert("", forKey: key, atIndex: idx)
				}
				else
				{
					// Move an item
					
					let oldIdx = Int(arc4random_uniform(UInt32(dict.count)))
					let newIdx = Int(arc4random_uniform(UInt32(dict.count)))
					
					if DEBUG_THIS_METHOD {
						print("moveObjectAtIndex:\(oldIdx) toIndex:\(newIdx)")
					}
					if dict.count > 0 {
						dict.move(fromIndex: oldIdx, toIndex: newIdx)
					}
				}
			}
			
			let changeset_undo = dict.changeset() ?? Dictionary()
			dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
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
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK:- Import: Basic
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	func test_import_basic_1() {
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		let dict = ZDCOrderedDictionary<String, String>()
		var changesets = Array<Dictionary<String, Any>>()
		
		// Empty dictionary will be starting state
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do { // changeset: A
			
			dict["cow"] = "moo"
			dict["duck"] = "quack"
		
			changesets.append(dict.changeset() ?? Dictionary())
		}
		do { // changeset: B
			
			dict["dog"] = "bark"
			dict["cat"] = "meow"
			
			changesets.append(dict.changeset() ?? Dictionary())
		}
		
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			try dict.importChangesets(changesets)
			XCTAssert(dict == dict_b)
			
			let changeset_merged = dict.changeset() ?? Dictionary()
			
			let changeset_redo = try dict.undo(changeset_merged)
			XCTAssert(dict == dict_a)
			
			let _ = try dict.undo(changeset_redo)
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_import_basic_2() {
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		let dict = ZDCOrderedDictionary<String, String>()
		var changesets = Array<Dictionary<String, Any>>()
		
		dict["cow"] = "moo"
		dict["duck"] = "quack"
		dict["dog"] = "bark"
		dict["cat"] = "meow"
		
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do { // changeset: A
			
			dict.remove(at: 0)
			
			changesets.append(dict.changeset() ?? Dictionary())
		}
		do { // changeset: B
			
			dict.remove(at: 0)
			dict.remove(at: 0)
			
			changesets.append(dict.changeset() ?? Dictionary())
		}
		
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			try dict.importChangesets(changesets)
			XCTAssert(dict == dict_b)
			
			let changeset_merged = dict.changeset() ?? Dictionary()
			
			let changeset_redo = try dict.undo(changeset_merged)
			XCTAssert(dict == dict_a)
			
			let _ = try dict.undo(changeset_redo)
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_import_basic_3() {
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		let dict = ZDCOrderedDictionary<String, String>()
		var changesets = Array<Dictionary<String, Any>>()
		
		dict["cow"] = "moo"
		
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do { // changeset: A
			
			dict.insert("quack", forKey: "duck", atIndex: 0)
			
			changesets.append(dict.changeset() ?? Dictionary())
		}
		do { // changeset: B
			
			dict.insert("bark", forKey: "dog", atIndex: 1)
			dict.insert("meow", forKey: "cat", atIndex: 0)
			
			changesets.append(dict.changeset() ?? Dictionary())
		}
		
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			try dict.importChangesets(changesets)
			XCTAssert(dict == dict_b)
			
			let changeset_merged = dict.changeset() ?? Dictionary()
			
			let changeset_redo = try dict.undo(changeset_merged)
			XCTAssert(dict == dict_a)
			
			let _ = try dict.undo(changeset_redo)
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_import_basic_4() {
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		let dict = ZDCOrderedDictionary<String, String>()
		var changesets = Array<Dictionary<String, Any>>()
		
		dict["cow"] = "moo"
		dict["duck"] = "quack"
		dict["dog"] = "bark"
		dict["cat"] = "meow"
		
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do { // changeset: A
			
			dict.move(fromIndex: 2, toIndex: 3) // dog
			
			changesets.append(dict.changeset() ?? Dictionary())
		}
		do { // changeset: B
			
			dict.move(fromIndex: 2, toIndex: 0) // cat
			dict.move(fromIndex: 3, toIndex: 2) // dog
			
			changesets.append(dict.changeset() ?? Dictionary())
		}
		
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			try dict.importChangesets(changesets)
			XCTAssert(dict == dict_b)
			
			let changeset_merged = dict.changeset() ?? Dictionary()
			
			let changeset_redo = try dict.undo(changeset_merged)
			XCTAssert(dict == dict_a)
			
			let _ = try dict.undo(changeset_redo)
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK:- Import: Failures
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	func test_import_failure_1() {
		
		var dict_a: ZDCOrderedDictionary<String, String>? = nil
		var dict_b: ZDCOrderedDictionary<String, String>? = nil
		
		let dict = ZDCOrderedDictionary<String, String>()
		var changesets = Array<Dictionary<String, Any>>()
		
		dict["bmfx"] = ""
		dict["pwtg"] = ""
		dict["czuy"] = ""
		dict["cubs"] = ""
		dict["xcwm"] = ""
		
		dict.clearChangeTracking()
		dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do { // changeset: A
			
			dict["tsgh"] = ""
			
			changesets.append(dict.changeset() ?? Dictionary())
		}
		do { // changeset: B
			
			dict.move(fromIndex: 5, toIndex: 0)
			
			changesets.append(dict.changeset() ?? Dictionary())
		}
		
		dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			try dict.importChangesets(changesets)
			XCTAssert(dict == dict_b)
			
			let changeset_merged = dict.changeset() ?? Dictionary()
			
			let changeset_redo = try dict.undo(changeset_merged)
			XCTAssert(dict == dict_a)
			
			let _ = try dict.undo(changeset_redo)
			XCTAssert(dict == dict_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Mark: Import: Fuzz: Basic
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	func test_import_fuzz_add() {
		
		let DEBUG_THIS_METHOD = false
	
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var dict_a: ZDCOrderedDictionary<String, String>? = nil
			var dict_b: ZDCOrderedDictionary<String, String>? = nil
			
			var changesets = Array<Dictionary<String, Any>>()
			let dict = ZDCOrderedDictionary<String, String>()
			
			// Start with an object that has a random number of objects [20 - 30)
			do {
				
				var startCount: Int
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
			dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
			// Make a random number of changesets: [1 - 10)
			
			var changesetCount: Int
			if DEBUG_THIS_METHOD {
				changesetCount = 2
			} else {
				changesetCount = 1 + Int(arc4random_uniform(UInt32(9)))
			}
			
			for _ in 0 ..< changesetCount {
				
				// Make a random number of changes: [1 - 30)
				
				var changeCount: Int
				if DEBUG_THIS_METHOD {
					changeCount = 4
				} else {
					changeCount = 1 + Int(arc4random_uniform(UInt32(29)))
				}
				
				for _ in 0 ..< changeCount {
					
					// Add an item
					
					let key = self.randomLetters(8)
					
					if DEBUG_THIS_METHOD {
						print("setObject:withKey:\(key) (idx=\(dict.count))")
					}
					dict[key] = ""
				}
				
				changesets.append(dict.changeset() ?? Dictionary())
				
				if DEBUG_THIS_METHOD {
					print("********************")
				}
			}
			
			dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
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
	
	func test_import_fuzz_remove() {
		
		let DEBUG_THIS_METHOD = false
		
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var dict_a: ZDCOrderedDictionary<String, String>? = nil
			var dict_b: ZDCOrderedDictionary<String, String>? = nil
			
			var changesets = Array<Dictionary<String, Any>>()
			let dict = ZDCOrderedDictionary<String, String>()
			
			// Start with an object that has a random number of objects [20 - 30)
			do {
				
				var startCount: Int
				if DEBUG_THIS_METHOD {
					startCount = 10
				} else {
					startCount = 20 + Int(arc4random_uniform(UInt32(10)))
				}
				
				for _ in 0 ..< startCount {
					
					let key = self.randomLetters(8)
					dict[key] = ""
				}
			}
			
			dict.clearChangeTracking()
			dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
			// Make a random number of changesets: [1 - 10)
			
			var changesetCount: Int
			if DEBUG_THIS_METHOD {
				changesetCount = 2
			} else {
				changesetCount = 1 + Int(arc4random_uniform(UInt32(9)))
			}
			
			for _ in 0 ..< changesetCount {
				
				// Make a random number of changes: [1 - 30)
				
				var changeCount: Int
				if DEBUG_THIS_METHOD {
					changeCount = 4
				} else {
					changeCount = 1 + Int(arc4random_uniform(UInt32(29)))
				}
				
				for _ in 0 ..< changeCount {
					
					// Remove an item
					if dict.count > 0 {
						
						let idx = Int(arc4random_uniform(UInt32(dict.count)))
						
						if DEBUG_THIS_METHOD {
							print("removeObjectAtIndex:\(idx)")
						}
						dict.remove(at: idx)
					}
				}
				
				changesets.append(dict.changeset() ?? Dictionary())
				
				if DEBUG_THIS_METHOD {
					print("********************")
				}
			}
			
			dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
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
	
	func test_import_fuzz_insert() {
		
		let DEBUG_THIS_METHOD = false
		
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var dict_a: ZDCOrderedDictionary<String, String>? = nil
			var dict_b: ZDCOrderedDictionary<String, String>? = nil
			
			var changesets = Array<Dictionary<String, Any>>()
			let dict = ZDCOrderedDictionary<String, String>()
			
			// Start with an object that has a random number of objects [20 - 30)
			do {
				
				var startCount: Int
				if DEBUG_THIS_METHOD {
					startCount = 10
				} else {
					startCount = 20 + Int(arc4random_uniform(UInt32(10)))
				}
				
				for _ in 0 ..< startCount {
					
					let key = self.randomLetters(8)
					dict[key] = ""
				}
			}
			
			dict.clearChangeTracking()
			dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
			// Make a random number of changesets: [1 - 10)
			
			var changesetCount: Int
			if DEBUG_THIS_METHOD {
				changesetCount = 2
			} else {
				changesetCount = 1 + Int(arc4random_uniform(UInt32(9)))
			}
			
			for _ in 0 ..< changesetCount {
				
				// Make a random number of changes: [1 - 30)
				
				var changeCount: Int
				if DEBUG_THIS_METHOD {
					changeCount = 4
				} else {
					changeCount = 1 + Int(arc4random_uniform(UInt32(29)))
				}
				
				for _ in 0 ..< changeCount {
					
					// Insert an item
					
					let key = self.randomLetters(8)
					let idx = Int(arc4random_uniform(UInt32(dict.count)))
					
					if DEBUG_THIS_METHOD {
						print("insertObject:forKey:\(key) atIndex:\(idx)")
					}
					dict.insert("", forKey: key, atIndex: idx)
				}
				
				changesets.append(dict.changeset() ?? Dictionary())
				
				if DEBUG_THIS_METHOD {
					print("********************")
				}
			}
			
			dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
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
	
	func test_import_fuzz_move() {
		
		let DEBUG_THIS_METHOD = false
		
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var dict_a: ZDCOrderedDictionary<String, String>? = nil
			var dict_b: ZDCOrderedDictionary<String, String>? = nil
			
			let dict = ZDCOrderedDictionary<String, String>()
			var changesets = Array<Dictionary<String, Any>>()
			
			// Start with an object that has a random number of objects [20 - 30)
			do {
				
				var startCount: Int
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
			dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
			// Make a random number of changesets: [1 - 10)
			
			var changesetCount: Int
			if DEBUG_THIS_METHOD {
				changesetCount = 2
			} else {
				changesetCount = 1 + Int(arc4random_uniform(UInt32(9)))
			}
			
			for _ in 0 ..< changesetCount {
				
				// Make a random number of changes: [1 - 30)
				
				var changeCount: Int
				if DEBUG_THIS_METHOD {
					changeCount = 1
				} else {
					changeCount = 1 + Int(arc4random_uniform(UInt32(29)))
				}
				
				for _ in 0 ..< changeCount {
					
					// Move an item
					
					let oldIdx = Int(arc4random_uniform(UInt32(dict.count)))
					let newIdx = Int(arc4random_uniform(UInt32(dict.count)))
					
					if DEBUG_THIS_METHOD {
						print("move(fromIndex:\(oldIdx), toIndex:\(newIdx)")
					}
					dict.move(fromIndex: oldIdx, toIndex: newIdx)
				}
				
				changesets.append(dict.changeset() ?? Dictionary())
				
				if DEBUG_THIS_METHOD {
					print("********************")
				}
			}
			
			dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
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
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK:- Import: Fuzz: Everything
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	func test_import_fuzz_everything() {
		
		let DEBUG_THIS_METHOD = false
		
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var dict_a: ZDCOrderedDictionary<String, String>? = nil
			var dict_b: ZDCOrderedDictionary<String, String>? = nil
			
			let dict = ZDCOrderedDictionary<String, String>()
			var changesets = Array<Dictionary<String, Any>>()
			
			// Start with an object that has a random number of objects [20 - 30)
			do {
				
				var startCount: Int
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
			dict_a = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
			// Make a random number of changesets: [1 - 10)
			
			var changesetCount: Int
			if DEBUG_THIS_METHOD {
				changesetCount = 2
			} else {
				changesetCount = 1 + Int(arc4random_uniform(UInt32(9)))
			}
			
			for _ in 0 ..< changesetCount {
				
				// Make a random number of changes: [1 - 30)
				
				var changeCount: Int
				if DEBUG_THIS_METHOD {
					changeCount = 2
				} else {
					changeCount = 1 + Int(arc4random_uniform(UInt32(29)))
				}
				
				for _ in 0 ..< changeCount {
					
					let random = arc4random_uniform(UInt32(4))
					
					if (random == 0)
					{
						// Add an item
						
						let key = self.randomLetters(8)
						
						if DEBUG_THIS_METHOD {
							print("setObject:withKey:\(key) (idx=\(dict.count))")
						}
						dict[key] = ""
					}
					else if (random == 1)
					{
						// Remove an item
						
						let idx = Int(arc4random_uniform(UInt32(dict.count)))
						
						if DEBUG_THIS_METHOD {
							print("removeObjectAtIndex:\(idx)")
						}
						dict.remove(at: idx)
					}
					else if (random == 2)
					{
						// Insert an item
						
						let key = self.randomLetters(8)
						let idx = Int(arc4random_uniform(UInt32(dict.count)))
						
						if DEBUG_THIS_METHOD {
							print("insertObject:forKey:\(key) atIndex:\(idx)")
						}
						dict.insert("", forKey: key, atIndex: idx)
					}
					else
					{
						// Move an item
						
						let oldIdx = Int(arc4random_uniform(UInt32(dict.count)))
						let newIdx = Int(arc4random_uniform(UInt32(dict.count)))
						
						if DEBUG_THIS_METHOD {
							print("move(fromIndex:\(oldIdx), toIndex:\(newIdx)")
						}
						dict.move(fromIndex:oldIdx, toIndex:newIdx)
					}
				}
				
				changesets.append(dict.changeset() ?? Dictionary())
				
				if DEBUG_THIS_METHOD {
					print("********************")
				}
			}
			
			dict_b = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
			
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
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK:- Merge: Failure
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	func test_merge_failure_1() {
		
		var dict = ZDCOrderedDictionary<String, String>()
		var changesets = Array<Dictionary<String, Any>>()
		
		dict["qszzujxl"] = "" // 0
		dict["krytwlyk"] = "" // 1
		dict["vgraihbv"] = "" // 2
		dict["vwyxkfwk"] = "" // 3
		dict["mcfxtodx"] = "" // 4
		
		dict.clearChangeTracking()
		var dict_cloud = dict.immutableCopy() as! ZDCOrderedDictionary<String, String>
		
		do {
			// - removeObjectAtIndex:4
			// - removeObjectAtIndex:3
			
			dict.remove(at: 4)
			dict.remove(at: 3)
			
			changesets.append(dict.changeset() ?? Dictionary())
		}
	
		do {
			// - setObject:withKey: vqtcntfi (idx=3)
			// - removeObjectAtIndex:0
			
			dict["vqtcntfi"] = ""
			dict.remove(at: 0)
		
			changesets.append(dict.changeset() ?? Dictionary())
		}
		
		dict.makeImmutable()
		dict_cloud = dict_cloud.copy() as! ZDCOrderedDictionary<String, String>
	
		do {
			// - moveObjectAtIndex:1 toIndex:1
			// - removeObjectAtIndex:1
			
			dict_cloud.move(fromIndex: 1, toIndex: 1)
			dict_cloud.remove(at: 1)
		}
		
		dict = dict.copy() as! ZDCOrderedDictionary<String, String>
		dict_cloud.makeImmutable()
		
		let dict_preMerge = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			let redo = try dict.merge(cloudVersion: dict_cloud, pendingChangesets: changesets)
		
			let _ = try dict.undo(redo)
			XCTAssert(dict == dict_preMerge)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_merge_failure_2() {
		
		var dict = ZDCOrderedDictionary<String, String>()
		var changesets = Array<Dictionary<String, Any>>()
		
		/*
		addObject:withKey: suisclsz (idx=0)
		addObject:withKey: yxqjgpop (idx=1)
		addObject:withKey: gurefiso (idx=2)
		addObject:withKey: ptrrakgz (idx=3)
		addObject:withKey: cugkmpfr (idx=4)
		....................
		moveObjectAtIndex: 0 toIndex: 3
		insertObject:forKey: chpckndi atIndex: 3
		********************
		insertObject:forKey: oxpeanii atIndex: 2
		moveObjectAtIndex: 0 toIndex: 3
		********************
		removeObjectAtIndex: 1
		moveObjectAtIndex:3 toIndex:1
		*/
		
		dict["alice"] = "" // 0
		dict["bob"]   = "" // 1
		dict["carol"] = "" // 2
		dict["dave"]  = "" // 3
		dict["emily"] = "" // 4
		
		dict.clearChangeTracking()
		var dict_cloud = dict.immutableCopy() as! ZDCOrderedDictionary<String, String>
		
		do {
			// - moveObjectAtIndex: 0 toIndex: 3
			// - insertObject:forKey: chpckndi atIndex: 3
			
			dict.move(fromIndex: 0, toIndex: 3)
			dict.insert("", forKey: "frank", atIndex: 3)
			
			changesets.append(dict.changeset() ?? Dictionary())
		}
		
		do {
			// - insertObject:forKey: oxpeanii atIndex: 2
			// - moveObjectAtIndex: 0 toIndex: 3
			
			dict.insert("", forKey: "gail", atIndex: 2)
			dict.move(fromIndex: 0, toIndex: 3)
			
			changesets.append(dict.changeset() ?? Dictionary())
		}
		
		dict.makeImmutable()           // don't allow modification (for now)
		dict_cloud = dict_cloud.copy() as! ZDCOrderedDictionary<String, String> // allow modification again
		
		do {
			// - removeObjectAtIndex: 1
			// - moveObjectAtIndex:3 toIndex:1
			
			dict_cloud.remove(at: 1)
			dict_cloud.move(fromIndex: 3, toIndex: 1)
		}
		
		dict = dict.copy() as! ZDCOrderedDictionary<String, String>
		dict_cloud.makeImmutable()
		
		let dict_preMerge = dict.immutableCopy() as? ZDCOrderedDictionary<String, String>
		
		do {
			let redo = try dict.merge(cloudVersion: dict_cloud, pendingChangesets: changesets)
			
			let _ = try dict.undo(redo)
			XCTAssert(dict == dict_preMerge)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK:- Merge: Fuzz: Everything
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	func test_merge_fuzz_everything() {
		
		let DEBUG_THIS_METHOD = false
		
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var changesets = Array<Dictionary<String, Any>>()
			
			var dict = ZDCOrderedDictionary<String, String>()
			
			// Start with an object that has a random number of objects [20 - 30)
			do {
				var startCount: Int
				if DEBUG_THIS_METHOD {
					startCount = 5
				} else {
					startCount = 20 + Int(arc4random_uniform(UInt32(10)))
				}
				
				for _ in 0 ..< startCount {
					
					let key = self.randomLetters(8)
					
					if DEBUG_THIS_METHOD {
						print("addObject:withKey: \(key) (idx=\(dict.count))")
					}
					dict[key] = ""
				}
			}
			
			if DEBUG_THIS_METHOD {
				print("....................")
			}
			
			dict.clearChangeTracking()
			var dict_cloud = dict.immutableCopy() as! ZDCOrderedDictionary<String, String>
			
			// Make a random number of changesets: [1 - 10)
			
			var changesetCount: Int
			if DEBUG_THIS_METHOD {
				changesetCount = 2
			} else {
				changesetCount = 1 + Int(arc4random_uniform(UInt32(9)))
			}
			
			for _ in 0 ..< changesetCount {
				
				// Make a random number of changes (to dict): [1 - 30)
				
				var changeCount: Int
				if DEBUG_THIS_METHOD {
					changeCount = 2
				} else {
					changeCount = 1 + Int(arc4random_uniform(UInt32(29)))
				}
				
				for _ in 0 ..< changeCount {
					
					let random = arc4random_uniform(UInt32(4))
					
					if (random == 0)
					{
						// Add an item
						
						let key = self.randomLetters(8)
						
						if DEBUG_THIS_METHOD {
							print("setObject:withKey: \(key) (idx=\(dict.count))")
						}
						dict[key] = ""
					}
					else if (random == 1)
					{
						// Remove an item
						
						let idx = Int(arc4random_uniform(UInt32(dict.count)))
						
						if DEBUG_THIS_METHOD {
							print("removeObjectAtIndex:\(idx)")
						}
						dict.remove(at: idx)
					}
					else if (random == 2)
					{
						// Insert an item
						
						let key = self.randomLetters(8)
						let idx = Int(arc4random_uniform(UInt32(dict.count)))
						
						if DEBUG_THIS_METHOD {
							print("insertObject:forKey: \(key) atIndex: \(idx)")
						}
						dict.insert("", forKey: key, atIndex: idx)
					}
					else
					{
						// Move an item
						
						let oldIdx = Int(arc4random_uniform(UInt32(dict.count)))
						let newIdx = Int(arc4random_uniform(UInt32(dict.count)))
						
						if DEBUG_THIS_METHOD {
							print("moveObjectAtIndex: \(oldIdx) toIndex: \(newIdx)")
						}
						dict.move(fromIndex: oldIdx, toIndex: newIdx)
					}
				}
				
				changesets.append(dict.changeset() ?? Dictionary())
				
				if DEBUG_THIS_METHOD {
					print("********************")
				}
			}
			
			dict.makeImmutable()
			dict_cloud = dict_cloud.copy() as! ZDCOrderedDictionary<String, String>
			
			do {
				
				// Make a random number of changes (to dict_cloud): [1 - 30)
				
				var changeCount: Int
				if DEBUG_THIS_METHOD {
					changeCount = 2
				} else {
					changeCount = 1 + Int(arc4random_uniform(UInt32(29)))
				}
				
				for _ in 0 ..< changeCount {
					
					let random = arc4random_uniform(UInt32(4))
					
					if (random == 0)
					{
						// Add an item
						
						let key = self.randomLetters(8)
						
						if DEBUG_THIS_METHOD {
							print("setObject:withKey: \(key) (idx=\(dict.count))")
						}
						dict_cloud[key] = ""
					}
					else if (random == 1)
					{
						// Remove an item
						
						let idx = Int(arc4random_uniform(UInt32(dict_cloud.count)))
						
						if DEBUG_THIS_METHOD {
							print("removeObjectAtIndex: \(idx)")
						}
						if dict_cloud.count > 0 {
							dict_cloud.remove(at: idx)
						}
					}
					else if (random == 2)
					{
						// Insert an item
						
						let key = self.randomLetters(8)
						let idx = Int(arc4random_uniform(UInt32(dict_cloud.count)))
						
						if DEBUG_THIS_METHOD {
							print("insertObject:forKey:atIndex: \(idx)")
						}
						dict_cloud.insert("", forKey: key, atIndex: idx)
					}
					else
					{
						// Move an item
						
						let oldIdx = Int(arc4random_uniform(UInt32(dict_cloud.count)))
						let newIdx = Int(arc4random_uniform(UInt32(dict_cloud.count)))
						
						if DEBUG_THIS_METHOD {
							print("moveObjectAtIndex:\(oldIdx) toIndex:\(newIdx)")
						}
						dict_cloud.move(fromIndex: oldIdx, toIndex: newIdx)
					}
				}
			}
			
			dict = dict.copy() as! ZDCOrderedDictionary<String, String>
			dict_cloud.makeImmutable()
			
			let dict_preMerge = dict.immutableCopy() as! ZDCOrderedDictionary<String, String>
			
			do {
				let redo = try dict.merge(cloudVersion: dict_cloud, pendingChangesets: changesets)
				
				let _ = try dict.undo(redo)
				XCTAssert(dict == dict_preMerge)
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
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK:- Merge: Simple
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	func test_simpleMerge_1() {
		
		let localDict = ZDCOrderedDictionary<String, Int>()
		var changesets = Array<Dictionary<String, Any>>()
		
		localDict["alice"] = 0
		localDict["bob"] = 0
		
		localDict.clearChangeTracking()
		let cloudDict = localDict.copy() as! ZDCOrderedDictionary<String, Int>
		
		do { // local changes
			
			localDict["alice"] = 42
			changesets.append(localDict.changeset() ?? Dictionary())
		}
		do { // cloud changes
			
			cloudDict["bob"] = 43
			cloudDict.makeImmutable()
		}
		
		do {
			let _ = try localDict.merge(cloudVersion: cloudDict, pendingChangesets: changesets)
		
			XCTAssert(localDict["alice"] == 42)
			XCTAssert(localDict["bob"] == 43)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_simpleMerge_2() {
		
		let localDict = ZDCOrderedDictionary<String, Int>()
		var changesets = Array<Dictionary<String, Any>>()
		
		localDict["alice"] = 0
		localDict["bob"] = 42
		
		localDict.clearChangeTracking()
		let cloudDict = localDict.copy() as! ZDCOrderedDictionary<String, Int>
		
		do { // local changes
			
			localDict["alice"] = 42
			changesets.append(localDict.changeset() ?? Dictionary())
		}
		do { // cloud changes
			
			cloudDict["alice"] = 43
			cloudDict["bob"] = 43
			cloudDict.makeImmutable()
		}
	
		do {
			let _ = try localDict.merge(cloudVersion: cloudDict, pendingChangesets: changesets)
			
			XCTAssert(localDict["alice"] == 43)
			XCTAssert(localDict["bob"] == 43)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_simpleMerge_3() {
		
		let localDict = ZDCOrderedDictionary<String, Int>()
		var changesets = Array<Dictionary<String, Any>>()
		
		localDict["bob"] = 42
		
		localDict.clearChangeTracking()
		let cloudDict = localDict.copy() as! ZDCOrderedDictionary<String, Int>
		
		do { // local changes
			
			localDict["alice"] = 42
			changesets.append(localDict.changeset() ?? Dictionary())
		}
		do { // cloud changes
			
			cloudDict["alice"] = 43
			cloudDict["bob"] = 43
			cloudDict.makeImmutable()
		}
	
		do {
			let _ = try localDict.merge(cloudVersion: cloudDict, pendingChangesets: changesets)
			
			XCTAssert(localDict["alice"] == 43)
			XCTAssert(localDict["bob"] == 43)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_simpleMerge_4() {
	
		let localDict = ZDCOrderedDictionary<String, Int>()
		var changesets = Array<Dictionary<String, Any>>()
		
		localDict["bob"] = 42
		
		localDict.clearChangeTracking()
		let cloudDict = localDict.copy() as! ZDCOrderedDictionary<String, Int>
		
		do { // local changes
			
			localDict["alice"] = 43
			changesets.append(localDict.changeset() ?? Dictionary())
		}
		do { // cloud changes
			
			cloudDict["bob"] = 43
			cloudDict.makeImmutable()
		}
	
		do {
			let _ = try localDict.merge(cloudVersion: cloudDict, pendingChangesets: changesets)
			
			XCTAssert(localDict["alice"] == 43)
			XCTAssert(localDict["bob"] == 43)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_simpleMerge_5() {
	
		let localDict = ZDCOrderedDictionary<String, Int>()
		var changesets = Array<Dictionary<String, Any>>()
		
		localDict["alice"] = 42
		localDict["bob"] = 42
		
		localDict.clearChangeTracking()
		let cloudDict = localDict.copy() as! ZDCOrderedDictionary<String, Int>
		
		do { // local changes
			
			localDict["bob"] = 43
			changesets.append(localDict.changeset() ?? Dictionary())
		}
		do { // cloud changes
			
			cloudDict["alice"] = nil
			cloudDict.makeImmutable()
		}
	
		do {
			let _ = try localDict.merge(cloudVersion: cloudDict, pendingChangesets: changesets)
			
			XCTAssert(localDict["alice"] == nil)
			XCTAssert(localDict["bob"] == 43)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Merge - Complex
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	func test_complexMerge_1() {
	
		let localDict = ZDCOrderedDictionary<String, ZDCOrderedDictionary<String, String>>()
		var changesets = Array<Dictionary<String, Any>>()
		
		localDict["dict"] = ZDCOrderedDictionary<String, String>()
		localDict["dict"]?["dog"] = "bark"
		
		localDict.clearChangeTracking()
		let cloudDict = ZDCOrderedDictionary(zdc: localDict, copyValues: true)
		
		do { // local changes
			
			localDict["dict"]?["cat"] = "meow"
			changesets.append(localDict.changeset() ?? Dictionary())
		}
		do { // cloud changes
			
			cloudDict["dict"]?["duck"] = "quack"
			cloudDict.makeImmutable()
		}
		
		XCTAssert(localDict["dict"]?["duck"] == nil)
		
		do {
			let _ = try localDict.merge(cloudVersion: cloudDict, pendingChangesets: changesets)
			
			XCTAssert(localDict["dict"]?["dog"] == "bark")
			XCTAssert(localDict["dict"]?["cat"] == "meow")
			XCTAssert(localDict["dict"]?["duck"] == "quack")
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
}
