# ZDCSyncable

Undo, redo & merge capabilities for structs & classes in pure Swift.

By: [ZeroDark.cloud](https://www.zerodark.cloud): A secure sync & messaging framework for your app, built on blockchain & AWS.

&nbsp;

## Undo & Redo

Example #1

```swift
import ZDCSyncable

struct Person: ZDCSyncable { // Just add ZDCSyncable protocol

  @Syncable var name: String // Then add @Syncable property wrapper.
  @Syncable var age: Int = 1 // And that's it!
}

// And now you get undo & redo support

let person = Person(name = "alice")
// ^ starting point

person.name = "bob"
person.age = 2
		
let changeset = person.changeset() // changes since starting point
do {
  let redo = try person.undo(changeset!) // revert to starting point

  // Current state:
  // person.name == "alice"
  // person.age == 1

  let _ = try person.undo(redo) // redo == (undo an undo)

  // Current state:
  // person.name == "bob"
  // person.age == 2
			
} catch _ {}
```



If you want to use a class instead of a struct, that's supported too:

Example #2

```swift
import ZDCSyncable

class Animal: ZDCRecord { // <- Just extend ZDCRecord

  @Syncable var species: String // And add @Syncable property wrapper.
  @Syncable var age: Int
}
```

&nbsp;

The `@Syncable` property wrappers work for primitive types.

And the framework comes with additional solutions for replacing collection types:

- ZDCArray
- ZDCDictionary
- ZDCOrderedDictionary
- ZDCSet
- ZDCOrderedSet



These collections types mirror the API of their native Swift counterparts. And they're all implemented as structs, so you get the same value semantics you're used to.



Example #3

```swift
import ZDCSyncable

struct Television: ZDCSyncable { // Add ZDCSyncable protocol

  @Syncable var brand: String // Add @Syncable property wrapper.
  
  // Or use syncable collection class:
  var specs = ZDCDictionary<String, String>()
  
  // ZDCDictionary has almost the exact same API as Swift's Dictionary.
  // And ZDCDictionary is a struct, so you get the same value semantics.
}

var tv = Television(brand: "Samsung")
tv.specs["size"] = "30"
tv.clearChangeTracking() // set starting point
		
tv.brand = "Sony"
tv.specs["size"] = "40"
tv.specs["widescreen"] = "true"
		
let changeset = tv.changeset() // changes since starting point
do {
  let redo = try tv.undo(changeset!) // revert to starting point
  
  // Current state:
  // tv.brand == "Samsung"
  // tv.specs["size"] == "30"
  // tv.specs["widescreen"] = nil

  let _ = try tv.undo(redo) // redo == (undo an undo)

  // Current state:
  // tv.brand == "Sony"
  // tv.specs["size"] == "40"
  // tv.specs["widescreen"] = "true"
			
} catch _ {}
```



## Merge

You can also merge changes !  (*i.e. from the cloud*)

```swift
var localTV = Television(brand: "Samsung")
localTV.specs["size"] = "30"
localTV.clearChangeTracking() // set starting point
		
var cloudTV = localTV // Television is a struct
var changesets: [ZDCChangeset] = []
	
// local modifications

localTV.specs["size"] = "30.5"
localTV.specs["widescreen"] = "yes"
	
changesets.append(localTV.changeset() ?? ZDCChangeset())
// ^ pending local changes (not yet pushed to cloud)

// cloud modifications

cloudTV.specs["hdmi inputs"] = "2"

// Now merge cloud version into local.
// Automatically take into account our pending local changes.

do {
  try localTV.merge(cloudVersion: cloudTV, pendingChangesets: changesets)
	
  // Merged state:
  // localTV.brand == "Samsung"
  // localTV.specs["size"] == "30.5"
  // localTV.specs["widescreen"] == "true"
  // localTV.specs["hdmi inputs"] = "2"
} catch _ {}
```

&nbsp;

## Getting Started

ZDCSyncable is available via CocoaPods.

#### CocoaPods

Add the following to your Podfile:

```
pod 'ZDCSyncable'
```

Then just run `pod install` as usual. And then you can import it via:

```swift
// Swift
import ZDCSyncable
```

&nbsp;

## Motivation

**Merge conflicts happen**. If you've ever used git before, you know it well. And solving a merge conflict requires knowing what was changed. The same is true with your data model.



Consider the simple case of syncing a humble dictionary. Say we're notified of a conflict, and this is all we know:

```json
{
  "local version": {
    "size": "30.5",
    "widescreen": "true"
  },
  "remote version": {
    "size": "30",
    "hdmi inputs": "2"
  }
}
```



What should the merged value be?

If we use only the above information, we're unable to make an informed decision:

- who changed the `size` property? local? remote? both? who wins?
- was `widescreen` deleted by remote? or was it added locally?
- was `hdmi inputs` added by remote? or was it deleted locally?



ZDCSyncable helps you solve merge conflicts by providing the missing information you need. It does so by tracking changes, and providing a change-set:



```json
{
  "local version": {
    "size": "30.5",
    "widescreen": "true"
  },
  "remote version": {
    "size": "30",
    "hdmi inputs": "2"
  },
  "local changeset": {
    "size": {
      "type": "changed",
      "previous": "30"
    },
    "widescreen": {
      "type": "added"
    }
  }
}
```



With this information in hand, the merge becomes obvious:

- the `size` property was changed locally, and was not changed by remote. Local wins
- the `widescreen` property was added locally
- the `hdmi inputs` property was added by remote



The ZDCSyncable project gives you the tools you need to:

- track changes to you data models
- store those change-set(s) while the changes are being uploaded
- properly merge changes from the cloud by taking into account the set of local changes



Truth be told, it's not THAT hard to code this stuff. It's not rocket science. But it does require **a TON of unit testing** to get all the little edge-cases correct. Which means you could spend all that time writing those unit tests yourself, or you could use an open-source version that's already been battle-tested by the community. (And then spend your extra time making your app awesome.)

