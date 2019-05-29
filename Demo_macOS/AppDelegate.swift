/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

import Cocoa
import ZDCSyncable

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		
		let dict = ZDCDictionary<String, String>()
		dict["foo"] = "bar"
		dict.clearChangeTracking() // starting point
		
		dict["foo"] = "buzz"
		dict["moo"] = "cow"
		
		let changeset = dict.changeset() ?? Dictionary()
		print("Before undo: \(dict.rawDictionary)")
		do {
			let redo = try dict.undo(changeset)
			
			print("After undo: \(dict.rawDictionary)")
			
			let _ = try dict.undo(redo)
			
			print("After redo: \(dict.rawDictionary)")
		}
		catch {
			print("Error: \(error)")
		}
	}
}
