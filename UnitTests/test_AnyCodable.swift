/// ZDCSyncable
/// https://github.com/4th-ATechnologies/ZDCSyncable
///
/// Undo, redo & merge capabilities for structs & classes in pure Swift.

import XCTest
import ZDCSyncable

class test_AnyCodable: XCTestCase {
	
	struct StructWithOptionals: Codable {
		let day: Int?
		let month: Int?
		let year: Int
	}
	
	func test_structWithOptionals() {
		
		AnyCodable.RegisterType(StructWithOptionals.self)
		
		let raw = StructWithOptionals(day: 20, month: 5, year: 2020)
		
		let test = AnyCodable(raw)
		do {
			let encoder = JSONEncoder()
			let encoded = try encoder.encode(test)
			
			let decoder = JSONDecoder()
			let wrapped = try decoder.decode(AnyCodable.self, from: encoded)
			
			if let _ = wrapped.value as? StructWithOptionals {} else {
				XCTAssert(false)
			}
			
		} catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
	
	func test_dictWithOptionals() {
		
		var raw: [String: Int?] = [:]
		raw["foo"] = 5
		raw["bar"] = nil
		
		let test = AnyCodable(raw)
		do {
			let encoder = JSONEncoder()
			let encoded = try encoder.encode(test)
			
			let decoder = JSONDecoder()
			let wrapped = try decoder.decode(AnyCodable.self, from: encoded)
			
			if let _ = wrapped.value as? [String: Int?] {} else {
				XCTAssert(false)
			}
			
		} catch {
			XCTAssert(false)
			print("Threw error: \(error)")
		}
	}
}
