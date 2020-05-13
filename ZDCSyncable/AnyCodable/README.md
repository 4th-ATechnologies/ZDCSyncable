ZDCSyncable creates change-sets. And the goal is to save these change-sets to disk before syncing our local changes to the cloud. In the event that a conflict occurs, we can refer to the local change-sets to automatically merge changes, and provide a seamless sync experience.



So we need the ability to encode & decode these change-sets. The difficulty is that the structure of a change-set depends on the data models being used in your app. Meaning that ZDCSyncable doesn't have this information in advance.



In the olden days (objective-c), encoding arbitrary object graphs was easy using NSCoding. But Swift is a little more strict. So we're using `AnyCodable` to solve the problem.



Essentially, `AnyCodable` allows you to encode/decode any type that conforms to Swift's `Codable` protocol. For example:



```swift
var dict: [String: Any] = [:]
dict["foo"] = "bar" // String is Codable
dict["moo"] = 2     // Int is Codable

// On it's own, dict isn't Codable.
// Because type Any doesn't conform to Codable.
// But we can fix it by wrapping it with AnyCodable:

var wrapped = AnyCodable(dict)

do {
  let encoded = try JSONEncoder().encode(wrapped)
	let decoded = try JSONDecoder().decode(AnyCodable.self, from: encoded)
  
  if let decoded_dict = decoded.value as? [String: Any] {
    print("Awesome!")
  }
} catch { }
```



You can also using it to encode/decode your own custom `Codable` types. **You simply need to register the type first**:



```swift
struct Name: Codable {
  let firstName: String
  let lastName: String
}

AnyCodable.RegisterType(Name.self)
		
var dict: [String: Any] = [:]
dict["foo"] = "bar"
dict["moo"] = 2
dict["who"] = Name(firstName: "Robbie", lastName: "Hanson")

let wrapped = AnyCodable(dict)

do {
  let encoded = try JSONEncoder().encode(wrapped)
	let decoded = try JSONDecoder().decode(AnyCodable.self, from: encoded)
  
  if let decoded_dict = decoded.value as? [String: Any] {
    print("Awesome!")
  }
} catch { }
```



---

## Credit

There are many "AnyCodable" implementations out there. But most of them suck. Except one, which does it properly:



**Readdle's AnyCodable**:

https://github.com/readdle/swift-anycodable/blob/master/Sources/AnyCodable.swift



I was halfway thru coding the same thing myself, when I discovered their solution. And there's no use re-inventing the wheel here.