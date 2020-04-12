import Foundation


public extension Collection {

	/// In the Xcode debugger, use the following command to prettyPrint the dictionary:
	/// `po print(dict.prettyPrint())`
	///
	func prettyPrint() -> String {
		
		do {
			let jsonData = try JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted])
			return String(data: jsonData, encoding: .utf8) ?? "{}"
		
		} catch {
			print("json serialization error: \(error)")
			return "{}"
		}
	}
}
