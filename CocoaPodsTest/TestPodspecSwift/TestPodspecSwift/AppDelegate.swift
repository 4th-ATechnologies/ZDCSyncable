import Cocoa
import ZDCSyncable

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		
		let dict = ZDCDictionary<String, String>()
		dict["foo"] = "bar"
	}
}
