/// ZDCSyncable
/// https://github.com/4th-ATechnologies/ZDCSyncable
///
/// Undo, redo & merge capabilities for structs & objects in pure Swift.

import XCTest
import ZDCSyncable

class test_ZDCOrder: XCTestCase {
	
	func randomLetters(_ length: UInt) -> String {
		
		let alphabet = "abcdefghijklmnopqrstuvwxyz"
		return String((0..<length).map{ _ in alphabet.randomElement()! })
	}
	
	// ====================================================================================================
	// MARK: Fuzz
	// ====================================================================================================
	
	func test_fuzz() {
		
		let DEBUG_THIS_METHOD = false
		
		for _ in 0 ..< 5_000 { autoreleasepool {
			
			var src = Array<String>()
			
			var arrayCount: Int!
			if DEBUG_THIS_METHOD {
				arrayCount = 10
			} else {
				arrayCount = 20 + Int(arc4random_uniform(UInt32(10)))
			}
			
			// Start with an object that has a random number of objects [20 - 30)
			//
			for _ in 0 ..< arrayCount {
				
				let key = self.randomLetters(8)
				src.append(key)
			}
				
			var dst = src
			
			// Now make a random number of changes: [1 - 20)
			
			var changeCount: Int!
			if DEBUG_THIS_METHOD {
				changeCount = 2
			} else {
				changeCount = 1 + Int(arc4random_uniform(UInt32(19)))
			}
			
			for _ in 0 ..< changeCount {
				
				let oldIdx = Int(arc4random_uniform(UInt32(dst.count)))
				var newIdx = 0
				repeat {
					newIdx = Int(arc4random_uniform(UInt32(dst.count)))
				} while (oldIdx == newIdx)
				
				if DEBUG_THIS_METHOD {
					print("move: \(oldIdx) -> \(newIdx)")
				}
				
				let key = dst[oldIdx]
				
				dst.remove(at: oldIdx)
				dst.insert(key, at: newIdx)
			}
			
			// Does it halt ?
			do {
				let changes = try ZDCOrder.estimateChangeset(from: src, to: dst)
				
				XCTAssert(changes.count >= 0)
				
			} catch {
				XCTAssert(false)
				print("esitmateChanges threw error: \(error)")
			}
			
			if DEBUG_THIS_METHOD {
				print("-------------------------------------------------")
			}
		}}
	}
}
