/**
 * ZDCSyncable
 * <GitHub URL goes here>
**/

import Cocoa
import ZDCSyncable_Swift_macOS

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		
	//	DispatchQueue.main.async {
	//
	//		self.whyIsSwiftSoSlow()
	//	}
	}
/*
	func randomLetters(_ length: UInt) -> String {
		
		let alphabet = "abcdefghijklmnopqrstuvwxyz"
		return String((0..<length).map{ _ in alphabet.randomElement()! })
	}
	
	func whyIsSwiftSoSlow() {
		
		let DEBUG_THIS_METHOD = false
		let start_func = Date()
		
		for round in 0 ..< 500 { autoreleasepool {
			
			let start_round = Date()
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
				assert(dict == dict_b)
				
				let changeset_merged = dict.changeset() ?? Dictionary()
	
				let changeset_redo = try dict.undo(changeset_merged)
				if DEBUG_THIS_METHOD && (dict != dict_a) {
					print("It's going to FAIL")
				}
				assert(dict == dict_a)
				
				let _ = try dict.undo(changeset_redo)
				if DEBUG_THIS_METHOD && (dict != dict_b) {
					print("It's going to FAIL")
				}
				assert(dict == dict_b)
			}
			catch {
				assert(false)
				print("Threw error: \(error)")
			}
			
		//	if DEBUG_THIS_METHOD {
		//		print("-------------------------------------------------")
		//	}
			
			let end_round = Date()
			print("\( round ): \( end_round.timeIntervalSince(start_round) )")
		}}
		
		let end_func = Date()
		print("Done: \( end_func.timeIntervalSince(start_func) ) ")
	}
*/
}
