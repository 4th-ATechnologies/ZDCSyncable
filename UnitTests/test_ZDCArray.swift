/// ZDCSyncable
/// https://github.com/4th-ATechnologies/ZDCSyncable
///
/// Undo, redo & merge capabilities for structs & objects in pure Swift.

import XCTest
import ZDCSyncable

class test_ZDCArray: XCTestCase {
	
	func randomLetters(_ length: UInt) -> String {
		
		let alphabet = "abcdefghijklmnopqrstuvwxyz"
		return String((0..<length).map{ _ in alphabet.randomElement()! })
	}
	
	// ====================================================================================================
	// MARK:- Undo - Basic
	// ====================================================================================================
	
	func test_undo_basic_1() {
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		
		// Basic undo/redo functionality.
		//
		// - add
		
		var array = ZDCArray<String>()
		
		// Empty array will be starting state
		//
		array_a = array
		
		array.append("cow")
		array.append("duck")
		
		XCTAssert(array.count == 2)
		
		let changeset_undo = array.changeset() ?? Dictionary()
		array_b = array
		
		do {
			let changeset_redo = try array.undo(changeset_undo)
			XCTAssert(array == array_a)
			
			let _ = try array.undo(changeset_redo)
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_undo_basic_2() {
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		
		// Basic undo/redo functionality.
		//
		// - remove
		
		var array = ZDCArray<String>()
		
		array.append("cow")
		array.append("duck")
		
		array.clearChangeTracking()
		array_a = array
		
		array.remove("cow")
		
		let changeset_undo = array.changeset() ?? Dictionary()
		array_b = array
		
		do {
			let changeset_redo = try array.undo(changeset_undo)
			XCTAssert(array == array_a)
			
			let _ = try array.undo(changeset_redo)
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_undo_basic_3() {
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		
		// Basic undo/redo functionality.
		//
		// - replace
		
		var array = ZDCArray<String>()
		
		array.append("cow")
		array.append("duck")
		
		array.clearChangeTracking()
		array_a = array
		
		array[0] = "horse"
		
		let changeset_undo = array.changeset() ?? Dictionary()
		array_b = array
		
		do {
			let changeset_redo = try array.undo(changeset_undo)
			XCTAssert(array == array_a)
			
			let _ = try array.undo(changeset_redo)
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_undo_basic_4() {
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Can we undo/redo basic `moveObjectAtIndex:toIndex:` functionality ?
		
		var array = ZDCArray<String>()
		
		array.append("cow")
		array.append("duck")
		
		array.clearChangeTracking()
		array_a = array
		
		array.move(fromIndex: 0, toIndex: 1)
		
		XCTAssert(array[0] == "duck")
		XCTAssert(array[1] == "cow")
		
		let changeset_undo = array.changeset() ?? Dictionary()
		array_b = array
		
		do {
			let changeset_redo = try array.undo(changeset_undo)
			XCTAssert(array == array_a)
			
			let _ = try array.undo(changeset_redo)
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	// ====================================================================================================
	// MARK: Undo: Combo: add + X
	// ====================================================================================================

	func test_undo_add_add() {
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Add + Add
		
		var array = ZDCArray<String>()
		
		array.append("cow")
		array.append("duck")
		
		array.clearChangeTracking()
		array_a = array
		
		array.append("dog")
		array.append("cat")
		
		XCTAssert(array.count == 4);
		
		let changeset_undo = array.changeset() ?? Dictionary()
		array_b = array
	
		do {
			let changeset_redo = try array.undo(changeset_undo) // a <- b
			XCTAssert(array == array_a)
			
			let _ = try array.undo(changeset_redo) // a -> b
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_undo_add_remove() {
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Add + Remove
		
		var array = ZDCArray<String>()
		
		array.append("cow")
		array.append("duck")
		
		array.clearChangeTracking()
		array_a = array
		
		array.append("dog")
		array.remove("cow")
		
		XCTAssert(array.count == 2);
		
		let changeset_undo = array.changeset() ?? Dictionary()
		array_b = array
		
		do {
			let changeset_redo = try array.undo(changeset_undo) // a <- b
			XCTAssert(array == array_a)
			
			let _ = try array.undo(changeset_redo) // a -> b
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_undo_add_insert() {
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Add + Insert
		
		var array = ZDCArray<String>()
		
		array.append("cow")
		array.append("duck")
		
		array.clearChangeTracking()
		array_a = array
		
		array.append("dog")
		array.insert("cat", at: 0)
		
		XCTAssert(array.count == 4);
		XCTAssert(array[0] == "cat")
		XCTAssert(array[1] == "cow")
		XCTAssert(array[2] == "duck")
		XCTAssert(array[3] == "dog")
		
		let changeset_undo = array.changeset() ?? Dictionary()
		array_b = array
		
		do {
			let changeset_redo = try array.undo(changeset_undo) // a <- b
			XCTAssert(array == array_a)
			
			let _ = try array.undo(changeset_redo) // a -> b
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_undo_add_move() {
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Add + Move
		
		var array = ZDCArray<String>()
		
		array.append("cow")
		array.append("duck")
		
		array.clearChangeTracking()
		array_a = array
		
		array.append("dog")
		array.move(fromIndex: 0, toIndex: 1)
		
		XCTAssert(array.count == 3)
		
		let changeset_undo = array.changeset() ?? Dictionary()
		array_b = array
		
		do {
			let changeset_redo = try array.undo(changeset_undo) // a <- b
			XCTAssert(array == array_a)
			
			let _ = try array.undo(changeset_redo) // a -> b
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	// ====================================================================================================
	// MARK: Undo: Combo: remove + X
	// ====================================================================================================

	func test_undo_remove_add() {
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Remove + Add
		
		var array = ZDCArray<String>()
		
		array.append("cow")
		array.append("duck")
		
		array.clearChangeTracking()
		array_a = array
		
		array.remove("cow")
		array.append("dog")
		
		XCTAssert(array.count == 2);
		
		let changeset_undo = array.changeset() ?? Dictionary()
		array_b = array
		
		do {
			let changeset_redo = try array.undo(changeset_undo) // a <- b
			XCTAssert(array == array_a)
			
			let _ = try array.undo(changeset_redo) // a -> b
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_undo_remove_remove() {
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Remove + Remove
		
		var array = ZDCArray<String>()
		
		array.append("cow")
		array.append("duck")
		
		array.clearChangeTracking()
		array_a = array
		
		array.remove("cow")
		array.remove("duck")
		
		XCTAssert(array.count == 0);
		
		let changeset_undo = array.changeset() ?? Dictionary()
		array_b = array
		
		do {
			let changeset_redo = try array.undo(changeset_undo) // a <- b
			XCTAssert(array == array_a)
			
			let _ = try array.undo(changeset_redo) // a -> b
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_undo_remove_insert() {
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Remove + Insert
		
		var array = ZDCArray<String>()
		
		array.append("cow")
		array.append("duck")
		
		array.clearChangeTracking()
		array_a = array
		
		array.remove("cow")
		array.insert("dog", at: 0)
		
		XCTAssert(array.count == 2);
		XCTAssert(array[0] == "dog")
		XCTAssert(array[1] == "duck")
		
		let changeset_undo = array.changeset() ?? Dictionary()
		array_b = array
		
		do {
			let changeset_redo = try array.undo(changeset_undo) // a <- b
			XCTAssert(array == array_a)
			
			let _ = try array.undo(changeset_redo) // a -> b
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_undo_remove_move() {
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Remove + Move
		
		var array = ZDCArray<String>()
		
		array.append("cow")
		array.append("duck")
		array.append("dog")
		
		array.clearChangeTracking()
		array_a = array
		
		array.remove("cow")
		array.move(fromIndex: 0, toIndex: 1)
		
		XCTAssert(array.count == 2)
		XCTAssert(array[0] == "dog")
		XCTAssert(array[1] == "duck")
		
		let changeset_undo = array.changeset() ?? Dictionary()
		array_b = array
		
		do {
			let changeset_redo = try array.undo(changeset_undo) // a <- b
			XCTAssert(array == array_a)
			
			let _ = try array.undo(changeset_redo) // a -> b
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	// ====================================================================================================
	// MARK: Undo: Combo: insert + X
	// ====================================================================================================
	
	func test_undo_insert_add() {
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Insert + Add
		
		var array = ZDCArray<String>()
		
		array.append("cow")
		array.append("duck")
		
		array.clearChangeTracking()
		array_a = array
		
		array.insert("dog", at: 1)
		array.append("cat")
		
		XCTAssert(array.count == 4);
		XCTAssert(array[0] == "cow")
		XCTAssert(array[1] == "dog")
		XCTAssert(array[2] == "duck")
		XCTAssert(array[3] == "cat")
		
		let changeset_undo = array.changeset() ?? Dictionary()
		array_b = array
		
		do {
			let changeset_redo = try array.undo(changeset_undo) // a <- b
			XCTAssert(array == array_a)
			
			let _ = try array.undo(changeset_redo) // a -> b
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_undo_insert_remove() {
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Insert + Remove
		
		var array = ZDCArray<String>()
		
		array.append("cow")
		array.append("duck")
		
		array.clearChangeTracking()
		array_a = array
		
		array.insert("dog", at: 1)
		array.remove("cow")
		
		XCTAssert(array.count == 2);
		XCTAssert(array[0] == "dog")
		XCTAssert(array[1] == "duck")
		
		let changeset_undo = array.changeset() ?? Dictionary()
		array_b = array
		
		do {
			let changeset_redo = try array.undo(changeset_undo) // a <- b
			XCTAssert(array == array_a)
			
			let _ = try array.undo(changeset_redo) // a -> b
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_undo_insert_insert() {
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Insert + Insert
		
		var array = ZDCArray<String>()
		
		array.append("cow")
		array.append("duck")
		
		array.clearChangeTracking()
		array_a = array
		
		array.insert("dog", at: 1)
		array.insert("cat", at: 1)
		
		XCTAssert(array.count == 4)
		XCTAssert(array[0] == "cow")
		XCTAssert(array[1] == "cat")
		XCTAssert(array[2] == "dog")
		XCTAssert(array[3] == "duck")
		
		let changeset_undo = array.changeset() ?? Dictionary()
		array_b = array
		
		do {
			let changeset_redo = try array.undo(changeset_undo) // a <- b
			XCTAssert(array == array_a)
			
			let _ = try array.undo(changeset_redo) // a -> b
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_undo_insert_move_a() {
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Insert + Move
		
		var array = ZDCArray<String>()
		
		array.append("cow")
		array.append("duck")
		
		array.clearChangeTracking()
		array_a = array
		
		array.insert("dog", at: 1)
		array.move(fromIndex: 2, toIndex: 0)
		
		XCTAssert(array.count == 3)
		XCTAssert(array[0] == "duck")
		XCTAssert(array[1] == "cow")
		XCTAssert(array[2] == "dog")
		
		let changeset_undo = array.changeset() ?? Dictionary()
		array_b = array
		
		do {
			let changeset_redo = try array.undo(changeset_undo) // a <- b
			XCTAssert(array == array_a)
			
			let _ = try array.undo(changeset_redo) // a -> b
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_undo_insert_move_b() {
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Insert + Move
		
		var array = ZDCArray<String>()
		
		array.append("cow")
		array.append("duck")
		
		array.clearChangeTracking()
		array_a = array
		
		array.insert("dog", at: 1)
		array.move(fromIndex: 0, toIndex: 2)
		
		XCTAssert(array.count == 3);
		XCTAssert(array[0] == "dog")
		XCTAssert(array[1] == "duck")
		XCTAssert(array[2] == "cow")
		
		let changeset_undo = array.changeset() ?? Dictionary()
		array_b = array
		
		do {
			let changeset_redo = try array.undo(changeset_undo) // a <- b
			XCTAssert(array == array_a)
			
			let _ = try array.undo(changeset_redo) // a -> b
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	// ====================================================================================================
	// MARK: Undo: Combo: move + X
	// ====================================================================================================
	
	func test_undo_move_add() {
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Move + Add
		
		var array = ZDCArray<String>()
		
		array.append("cow")
		array.append("duck")
		
		array.clearChangeTracking()
		array_a = array
		
		array.move(fromIndex: 0, toIndex: 1)
		array.append("dog")
		
		XCTAssert(array.count == 3);
		XCTAssert(array[0] == "duck")
		XCTAssert(array[1] == "cow")
		XCTAssert(array[2] == "dog")
		
		let changeset_undo = array.changeset() ?? Dictionary()
		array_b = array
		
		do {
			let changeset_redo = try array.undo(changeset_undo) // a <- b
			XCTAssert(array == array_a)
			
			let _ = try array.undo(changeset_redo) // a -> b
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_undo_move_remove() {
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Move + Remove
		
		var array = ZDCArray<String>()
		
		array.append("cow")
		array.append("duck")
		
		array.clearChangeTracking()
		array_a = array
		
		array.move(fromIndex: 0, toIndex: 1)
		array.remove("cow")
		
		XCTAssert(array.count == 1);
		XCTAssert(array[0] == "duck")
		
		let changeset_undo = array.changeset() ?? Dictionary()
		array_b = array
		
		do {
			let changeset_redo = try array.undo(changeset_undo) // a <- b
			XCTAssert(array == array_a)
			
			let _ = try array.undo(changeset_redo) // a -> b
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_undo_move_insert() {
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Move + Insert
		
		var array = ZDCArray<String>()
		
		array.append("cow")
		array.append("duck")
		
		array.clearChangeTracking()
		array_a = array
		
		array.move(fromIndex: 0, toIndex: 1)
		array.insert("dog", at: 1)
		
		XCTAssert(array.count == 3);
		XCTAssert(array[0] == "duck")
		XCTAssert(array[1] == "dog")
		XCTAssert(array[2] == "cow")
		
		let changeset_undo = array.changeset() ?? Dictionary()
		array_b = array
		
		do {
			let changeset_redo = try array.undo(changeset_undo) // a <- b
			XCTAssert(array == array_a)
			
			let _ = try array.undo(changeset_redo) // a -> b
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_undo_move_move_a() {
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Move + Move
		
		var array = ZDCArray<String>()
		
		array.append("cow")
		array.append("duck")
		
		array.clearChangeTracking()
		array_a = array
		
		array.move(fromIndex: 0, toIndex: 1)
		array.move(fromIndex: 0, toIndex: 1)
		
		XCTAssert(array[0] == "cow")
		XCTAssert(array[1] == "duck")
		
		let changeset_undo = array.changeset() ?? Dictionary()
		array_b = array
		
		do {
			let changeset_redo = try array.undo(changeset_undo) // a <- b
			XCTAssert(array == array_a)
			
			let _ = try array.undo(changeset_redo) // a -> b
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_undo_move_move_b() {
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Move + Move
		
		var array = ZDCArray<String>()
		
		array.append("cow")
		array.append("duck")
		array.append("dog")
		array.append("cat")
		
		array.clearChangeTracking()
		array_a = array
		
		array.move(fromIndex: 1, toIndex: 3)
		array.move(fromIndex: 2, toIndex: 0)
		
		XCTAssert(array[0] == "cat")
		XCTAssert(array[1] == "cow")
		XCTAssert(array[2] == "dog")
		XCTAssert(array[3] == "duck")
		
		let changeset_undo = array.changeset() ?? Dictionary()
		array_b = array
		
		do {
			let changeset_redo = try array.undo(changeset_undo) // a <- b
			XCTAssert(array == array_a)
			
			let _ = try array.undo(changeset_redo) // a -> b
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_undo_move_move_c() {
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Move + Move
		
		var array = ZDCArray<String>()
		
		array.append("cow")
		array.append("duck")
		array.append("dog")
		array.append("cat")
		
		array.clearChangeTracking()
		array_a = array
		
		array.move(fromIndex: 0, toIndex: 3)
		array.move(fromIndex: 2, toIndex: 1)
		
		let changeset_undo = array.changeset() ?? Dictionary()
		array_b = array
		
		do {
			let changeset_redo = try array.undo(changeset_undo) // a <- b
			XCTAssert(array == array_a)
			
			let _ = try array.undo(changeset_redo) // a -> b
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_undo_move_move_d() {
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		
		// Basic undo/redo functionality.
		//
		// Move + Move
		
		var array = ZDCArray<String>()
		
		array.append("cow")
		array.append("duck")
		array.append("dog")
		array.append("cat")
		
		array.clearChangeTracking()
		array_a = array
		
		array.move(fromIndex: 0, toIndex: 3)
		array.move(fromIndex: 1, toIndex: 2)
		
		XCTAssert(array[0] == "duck")
		XCTAssert(array[1] == "cat")
		XCTAssert(array[2] == "dog")
		XCTAssert(array[3] == "cow")
		
		let changeset_undo = array.changeset() ?? Dictionary()
		array_b = array
		
		do {
			let changeset_redo = try array.undo(changeset_undo) // a <- b
			XCTAssert(array == array_a)
			
			let _ = try array.undo(changeset_redo) // a -> b
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	// ====================================================================================================
	// MARK: Undo: Previous Failures
	// ====================================================================================================

	func test_failure_1() {
		
		// UNIT TEST FAILURE:
		// -----------------
		//
		// Initial array.count: 5
		//
		// removeObjectAtIndex: 3
		// removeObjectAtIndex: 1
		// removeObjectAtIndex: 2
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		
		var array = ZDCArray<String>()
		
		array.append("alice")
		array.append("bob")
		array.append("carol")
		array.append("dave")
		array.append("emily")
		
		array.clearChangeTracking()
		array_a = array
		
		array.remove(at: 3)
		array.remove(at: 1)
		array.remove(at: 2)
		
		let changeset_undo = array.changeset() ?? Dictionary()
		array_b = array
		
		do {
			let changeset_redo = try array.undo(changeset_undo) // a <- b
			XCTAssert(array == array_a)
			
			let _ = try array.undo(changeset_redo) // a -> b
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_failure_2() {
		
		// UNIT TEST FAILURE:
		// -----------------
		//
		// Initial array.count: 5
		//
		// moveObjectAtIndex:1 toIndex:3
		// moveObjectAtIndex:1 toIndex:3
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		
		var array = ZDCArray<String>()
		
		array.append("alice")
		array.append("bob")
		array.append("carol")
		array.append("dave")
		array.append("emily")
		
		array.clearChangeTracking()
		array_a = array
		
		array.move(fromIndex: 1, toIndex:3)
		array.move(fromIndex: 1, toIndex:3)
		
		let changeset_undo = array.changeset() ?? Dictionary()
		array_b = array
		
		do {
			let changeset_redo = try array.undo(changeset_undo) // a <- b
			XCTAssert(array == array_a)
			
			let _ = try array.undo(changeset_redo) // a -> b
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_failure_3() {
		
		// UNIT TEST FAILURE:
		// -----------------
		//
		// Initial array.count: 5
		//
		// moveObjectAtIndex:3 toIndex:2
		// addObject: kizgnvjy
		// moveObjectAtIndex:5 toIndex:0
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		
		var array = ZDCArray<String>()
		
		array.append("alice")
		array.append("bob")
		array.append("carol")
		array.append("dave")
		array.append("emily")
		
		array.clearChangeTracking()
		array_a = array
		
		array.move(fromIndex: 3, toIndex:2)
		array.append("zion")
		array.move(fromIndex: 5, toIndex:0)
		
		let changeset_undo = array.changeset() ?? Dictionary()
		array_b = array
		
		do {
			let changeset_redo = try array.undo(changeset_undo) // a <- b
			XCTAssert(array == array_a)
			
			let _ = try array.undo(changeset_redo) // a -> b
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_failure_4() {
		
		// UNIT TEST FAILURE:
		// -----------------
		//
		// Initial array.count: 5
		//
		// addObject: soktsaod
		// addObject: kugqcgmf
		// moveObjectAtIndex:3 toIndex:6
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		
		var array = ZDCArray<String>()
		
		array.append("alice")
		array.append("bob")
		array.append("carol")
		array.append("dave")
		array.append("emily")
		
		array.clearChangeTracking()
		array_a = array
		
		array.append("xan")
		array.append("zion")
		array.move(fromIndex: 3, toIndex:6)
		
		let changeset_undo = array.changeset() ?? Dictionary()
		array_b = array
		
		do {
			let changeset_redo = try array.undo(changeset_undo) // a <- b
			XCTAssert(array == array_a)
			
			let _ = try array.undo(changeset_redo) // a -> b
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_failure_5() {
		
		// UNIT TEST FAILURE:
		// -----------------
		//
		// Initial array.count: 5
		//
		// moveObjectAtIndex:4 toIndex:1
		// removeObjectAtIndex:0
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		
		var array = ZDCArray<String>()
		
		array.append("alice")
		array.append("bob")
		array.append("carol")
		array.append("dave")
		array.append("emily")
		
		array.clearChangeTracking()
		array_a = array
		
		array.move(fromIndex: 4, toIndex:1)
		array.remove(at: 0)
		
		let changeset_undo = array.changeset() ?? Dictionary()
		array_b = array
		
		do {
			let changeset_redo = try array.undo(changeset_undo) // a <- b
			XCTAssert(array == array_a)
			
			let _ = try array.undo(changeset_redo) // a -> b
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_failure_6() {
		
		// UNIT TEST FAILURE:
		// -----------------
		//
		// Initial array.count: 5
		//
		// removeObjectAtIndex:2
		// moveObjectAtIndex:3 toIndex:0
		// removeObjectAtIndex:3
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		
		var array = ZDCArray<String>()
		
		array.append("alice")
		array.append("bob")
		array.append("carol")
		array.append("dave")
		array.append("emily")
		
		array.clearChangeTracking()
		array_a = array
		
		array.remove(at: 2)
		array.move(fromIndex: 3, toIndex:0)
		array.remove(at: 3)
		
		let changeset_undo = array.changeset() ?? Dictionary()
		array_b = array
		
		do {
			let changeset_redo = try array.undo(changeset_undo) // a <- b
			XCTAssert(array == array_a)
			
			let _ = try array.undo(changeset_redo) // a -> b
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_failure_7() {
		
		// UNIT TEST FAILURE:
		// -----------------
		//
		// Initial array.count: 5
		//
		// removeObjectAtIndex:2
		// moveObjectAtIndex:2 toIndex:3
		// removeObjectAtIndex:3
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		
		var array = ZDCArray<String>()
		
		array.append("alice")
		array.append("bob")
		array.append("carol")
		array.append("dave")
		array.append("emily")
		
		array.clearChangeTracking()
		array_a = array
		
		array.remove(at: 2)
		array.move(fromIndex: 2, toIndex:3)
		array.remove(at: 3)
		
		let changeset_undo = array.changeset() ?? Dictionary()
		array_b = array
		
		do {
			let changeset_redo = try array.undo(changeset_undo) // a <- b
			XCTAssert(array == array_a)
			
			let _ = try array.undo(changeset_redo) // a -> b
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_failure_8() {
		
		// UNIT TEST FAILURE:
		// -----------------
		//
		// Initial array.count: 5
		//
		// moveObjectAtIndex:2 toIndex:4
		// moveObjectAtIndex:2 toIndex:3
		// removeObjectAtIndex:1
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		
		var array = ZDCArray<String>()
		
		array.append("alice")
		array.append("bob")
		array.append("carol")
		array.append("dave")
		array.append("emily")
		
		array.clearChangeTracking()
		array_a = array
		
		array.move(fromIndex: 2, toIndex:4)
		array.move(fromIndex: 2, toIndex:3)
		array.remove(at: 1)
		
		let changeset_undo = array.changeset() ?? Dictionary()
		array_b = array
		
		do {
			let changeset_redo = try array.undo(changeset_undo) // a <- b
			XCTAssert(array == array_a)
			
			let _ = try array.undo(changeset_redo) // a -> b
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_failure_9() {
		
		// Initial array.count: 5
		//
		// addObject: duylyubo
		// moveObjectAtIndex:2 toIndex:5
		// removeObjectAtIndex:4
		// addObject: fmxourgc
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		
		var array = ZDCArray<String>()
		
		array.append("alice")
		array.append("bob")
		array.append("carol")
		array.append("dave")
		array.append("emily")
		
		array.clearChangeTracking()
		array_a = array
		
		array.append("frank")
		array.move(fromIndex: 2, toIndex:5)
		array.remove(at: 4)
		array.append("gwen")
		
		let changeset_undo = array.changeset() ?? Dictionary()
		array_b = array
		
		do {
			let changeset_redo = try array.undo(changeset_undo) // a <- b
			XCTAssert(array == array_a)
			
			let _ = try array.undo(changeset_redo) // a -> b
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	// ====================================================================================================
	// MARK: Undo: Fuzz: Basic
	// ====================================================================================================

	func test_undo_fuzz_add() {
		
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var array_a: ZDCArray<String>? = nil
			var array_b: ZDCArray<String>? = nil
			
			var array = ZDCArray<String>()
			
			// Start with an object that has a random number of objects [0 - 10)
			do {
				let startCount = Int(arc4random_uniform(UInt32(10)))
			
				for _ in 0 ..< startCount {
					
					let key = self.randomLetters(8)
					array.append(key)
				}
			}
			
			array.clearChangeTracking()
			array_a = array
			
			// Now add a random number of object [1 - 10)
			do {
				let changeCount = 1 + Int(arc4random_uniform(UInt32(9)))
				
				for _ in 0 ..< changeCount {
					
					let key = self.randomLetters(8)
					array.append(key)
				}
			}
			
			let changeset_undo = array.changeset() ?? Dictionary()
			array_b = array
			
			do {
				let changeset_redo = try array.undo(changeset_undo) // a <- b
				XCTAssert(array == array_a)
				
				let _ = try array.undo(changeset_redo) // a -> b
				XCTAssert(array == array_b)
			}
			catch {
				XCTAssert(false)
				print("Threw error: \(error)")
			}
		}}
	}

	func test_undo_fuzz_remove() {
		
		let DEBUG_THIS_METHOD = false
		
		for _ in 0 ..< 1_000 { autoreleasepool {
		
			var array_a: ZDCArray<String>? = nil
			var array_b: ZDCArray<String>? = nil
			
			var array = ZDCArray<String>()
			
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
					array.append(key)
				}
			}
			
			if DEBUG_THIS_METHOD {
				print("Initial array.count: \(array.count)")
			}
			
			array.clearChangeTracking()
			array_a = array
			
			// Now remove a random number of object [1 - 15)
			do {
				
				var changeCount: Int
				if DEBUG_THIS_METHOD {
					changeCount = 3
				} else {
					changeCount = 1 + Int(arc4random_uniform(UInt32(14)))
				}
				
				for _ in 0 ..< changeCount {
					
					let idx = Int(arc4random_uniform(UInt32(array.count)))
					
					if DEBUG_THIS_METHOD {
						print("removeObjectAtIndex: \(idx)")
					}
					if (array.count > 0) {
						array.remove(at: idx)
					}
				}
			}
			
			let changeset_undo = array.changeset() ?? Dictionary()
			array_b = array
			
			do {
				let changeset_redo = try array.undo(changeset_undo) // a <- b
				if DEBUG_THIS_METHOD && (array != array_a) {
					print("It's going to FAIL")
				}
				XCTAssert(array == array_a)
				
				let _ = try array.undo(changeset_redo) // a -> b
				if DEBUG_THIS_METHOD && (array != array_b) {
					print("It's going to FAIL")
				}
				XCTAssert(array == array_b)
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

	func test_undo_fuzz_insert() {
		
		let DEBUG_THIS_METHOD = false
		
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var array_a: ZDCArray<String>? = nil
			var array_b: ZDCArray<String>? = nil
			
			var array = ZDCArray<String>()
			
			// Start with an object that has a random number of objects [0 - 10)
			do {
				let startCount = Int(arc4random_uniform(UInt32(10)))
				
				for _ in 0 ..< startCount {
					
					let key = self.randomLetters(8)
					array.append(key)
				}
			}
			
			if DEBUG_THIS_METHOD {
				print("Initial array.count: \(array.count)")
			}
			
			array.clearChangeTracking()
			array_a = array
			
			// Now insert a random number of object [1 - 10)
			do {
				let changeCount = 1 + Int(arc4random_uniform(UInt32(9)))
				
				for _ in 0 ..< changeCount {
					
					let key = self.randomLetters(8)
					let idx = Int(arc4random_uniform(UInt32(array.count)))
					
					if DEBUG_THIS_METHOD {
						print("insertObject:\(key) atIndex:\(idx)")
					}
					array.insert(key, at: idx)
				}
			}
			
			let changeset_undo = array.changeset() ?? Dictionary()
			array_b = array
			
			do {
				let changeset_redo = try array.undo(changeset_undo) // a <- b
				if DEBUG_THIS_METHOD && (array != array_a) {
					print("It's going to FAIL")
				}
				XCTAssert(array == array_a)
				
				let _ = try array.undo(changeset_redo) // a -> b
				if DEBUG_THIS_METHOD && (array != array_b) {
					print("It's going to FAIL")
				}
				XCTAssert(array == array_b)
		
				if DEBUG_THIS_METHOD {
					print("-------------------------------------------------")
				}
			}
			catch {
				XCTAssert(false)
				print("Threw error: \(error)")
			}
		}}
	}

	func test_undo_fuzz_move() {
		
		let DEBUG_THIS_METHOD = false
		
		for _ in 0 ..< 1_000 { autoreleasepool {
			var array_a: ZDCArray<String>? = nil
			var array_b: ZDCArray<String>? = nil
			
			var array = ZDCArray<String>()
			
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
					array.append(key)
				}
			}
			
			if DEBUG_THIS_METHOD {
				print("Initial array.count: \(array.count)")
			}
			
			array.clearChangeTracking()
			array_a = array
			
			// Now make a random number of moves: [1 - 30)
			
			var changeCount: Int
			if DEBUG_THIS_METHOD {
				changeCount = 2
			} else {
				changeCount = 1 + Int(arc4random_uniform(UInt32(29)))
			}
			
			for _ in 0 ..< changeCount {
				
				let oldIdx = Int(arc4random_uniform(UInt32(array.count)))
				let newIdx = Int(arc4random_uniform(UInt32(array.count)))
				
				if DEBUG_THIS_METHOD {
					print("moveObjectAtIndex:\(oldIdx) toIndex:\(newIdx)")
				}
				if (array.count > 0) {
					array.move(fromIndex: oldIdx, toIndex: newIdx)
				}
			}
			
			let changeset_undo = array.changeset() ?? Dictionary()
			array_b = array
			
			do {
				let changeset_redo = try array.undo(changeset_undo) // a <- b
				if DEBUG_THIS_METHOD && (array != array_a) {
					print("It's going to FAIL")
				}
				XCTAssert(array == array_a)
				
				let _ = try array.undo(changeset_redo) // a -> b
				if DEBUG_THIS_METHOD && (array != array_b) {
				print("It's going to FAIL")
				}
				XCTAssert(array == array_b)
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
	// MARK: Undo: Fuzz: Combo: add + x
	// ====================================================================================================

	func test_undo_fuzz_add_remove() {
		
		let DEBUG_THIS_METHOD = false
		
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var array_a: ZDCArray<String>? = nil
			var array_b: ZDCArray<String>? = nil
			
			var array = ZDCArray<String>()
			
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
					array.append(key)
				}
			}
			
			if DEBUG_THIS_METHOD {
				print("Initial array.count: \(array.count)")
			}
			
			array.clearChangeTracking()
			array_a = array
			
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
						print("addObject: \(key)")
					}
					array.append(key)
				}
				else
				{
					// Remove an item
					
					let idx = Int(arc4random_uniform(UInt32(array.count)))
					
					if DEBUG_THIS_METHOD {
						print("removeObjectAtIndex: \(idx)")
					}
					if (array.count > 0) {
						array.remove(at: idx)
					}
				}
			}
			
			let changeset_undo = array.changeset() ?? Dictionary()
			array_b = array
			
			do {
				let changeset_redo = try array.undo(changeset_undo) // a <- b
				if (DEBUG_THIS_METHOD && (array != array_a)) {
					print("It's going to FAIL")
				}
				XCTAssert(array == array_a)
				
				let _ = try array.undo(changeset_redo) // a -> b
				if DEBUG_THIS_METHOD && (array != array_b) {
					print("It's going to FAIL")
				}
				XCTAssert(array == array_b)
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
			
			var array_a: ZDCArray<String>? = nil
			var array_b: ZDCArray<String>? = nil
			
			var array = ZDCArray<String>()
			
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
					array.append(key)
				}
			}
			
			if DEBUG_THIS_METHOD {
				print("Initial array.count: \(array.count)")
			}
			
			array.clearChangeTracking()
			array_a = array
			
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
						print("addObject: \(key)")
					}
					array.append(key)
				}
				else
				{
					// Insert an item
					
					let key = self.randomLetters(8)
					let idx = Int(arc4random_uniform(UInt32(array.count)))
					
					if DEBUG_THIS_METHOD {
						print("insertObject:\(key) atIndex:\(idx)")
					}
					array.insert(key, at: idx)
				}
			}
			
			let changeset_undo = array.changeset() ?? Dictionary()
			array_b = array
			
			do {
				let changeset_redo = try array.undo(changeset_undo) // a <- b
				if DEBUG_THIS_METHOD && (array != array_a) {
					print("It's going to FAIL")
				}
				XCTAssert(array == array_a)
				
				let _ = try array.undo(changeset_redo) // a -> b
				if DEBUG_THIS_METHOD && (array != array_b) {
					print("It's going to FAIL")
				}
				XCTAssert(array == array_b)
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
		
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var array_a: ZDCArray<String>? = nil
			var array_b: ZDCArray<String>? = nil
			
			var array = ZDCArray<String>()
			
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
					array.append(key)
				}
			}
				
			if DEBUG_THIS_METHOD {
				print("Initial array.count: \(array.count)")
			}
			
			array.clearChangeTracking()
			array_a = array
			
			// Now make a random number of changes: [1 - 30)
			
			var changeCount: Int
			if DEBUG_THIS_METHOD {
				changeCount = 3
			} else {
				changeCount = 1 + Int(arc4random_uniform(UInt32(29)))
			}
			
			for _ in 0 ..< changeCount {
				
				if (arc4random_uniform(UInt32(2)) == 0)
				{
					// Add an item
					
					let key = self.randomLetters(8)
					
					if DEBUG_THIS_METHOD {
						print("addObject: \(key)")
					}
					array.append(key)
				}
				else
				{
					// Move an item
					
					let oldIdx = Int(arc4random_uniform(UInt32(array.count)))
					let newIdx = Int(arc4random_uniform(UInt32(array.count)))
			
					if DEBUG_THIS_METHOD {
						print("moveObjectAtIndex:\(oldIdx) toIndex:\(newIdx)")
					}
					if (array.count > 0) {
						array.move(fromIndex: oldIdx, toIndex: newIdx)
					}
				}
			}
			
			let changeset_undo = array.changeset() ?? Dictionary()
			array_b = array
			
			do {
				let changeset_redo = try array.undo(changeset_undo) // a <- b
				if (DEBUG_THIS_METHOD && (array != array_a)) {
					print("It's going to FAIL")
				}
				XCTAssert(array == array_a)
				
				let _ = try array.undo(changeset_redo) // a -> b
				if DEBUG_THIS_METHOD && (array != array_b) {
					print("It's going to FAIL")
				}
				XCTAssert(array == array_b)
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
	// MARK: Undo: Fuzz: Combo: remove + x
	// ====================================================================================================
	
	func test_undo_fuzz_remove_insert() {
		
		let DEBUG_THIS_METHOD = false
		
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var array_a: ZDCArray<String>? = nil
			var array_b: ZDCArray<String>? = nil
			
			var array = ZDCArray<String>()
			
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
					array.append(key)
				}
			}
				
			if DEBUG_THIS_METHOD {
				print("Initial array.count: \(array.count)")
			}
			
			array.clearChangeTracking()
			array_a = array
			
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
					
					let idx = Int(arc4random_uniform(UInt32(array.count)))
					
					if DEBUG_THIS_METHOD {
						print("removeObjectAtIndex:\(idx)")
					}
					if (array.count > 0) {
						array.remove(at: idx)
					}
				}
				else
				{
					// Insert an item
					
					let key = self.randomLetters(8)
					let idx = Int(arc4random_uniform(UInt32(array.count)))
					
					if DEBUG_THIS_METHOD {
						print("insertObject:forKey:\(key) atIndex:\(idx)")
					}
					array.insert(key, at: idx)
				}
			}
			
			let changeset_undo = array.changeset() ?? Dictionary()
			array_b = array
			
			do {
				let changeset_redo = try array.undo(changeset_undo) // a <- b
				if DEBUG_THIS_METHOD && (array != array_a) {
					print("It's going to FAIL")
				}
				XCTAssert(array == array_a)
				
				let _ = try array.undo(changeset_redo) // a -> b
				if DEBUG_THIS_METHOD && (array != array_b) {
					print("It's going to FAIL")
				}
				XCTAssert(array == array_b)
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
			
			var array_a: ZDCArray<String>? = nil
			var array_b: ZDCArray<String>? = nil
			
			var array = ZDCArray<String>()
			
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
					array.append(key)
				}
			}
			
			if DEBUG_THIS_METHOD {
				print("Initial array.count: \(array.count)")
			}
			
			array.clearChangeTracking()
			array_a = array
			
			// Now make a random number of changes: [1 - 30)
			
			var changeCount: Int
			if DEBUG_THIS_METHOD {
				changeCount = 9
			} else {
				changeCount = 1 + Int(arc4random_uniform(UInt32(29)))
			}
			
			for _ in 0 ..< changeCount {
				
				if (arc4random_uniform(UInt32(2)) == 0)
				{
					// Remove an item
					
					let idx = Int(arc4random_uniform(UInt32(array.count)))
					
					if DEBUG_THIS_METHOD {
						print("removeObjectAtIndex:\(idx)")
					}
					if (array.count > 0) {
						array.remove(at: idx)
					}
				}
				else
				{
					// Move an item
					
					let oldIdx = Int(arc4random_uniform(UInt32(array.count)))
					let newIdx = Int(arc4random_uniform(UInt32(array.count)))
					
					if DEBUG_THIS_METHOD {
						print("moveObjectAtIndex:\(oldIdx) toIndex:\(newIdx)")
					}
					if (array.count > 0) {
						array.move(fromIndex: oldIdx, toIndex: newIdx)
					}
				}
			}
			
			let changeset_undo = array.changeset() ?? Dictionary()
			array_b = array
			
			do {
				let changeset_redo = try array.undo(changeset_undo) // a <- b
				if DEBUG_THIS_METHOD && (array != array_a) {
					print("It's going to FAIL")
				}
				XCTAssert(array == array_a)
				
				let _ = try array.undo(changeset_redo) // a -> b
				if DEBUG_THIS_METHOD && (array != array_b) {
					print("It's going to FAIL")
				}
				XCTAssert(array == array_b)
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
	// MARK: Undo: Fuzz: Combo: insert + x
	// ====================================================================================================

	func test_undo_fuzz_insert_move() {
		
		let DEBUG_THIS_METHOD = false
		
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var array_a: ZDCArray<String>? = nil
			var array_b: ZDCArray<String>? = nil
			
			var array = ZDCArray<String>()
			
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
					array.append(key)
				}
			}
			
			array.clearChangeTracking()
			array_a = array
			
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
					let idx = Int(arc4random_uniform(UInt32(array.count)))
					
					if DEBUG_THIS_METHOD {
						print("insertObject:forKey:\(key) atIndex:\(idx)")
					}
					array.insert(key, at: idx)
				}
				else
				{
					// Move an item
					
					let oldIdx = Int(arc4random_uniform(UInt32(array.count)))
					let newIdx = Int(arc4random_uniform(UInt32(array.count)))
					
					if DEBUG_THIS_METHOD {
						print("moveObjectAtIndex:\(oldIdx) toIndex:\(newIdx)")
					}
					if (array.count > 0) {
						array.move(fromIndex: oldIdx, toIndex: newIdx)
					}
				}
			}
			
			let changeset_undo = array.changeset() ?? Dictionary()
			array_b = array
			
			do {
				let changeset_redo = try array.undo(changeset_undo) // a <- b
				if DEBUG_THIS_METHOD && (array != array_a) {
					print("It's going to FAIL")
				}
				XCTAssert(array == array_a)
				
				let _ = try array.undo(changeset_redo) // a -> b
				if DEBUG_THIS_METHOD && (array != array_b) {
					print("It's going to FAIL")
				}
				XCTAssert(array == array_b)
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
	// MARK: Undo: Fuzz: Triplets
	// ====================================================================================================
	
	func test_undo_fuzz_add_remove_insert() {
		
		let DEBUG_THIS_METHOD = false
		
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var array_a: ZDCArray<String>? = nil
			var array_b: ZDCArray<String>? = nil
			
			var array = ZDCArray<String>()
			
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
					array.append(key)
				}
			}
			
			array.clearChangeTracking()
			array_a = array
			
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
						print("setObject:withKey: \(key) (idx=\(array.count))")
					}
					array.append(key)
				}
				else if (random == 1)
				{
					// Remove an item
					
					let idx = Int(arc4random_uniform(UInt32(array.count)))
					
					if DEBUG_THIS_METHOD {
						print("removeObjectAtIndex:\(idx)")
					}
					if (array.count > 0) {
						array.remove(at: idx)
					}
				}
				else
				{
					// Insert an item
					
					let key = self.randomLetters(8)
					let idx = Int(arc4random_uniform(UInt32(array.count)))
					
					if DEBUG_THIS_METHOD {
						print("insertObject:forKey:\(key) atIndex:\(idx)")
					}
					array.insert(key, at: idx)
				}
			}
			
			let changeset_undo = array.changeset() ?? Dictionary()
			array_b = array
			
			do {
				let changeset_redo = try array.undo(changeset_undo) // a <- b
				if DEBUG_THIS_METHOD && (array != array_a) {
					print("It's going to FAIL")
				}
				XCTAssert(array == array_a)
				
				let _ = try array.undo(changeset_redo) // a -> b
				if DEBUG_THIS_METHOD && (array != array_b) {
					print("It's going to FAIL")
				}
				XCTAssert(array == array_b)
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
			
			var array_a: ZDCArray<String>? = nil
			var array_b: ZDCArray<String>? = nil
			
			var array = ZDCArray<String>()
			
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
					array.append(key)
				}
			}
			
			if DEBUG_THIS_METHOD {
				print("Initial array.count: \(array.count)")
			}
			
			array.clearChangeTracking()
			array_a = array
			
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
						print("addObject: \(key)")
					}
					array.append(key)
				}
				else if (random == 1)
				{
					// Remove an item
					
					let idx = Int(arc4random_uniform(UInt32(array.count)))
					
					if DEBUG_THIS_METHOD {
						print("removeObjectAtIndex:\(idx)")
					}
					if (array.count > 0) {
						array.remove(at: idx)
					}
				}
				else
				{
					// Move an item
					
					let oldIdx = Int(arc4random_uniform(UInt32(array.count)))
					let newIdx = Int(arc4random_uniform(UInt32(array.count)))
					
					if DEBUG_THIS_METHOD {
						print("moveObjectAtIndex:\(oldIdx) toIndex:\(newIdx)")
					}
					if (array.count > 0) {
						array.move(fromIndex: oldIdx, toIndex: newIdx)
					}
				}
			}
			
			let changeset_undo = array.changeset() ?? Dictionary()
			array_b = array
			
			do {
				let changeset_redo = try array.undo(changeset_undo) // a <- b
				if DEBUG_THIS_METHOD && (array != array_a) {
					print("It's going to FAIL")
				}
				XCTAssert(array == array_a)
				
				let _ = try array.undo(changeset_redo) // a -> b
				if DEBUG_THIS_METHOD && (array != array_b) {
					print("It's going to FAIL")
				}
				XCTAssert(array == array_b)
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
			
			var array_a: ZDCArray<String>? = nil
			var array_b: ZDCArray<String>? = nil
			
			var array = ZDCArray<String>()
			
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
					array.append(key)
				}
			}
			
			array.clearChangeTracking()
			array_a = array
			
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
						print("setObject:withKey:\(key) (idx=\(array.count))")
					}
					array.append(key)
				}
				else if (random == 1)
				{
					// Insert an item
					
					let key = self.randomLetters(8)
					let idx = Int(arc4random_uniform(UInt32(array.count)))
					
					if DEBUG_THIS_METHOD {
						print("insertObject:forKey:\(key) atIndex:\(idx)")
					}
					array.insert(key, at: idx)
				}
				else
				{
					// Move an item
					
					let oldIdx = Int(arc4random_uniform(UInt32(array.count)))
					let newIdx = Int(arc4random_uniform(UInt32(array.count)))
					
					if DEBUG_THIS_METHOD {
						print("moveObjectAtIndex:\(oldIdx) toIndex:\(newIdx)")
					}
					if (array.count > 0) {
						array.move(fromIndex: oldIdx, toIndex: newIdx)
					}
				}
			}
			
			let changeset_undo = array.changeset() ?? Dictionary()
			array_b = array
			
			do {
				let changeset_redo = try array.undo(changeset_undo) // a <- b
				if (DEBUG_THIS_METHOD && (array != array_a)) {
					print("It's going to FAIL")
				}
				XCTAssert(array == array_a)
				
				let _ = try array.undo(changeset_redo) // a -> b
				if DEBUG_THIS_METHOD && (array != array_b) {
					print("It's going to FAIL")
				}
				XCTAssert(array == array_b)
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
			
			var array_a: ZDCArray<String>? = nil
			var array_b: ZDCArray<String>? = nil
			
			var array = ZDCArray<String>()
			
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
					array.append(key)
				}
			}
			
			array.clearChangeTracking()
			array_a = array
			
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
					
					let idx = Int(arc4random_uniform(UInt32(array.count)))
					
					if DEBUG_THIS_METHOD {
						print("removeObjectAtIndex:\(idx)")
					}
					if (array.count > 0) {
						array.remove(at: idx)
					}
				}
				else if (random == 1)
				{
					// Insert an item
					
					let key = self.randomLetters(8)
					let idx = Int(arc4random_uniform(UInt32(array.count)))
					
					if DEBUG_THIS_METHOD {
						print("insertObject:\(key) atIndex:\(idx)")
					}
					array.insert(key, at: idx)
				}
				else
				{
					// Move an item
					
					let oldIdx = Int(arc4random_uniform(UInt32(array.count)))
					let newIdx = Int(arc4random_uniform(UInt32(array.count)))
					
					if DEBUG_THIS_METHOD {
						print("moveObjectAtIndex:\(oldIdx) toIndex:\(newIdx)")
					}
					if (array.count > 0) {
						array.move(fromIndex: oldIdx, toIndex: newIdx)
					}
				}
			}
			
			let changeset_undo = array.changeset() ?? Dictionary()
			array_b = array
			
			do {
				let changeset_redo = try array.undo(changeset_undo) // a <- b
				if DEBUG_THIS_METHOD && (array != array_a) {
					print("It's going to FAIL")
				}
				XCTAssert(array == array_a)
				
				let _ = try array.undo(changeset_redo) // a -> b
				if DEBUG_THIS_METHOD && (array != array_b) {
					print("It's going to FAIL")
				}
				XCTAssert(array == array_b)
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
	// MARK: Undo: Fuzz: Everything
	// ====================================================================================================
	
	func test_undo_fuzz_everything() {
		
		let DEBUG_THIS_METHOD = false
		
		for _ in 0 ..< 5_000 { autoreleasepool {
			
			var array_a: ZDCArray<String>? = nil
			var array_b: ZDCArray<String>? = nil
			
			var array = ZDCArray<String>()
			
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
					array.append(key)
				}
			}
			
			array.clearChangeTracking()
			array_a = array
			
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
						print("addObject: \(key)")
					}
					array.append(key)
				}
				else if (random == 1)
				{
					// Remove an item
					
					let idx = Int(arc4random_uniform(UInt32(array.count)))
					
					if DEBUG_THIS_METHOD {
						print("removeObjectAtIndex:\(idx)")
					}
					if (array.count > 0) {
						array.remove(at: idx)
					}
				}
				else if (random == 2)
				{
					// Modify an item
					
					let idx = Int(arc4random_uniform(UInt32(array.count)))
					let value = self.randomLetters(4)
					
					if DEBUG_THIS_METHOD {
						print("modify:\(idx) value:\(value)")
					}
					array[idx] = value
				}
				else if (random == 3)
				{
					// Insert an item
					
					let key = self.randomLetters(8)
					let idx = Int(arc4random_uniform(UInt32(array.count)))
					
					if DEBUG_THIS_METHOD {
						print("insertObject:\(key) atIndex:\(idx)")
					}
					array.insert(key, at: idx)
				}
				else
				{
					// Move an item
					
					let oldIdx = Int(arc4random_uniform(UInt32(array.count)))
					let newIdx = Int(arc4random_uniform(UInt32(array.count)))
					
					if DEBUG_THIS_METHOD {
						print("moveObjectAtIndex:\(oldIdx) toIndex:\(newIdx)")
					}
					if (array.count > 0) {
						array.move(fromIndex: oldIdx, toIndex: newIdx)
					}
				}
			}
			
			let changeset_undo = array.changeset() ?? Dictionary()
			array_b = array
			
			do {
				let changeset_redo = try array.undo(changeset_undo) // a <- b
				if DEBUG_THIS_METHOD && (array != array_a) {
					print("It's going to FAIL")
				}
				XCTAssert(array == array_a)
				
				let _ = try array.undo(changeset_redo) // a -> b
				if DEBUG_THIS_METHOD && (array != array_b) {
					print("It's going to FAIL")
				}
				XCTAssert(array == array_b)
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
	// MARK:- Import: Basic
	// ====================================================================================================
	
	func test_import_basic_1() {
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		var changesets: [ZDCChangeset] = []
	
		var array = ZDCArray<String>()
	
		// Empty dictionary will be starting state
		array_a = array
	
		do { // changeset: A
	
			array.append("cow")
			array.append("duck")
	
			changesets.append(array.changeset() ?? Dictionary())
		}
		do { // changeset: B
	
			array.append("dog")
			array.append("cat")
	
			changesets.append(array.changeset() ?? Dictionary())
		}
	
		array_b = array
	
		do {
			try array.importChangesets(changesets)
			XCTAssert(array == array_b)
			
			let changeset_merged = array.changeset() ?? Dictionary()
			
			let changeset_redo = try array.undo(changeset_merged)
			XCTAssert(array == array_a)
			
			let _ = try array.undo(changeset_redo)
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_import_basic_2() {
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		var changesets: [ZDCChangeset] = []
	
		var array = ZDCArray<String>()
	
		array.append("cow")
		array.append("duck")
		array.append("dog")
		array.append("cat")
	
		array.clearChangeTracking()
		array_a = array
	
		do { // changeset: A
	
			array.remove(at: 0)
	
			changesets.append(array.changeset() ?? Dictionary())
		}
		do { // changeset: B
	
			array.remove(at: 0)
			array.remove(at: 0)
	
			changesets.append(array.changeset() ?? Dictionary())
		}
	
		array_b = array
	
		do {
			try array.importChangesets(changesets)
			XCTAssert(array == array_b)
			
			let changeset_merged = array.changeset() ?? Dictionary()
			
			let changeset_redo = try array.undo(changeset_merged)
			XCTAssert(array == array_a)
			
			let _ = try array.undo(changeset_redo)
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_import_basic_3() {
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		var changesets: [ZDCChangeset] = []
	
		var array = ZDCArray<String>()
	
		array.append("cow")
	
		array.clearChangeTracking()
		array_a = array
	
		do { // changeset: A
	
			array.insert("duck", at: 0)
	
			changesets.append(array.changeset() ?? Dictionary())
		}
		do { // changeset: B
	
			array.insert("dog", at: 1)
			array.insert("cat", at: 0)
	
			changesets.append(array.changeset() ?? Dictionary())
		}
	
		array_b = array
	
		do {
			try array.importChangesets(changesets)
			XCTAssert(array == array_b)
			
			let changeset_merged = array.changeset() ?? Dictionary()
			
			let changeset_redo = try array.undo(changeset_merged)
			XCTAssert(array == array_a)
			
			let _ = try array.undo(changeset_redo)
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_import_basic_4() {
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		var changesets: [ZDCChangeset] = []
	
		var array = ZDCArray<String>()
	
		array.append("cow")
		array.append("duck")
		array.append("dog")
		array.append("cat")
	
		array.clearChangeTracking()
		array_a = array
	
		do { // changeset: A
	
			array.move(fromIndex: 2, toIndex: 3) // dog
	
			changesets.append(array.changeset() ?? Dictionary())
		}
		do { // changeset: B
	
			array.move(fromIndex: 2, toIndex:0) // cat
			array.move(fromIndex: 3, toIndex:2) // dog
	
			changesets.append(array.changeset() ?? Dictionary())
		}
	
		array_b = array
	
		do {
			try array.importChangesets(changesets)
			XCTAssert(array == array_b)
		
			let changeset_merged = array.changeset() ?? Dictionary()
		
			let changeset_redo = try array.undo(changeset_merged)
			XCTAssert(array == array_a)
		
			let _ = try array.undo(changeset_redo)
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	// ====================================================================================================
	// MARK: Import: Failures
	// ====================================================================================================

	func test_import_failure_1() {
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		var changesets: [ZDCChangeset] = []
	
		var array = ZDCArray<String>()
	
		// UNIT TEST FAILURE:
		// -----------------
		//
		// Initial array.count: 5
		//
		// moveObjectAtIndex:0 toIndex:1
		// ********************
		// moveObjectAtIndex:0 toIndex:3
		// ********************
	
		array.append("alice")
		array.append("bob")
		array.append("carol")
		array.append("dave")
		array.append("emily")
	
		array.clearChangeTracking()
		array_a = array
	
		do { // changeset: A
	
			array.move(fromIndex: 0, toIndex: 1)
	
			changesets.append(array.changeset() ?? Dictionary())
		}
		do { // changeset: B
	
			array.move(fromIndex: 0, toIndex: 3)
	
			changesets.append(array.changeset() ?? Dictionary())
		}
	
		array_b = array
	
		do {
			try array.importChangesets(changesets)
			XCTAssert(array == array_b)
		
			let changeset_merged = array.changeset() ?? Dictionary()
		
			let changeset_redo = try array.undo(changeset_merged)
			XCTAssert(array == array_a)
		
			let _ = try array.undo(changeset_redo)
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_import_failure_2() {
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		var changesets: [ZDCChangeset] = []
	
		var array = ZDCArray<String>()
	
		// UNIT TEST FAILURE:
		// -----------------
		//
		// Initial array.count: 5
		//
		// moveObjectAtIndex:0 toIndex:3
		// moveObjectAtIndex:2 toIndex:2
		// ********************
		// moveObjectAtIndex:4 toIndex:3
		// moveObjectAtIndex:0 toIndex:3
		// ********************
	
		array.append("alice")
		array.append("bob")
		array.append("carol")
		array.append("dave")
		array.append("emily")
	
		array.clearChangeTracking()
		array_a = array
	
		do { // changeset: A
	
			array.move(fromIndex: 0, toIndex: 3)
			array.move(fromIndex: 2, toIndex: 2)
	
			changesets.append(array.changeset() ?? Dictionary())
		}
		do { // changeset: B
	
			array.move(fromIndex: 4, toIndex: 3)
			array.move(fromIndex: 0, toIndex: 3)
	
			changesets.append(array.changeset() ?? Dictionary())
		}
	
		array_b = array
	
		do {
			try array.importChangesets(changesets)
			XCTAssert(array == array_b)
		
			let changeset_merged = array.changeset() ?? Dictionary()
		
			let changeset_redo = try array.undo(changeset_merged)
			XCTAssert(array == array_a)
		
			let _ = try array.undo(changeset_redo)
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_import_failure_3() {
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		var changesets: [ZDCChangeset] = []
	
		var array = ZDCArray<String>()
	
		// UNIT TEST FAILURE:
		// -----------------
		//
		// Initial array.coun: 5
		//
		// addObject: ftjnwyqy
		// moveObjectAtIndex:3 toIndex:4
		// ********************
		// insertObject:atIndex:3
		// moveObjectAtIndex:2 toIndex:6
		// ********************
	
		array.append("alice")
		array.append("bob")
		array.append("carol")
		array.append("dave")
		array.append("emily")
	
		array.clearChangeTracking()
		array_a = array
	
		do { // changeset: A
	
			array.append("frank")
			array.move(fromIndex: 3, toIndex: 4)
	
			changesets.append(array.changeset() ?? Dictionary())
		}
		do { // changeset: B
	
			array.insert("gwen", at: 3)
			array.move(fromIndex: 2, toIndex: 6)
	
			changesets.append(array.changeset() ?? Dictionary())
		}
	
		array_b = array
	
		do {
			try array.importChangesets(changesets)
			XCTAssert(array == array_b)
		
			let changeset_merged = array.changeset() ?? Dictionary()
		
			let changeset_redo = try array.undo(changeset_merged)
			XCTAssert(array == array_a)
		
			let _ = try array.undo(changeset_redo)
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

	func test_import_failure_4() {
		
		var array_a: ZDCArray<String>? = nil
		var array_b: ZDCArray<String>? = nil
		var changesets: [ZDCChangeset] = []
	
		var array = ZDCArray<String>()
	
		// UNIT TEST FAILURE:
		// -----------------
		//
		// Initial array.count: 5
		//
		// moveObjectAtIndex:2 toIndex:1
		// addObject: opiimkhy
		// ********************
		// removeObjectAtIndex:3
		// moveObjectAtIndex:4 toIndex:1
		// ********************
	
		array.append("alice")
		array.append("bob")
		array.append("carol")
		array.append("dave")
		array.append("emily")
	
		array.clearChangeTracking()
		array_a = array
	
		do { // changeset: A
	
			array.move(fromIndex: 2, toIndex: 1)
			array.append("frank")
	
			changesets.append(array.changeset() ?? Dictionary())
		}
		do { // changeset: B
	
			array.remove(at: 3)
			array.move(fromIndex: 4, toIndex: 1)
	
			changesets.append(array.changeset() ?? Dictionary())
		}
	
		array_b = array
	
		do {
			try array.importChangesets(changesets)
			XCTAssert(array == array_b)
		
			let changeset_merged = array.changeset() ?? Dictionary()
		
			let changeset_redo = try array.undo(changeset_merged)
			XCTAssert(array == array_a)
		
			let _ = try array.undo(changeset_redo)
			XCTAssert(array == array_b)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Import: Fuzz: Basic
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	func test_import_fuzz_add() {
		
		let DEBUG_THIS_METHOD = false
	
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var array_a: ZDCArray<String>? = nil
			var array_b: ZDCArray<String>? = nil
			var changesets: [ZDCChangeset] = []
	
			var array = ZDCArray<String>()
	
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
					array.append(key)
				}
			}
	
			array.clearChangeTracking()
			array_a = array
	
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
						print("addObject: \(key)")
					}
					array.append(key)
				}
	
				changesets.append(array.changeset() ?? Dictionary())
	
				if DEBUG_THIS_METHOD {
					print("********************")
				}
			}
	
			array_b = array
	
			do {
				try array.importChangesets(changesets)
				XCTAssert(array == array_b)
		
				let changeset_merged = array.changeset() ?? Dictionary()
		
				let changeset_redo = try array.undo(changeset_merged)
				if DEBUG_THIS_METHOD && (array != array_a) {
					print("It's going to FAIL");
				}
				XCTAssert(array == array_a)
		
				let _ = try array.undo(changeset_redo)
				if DEBUG_THIS_METHOD && (array != array_b) {
					print("It's going to FAIL");
				}
				XCTAssert(array == array_b)
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
			
			var array_a: ZDCArray<String>? = nil
			var array_b: ZDCArray<String>? = nil
			var changesets: [ZDCChangeset] = []
	
			var array = ZDCArray<String>()
	
			// Start with an object that has a random number of objects [20 - 30)
			do {
				
				var startCount: Int
				if DEBUG_THIS_METHOD {
					startCount = 10
				} else {
					startCount = 20 + Int(arc4random_uniform(UInt32(10)))
				}
	
				for _ in 0 ..< startCount{
					
					let key = self.randomLetters(8)
					array.append(key)
				}
			}
	
			array.clearChangeTracking()
			array_a = array
	
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
	
					let idx = Int(arc4random_uniform(UInt32(array.count)))
	
					if DEBUG_THIS_METHOD {
						print("removeObjectAtIndex:\(idx)")
					}
					if (array.count > 0) {
						array.remove(at: idx)
					}
				}
	
				changesets.append(array.changeset() ?? Dictionary())
	
				if DEBUG_THIS_METHOD {
					print("********************")
				}
			}
	
			array_b = array
	
			do {
				try array.importChangesets(changesets)
				XCTAssert(array == array_b)
		
				let changeset_merged = array.changeset() ?? Dictionary()
		
				let changeset_redo = try array.undo(changeset_merged)
				if DEBUG_THIS_METHOD && (array != array_a) {
					print("It's going to FAIL")
				}
				XCTAssert(array == array_a)
		
				let _ = try array.undo(changeset_redo)
				if DEBUG_THIS_METHOD && (array != array_b) {
					print("It's going to FAIL")
				}
				XCTAssert(array == array_b)
			}
			catch {
				XCTAssert(false)
				print("Threw error: \(error)")
			}
	
			if DEBUG_THIS_METHOD {
				print("-------------------------------------------------");
			}
		}}
	}

	func test_import_fuzz_insert() {
		
		let DEBUG_THIS_METHOD = false
	
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var array_a: ZDCArray<String>? = nil
			var array_b: ZDCArray<String>? = nil
			var changesets: [ZDCChangeset] = []
	
			var array = ZDCArray<String>()
	
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
					array.append(key)
				}
			}
	
			array.clearChangeTracking()
			array_a = array
	
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
					let idx = Int(arc4random_uniform(UInt32(array.count)))
	
					if DEBUG_THIS_METHOD {
						print("insertObject:forKey:\(key) atIndex:\(idx)")
					}
					array.insert(key, at: idx)
				}
	
				changesets.append(array.changeset() ?? Dictionary())
	
				if DEBUG_THIS_METHOD {
					print("********************")
				}
			}
	
			array_b = array
	
			do {
				try array.importChangesets(changesets)
				XCTAssert(array == array_b)
		
				let changeset_merged = array.changeset() ?? Dictionary()
		
				let changeset_redo = try array.undo(changeset_merged)
				if DEBUG_THIS_METHOD && (array != array_a) {
					print("It's going to FAIL")
				}
				XCTAssert(array == array_a)
		
				let _ = try array.undo(changeset_redo)
				if DEBUG_THIS_METHOD && (array != array_b) {
					print("It's going to FAIL")
				}
				XCTAssert(array == array_b)
			}
			catch {
				XCTAssert(false)
				print("Threw error: \(error)")
			}
	
			if DEBUG_THIS_METHOD {
				print("-------------------------------------------------");
			}
		}}
	}

	func test_import_fuzz_move() {
		
		let DEBUG_THIS_METHOD = false
	
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var array_a: ZDCArray<String>? = nil
			var array_b: ZDCArray<String>? = nil
			var changesets: [ZDCChangeset] = []
	
			var array = ZDCArray<String>()
	
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
					array.append(key)
				}
			}
	
			if DEBUG_THIS_METHOD {
				print("Initial array.count: \(array.count)")
			}
	
			array.clearChangeTracking()
			array_a = array
	
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
					
					// Move an item
	
					let oldIdx = Int(arc4random_uniform(UInt32(array.count)))
					let newIdx = Int(arc4random_uniform(UInt32(array.count)))
	
					if DEBUG_THIS_METHOD {
						print("moveObjectAtIndex:\(oldIdx) toIndex:\(newIdx)")
					}
					array.move(fromIndex: oldIdx, toIndex: newIdx)
				}
	
				changesets.append(array.changeset() ?? Dictionary())
	
				if DEBUG_THIS_METHOD {
					print("********************");
				}
			}
	
			array_b = array
	
			do {
				try array.importChangesets(changesets)
				XCTAssert(array == array_b)
		
				let changeset_merged = array.changeset() ?? Dictionary()
		
				let changeset_redo = try array.undo(changeset_merged)
				if DEBUG_THIS_METHOD && (array != array_a) {
					print("It's going to FAIL")
				}
				XCTAssert(array == array_a)
		
				let _ = try array.undo(changeset_redo)
				if DEBUG_THIS_METHOD && (array != array_b) {
					print("It's going to FAIL")
				}
				XCTAssert(array == array_b)
			}
			catch {
				XCTAssert(false)
				print("Threw error: \(error)")
			}
	
			if DEBUG_THIS_METHOD {
				print("-------------------------------------------------");
			}
		}}
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Import: Fuzz: Everything
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	func test_import_fuzz_everything() {
		
		let DEBUG_THIS_METHOD = false
	
		for _ in 0 ..< 1_000 { autoreleasepool {
			
			var array_a: ZDCArray<String>? = nil
			var array_b: ZDCArray<String>? = nil
			var changesets: [ZDCChangeset] = []
	
			var array = ZDCArray<String>()
	
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
					array.append(key)
				}
			}
	
			if DEBUG_THIS_METHOD {
				print("Initial array.count: \(array.count)")
			}
	
			array.clearChangeTracking()
			array_a = array
	
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
							print("addObject: \(key)")
						}
						array.append(key)
					}
					else if (random == 1)
					{
						// Remove an item
	
						let idx = Int(arc4random_uniform(UInt32(array.count)))
	
						if DEBUG_THIS_METHOD {
							print("removeObjectAtIndex:\(idx)")
						}
						if (array.count > 0) {
							array.remove(at: idx)
						}
					}
					else if (random == 2)
					{
						// Insert an item
	
						let key = self.randomLetters(8)
						let idx = Int(arc4random_uniform(UInt32(array.count)))
	
						if DEBUG_THIS_METHOD {
							print("insertObject:forKey:\(key) atIndex:\(idx)")
						}
						array.insert(key, at: idx)
					}
					else
					{
						// Move an item
	
						let oldIdx = Int(arc4random_uniform(UInt32(array.count)))
						let newIdx = Int(arc4random_uniform(UInt32(array.count)))
	
						if DEBUG_THIS_METHOD {
							print("moveObjectAtIndex:\(oldIdx) toIndex:\(newIdx)")
						}
						if (array.count > 0) {
							array.move(fromIndex: oldIdx, toIndex: newIdx)
						}
					}
				}
	
				changesets.append(array.changeset() ?? Dictionary())
	
				if DEBUG_THIS_METHOD {
					print("********************");
				}
			}
	
			array_b = array
	
			do {
				try array.importChangesets(changesets)
				XCTAssert(array == array_b)
				
				let changeset_merged = array.changeset() ?? Dictionary()
	
				let changeset_redo = try array.undo(changeset_merged)
				if DEBUG_THIS_METHOD && (array != array_a) {
					print("It's going to FAIL")
				}
				XCTAssert(array == array_a)
		
				let _ = try array.undo(changeset_redo)
				if DEBUG_THIS_METHOD && (array != array_b) {
					print("It's going to FAIL")
				}
				XCTAssert(array == array_b)
			}
			catch {
				XCTAssert(false)
				print("Threw error: \(error)")
			}
	
			if DEBUG_THIS_METHOD {
				print("-------------------------------------------------");
			}
		}}
	}
	
	// ====================================================================================================
	// MARK:- Merge - Simple
	// ====================================================================================================

	func test_simpleMerge_1() {
		
		var changesets: [ZDCChangeset] = []
	
		var local = ZDCArray<String>()
		local.append("alice")
		local.append("bob")
	
		local.clearChangeTracking()
		var cloud = local
	
		do { // local changes
	
			local.remove("alice")
			local.append("carol")
			changesets.append(local.changeset() ?? Dictionary())
		}
		do { // cloud changes
	
			cloud.remove("bob")
			cloud.append("dave")
		}
	
		do {
			let _ = try local.merge(cloudVersion: cloud, pendingChangesets: changesets)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	
		XCTAssert(!local.contains("alice"))
		XCTAssert(!local.contains("bob"))
	
		XCTAssert(local.contains("carol"))
		XCTAssert(local.contains("dave"))
	}

	func test_simpleMerge_2() {
		
		var changesets: [ZDCChangeset] = []
	
		var local = ZDCArray<String>()
		local.append("alice")
		local.append("bob")
	
		local.clearChangeTracking()
		var cloud = local
	
		do { // local changes
	
			local.remove("alice")
			local.append("carol")
			changesets.append(local.changeset() ?? Dictionary())
		}
		do { // cloud changes
	
			cloud.remove("alice")
			cloud.append("dave")
			cloud.remove("bob")
			cloud.append("emily")
		}
	
		do {
			let _ = try local.merge(cloudVersion: cloud, pendingChangesets: changesets)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	
		XCTAssert(!local.contains("alice"))
		XCTAssert(!local.contains("bob"))
	
		XCTAssert(local.contains("carol"))
		XCTAssert(local.contains("dave"))
		XCTAssert(local.contains("emily"))
	}

	func test_simpleMerge_3() {
		
		var changesets: [ZDCChangeset] = []
	
		var local = ZDCArray<String>()
		local.append("alice")
	
		local.clearChangeTracking()
		var cloud = local
	
		do { // local changes
	
			local.append("bob")
			changesets.append(local.changeset() ?? Dictionary())
		}
		do { // cloud changes
	
			cloud.append("carol")
			cloud.remove("alice")
			cloud.append("dave")
		}
	
		do {
			let _ = try local.merge(cloudVersion: cloud, pendingChangesets: changesets)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	
		XCTAssert(!local.contains("alice"))
	
		XCTAssert(local.contains("bob"))
		XCTAssert(local.contains("carol"))
		XCTAssert(local.contains("dave"))
	}

	func test_simpleMerge_4() {
		
		var changesets: [ZDCChangeset] = []
	
		var local = ZDCArray<String>()
		local.append("alice")
	
		local.clearChangeTracking()
		var cloud = local
	
		do { // local changes
	
			local.append("bob")
			changesets.append(local.changeset() ?? Dictionary())
		}
		do { // cloud changes
	
			cloud.remove("alice")
			cloud.append("carol")
		}
	
		do {
			let _ = try local.merge(cloudVersion: cloud, pendingChangesets: changesets)
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	
		XCTAssert(!local.contains("alice"))
	
		XCTAssert(local.contains("bob"))
		XCTAssert(local.contains("carol"))
	}

	func test_simpleMerge_5() {
		
		var changesets: [ZDCChangeset] = []
	
		var local = ZDCArray<String>()
		local.append("alice")
		local.append("bob")
	
		local.clearChangeTracking()
		var cloud = local
	
		do { // local changes
	
			local.remove("bob")
			local.append("carol")
			changesets.append(local.changeset() ?? Dictionary())
		}
		do { // cloud changes
	
			cloud.remove("alice")
		}
	
		do {
			let _ = try local.merge(cloudVersion: cloud, pendingChangesets: changesets)
			
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	
		XCTAssert(!local.contains("alice"))
		XCTAssert(!local.contains("bob"))
	
		XCTAssert(local.contains("carol"))
	}

	// ====================================================================================================
	// MARK: Merge - With Duplicates
	// ====================================================================================================

	func test_mergeWithDuplicates_1() {
		
		var changesets: [ZDCChangeset] = []
	
		var local = ZDCArray<String>()
		local.append("alice")
	
		local.clearChangeTracking()
		var cloud = local
	
		do { // local changes
	
			local.append("alice")
			changesets.append(local.changeset() ?? Dictionary())
		}
		do { // cloud changes
	
			cloud.append("alice")
		}
	
		do {
			let _ = try local.merge(cloudVersion: cloud, pendingChangesets: changesets)
			
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	
		XCTAssert(local.contains("alice"))
		XCTAssert(local.count == 2)
	}

	func test_mergeWithDuplicates_2() {
		
		var changesets: [ZDCChangeset] = []
	
		var local = ZDCArray<String>()
		local.append("alice")
		local.append("alice")
	
		local.clearChangeTracking()
		var cloud = local
	
		do { // local changes
	
			local.append("bob")
			changesets.append(local.changeset() ?? Dictionary())
		}
		do { // cloud changes
	
			cloud.remove(at: 0)
			cloud.append("bob")
		}
	
		do {
			let _ = try local.merge(cloudVersion: cloud, pendingChangesets: changesets)
			
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	
		XCTAssert(local.contains("alice"))
		XCTAssert(local.count == 2)
	}

	func test_mergeWithDuplicates_3() {
		
		var changesets: [ZDCChangeset] = []
	
		var local = ZDCArray<String>()
		local.append("alice")
		local.append("alice")
	
		local.clearChangeTracking()
		var cloud = local
	
		do { // local changes
	
			local.remove(at: 0)
			local.append("bob")
			changesets.append(local.changeset() ?? Dictionary())
		}
		do { // cloud changes
	
			cloud.append("bob")
		}
		
		do {
			let _ = try local.merge(cloudVersion: cloud, pendingChangesets: changesets)
			
		}
		catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	
		XCTAssert(local.contains("alice"))
		XCTAssert(local.count == 2)
	}
	
}
