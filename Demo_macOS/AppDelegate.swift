/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

import Cocoa
import ZDCSyncable

struct Person: ZDCSyncable, CustomStringConvertible {
	
	@Syncable var firstName: String
	@Syncable var lastName: String? = nil
	@Syncable var age: Int
	
	var description: String {
		return "Person: first:\(firstName), last:\(lastName ?? "nil") age:\(age)"
	}
}

struct Television: ZDCSyncable, CustomStringConvertible {
	
	@Syncable var brand: String
	
	var specs = ZDCDictionary<String, String>()
	
	var description: String {
		return "Television: brand:\(brand), specs:\(specs.rawDictionary)>"
	}
	
	/// You must implement this function IFF you have ZDCSyncable properties such as ZDCDictionary.
	///
	mutating func setSyncableValue(_ value: Any?, for key: String) -> Bool {
		
		switch key {
		case "specs":
			
			if let value = value as? ZDCDictionary<String, String> {
				specs = value
				return true
			}
			
		default: break
		}
		
		return false
	}
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		
		demo1()
		demo2()
		demo3()
	}
	
	func demo1() {
		print("===== demo1 =====")
		
		// Using a simple struct with @Syncable property wrappers
		
		var person = Person(firstName: "John", age: 18)
		// ^ starting point

		person.lastName = "Doe"
		person.age = 22
				
		let changeset = person.changeset() // changes since starting point
		print("Before undo: \(person)")
		do {
			let redo = try person.undo(changeset!) // revert to starting point
			
			print("After undo: \(person)")
			// Current state:
			// person.lastName == nil
			// person.age == 18
			
			let _ = try person.undo(redo) // redo == (undo an undo)
			
			print("After redo: \(person)")
			// Current state:
			// foobar.someString == "modified"
			// foobar.someInt == 2
					
		} catch _ {}
	}
	
	func demo2() {
		print("===== demo2 =====")
		
		// Using a struct that includes a dictionary
		
		var tv = Television(brand: "Samsung")
		tv.specs["size"] = "40"
		tv.clearChangeTracking() // starting point
		
		tv.brand = "Phillips"
		tv.specs["size"] = "52"
		tv.specs["widescreen"] = "true"
		
		let changeset = tv.changeset() ?? ZDCChangeset()
		print("Before undo: \(tv)")
		do {
			let redo = try tv.undo(changeset)
			
			print("After undo: \(tv)")
			// tv.brand = "Samsung"
			// tv.specs["size"] = "40"
			// tv.specs["widescreen"] = nil
			
			let _ = try tv.undo(redo)
			
			print("After redo: \(tv)")
			// tv.brand = "Phillips"
			// tv.specs["size"] = "52"
			// tv.specs["widescreen"] = "yes"
		}
		catch {
			print("Error: \(error)")
		}
	}
	
	func demo3() {
		print("===== demo3 =====")
		
		// Using a collection class by itself
		
		var dict = ZDCDictionary<String, String>()
		dict["foo"] = "bar"
		dict.clearChangeTracking() // starting point
		
		dict["foo"] = "buzz"
		dict["moo"] = "cow"
		
		let changeset = dict.changeset() ?? ZDCChangeset()
		print("Before undo: \(dict.rawDictionary)")
		do {
			let redo = try dict.undo(changeset)
			
			print("After undo: \(dict.rawDictionary)")
			// dict["foo"] = "bar"
			// dict["moo"] = nil
			
			let _ = try dict.undo(redo)
			
			print("After redo: \(dict.rawDictionary)")
			// dict["foo"] = "buzz"
			// dict["moo"] = "cow"
		}
		catch {
			print("Error: \(error)")
		}
	}
}
