# ZDCSyncable

Undo, redo & merge capabilities for plain objects in Swift.

(There's an objective-c version available [here](https://github.com/4th-ATechnologies/ZDCSyncableObjC).)

By: [ZeroDark.cloud](https://www.zerodark.cloud): A secure sync & messaging framework for your app, built on blockchain & AWS.

&nbsp;

## Undo & Redo

Example #1

```swift
class FooBar: ZDCRecord { // < Just extend ZDCRecord

  @objc dynamic var someString: String? // add your properties
  @objc dynamic var someInt: Int = 0    // and make sure they're '@objc dynamic'
}

// And now you get undo & redo support (for free!)

let foobar = FooBar();
foobar.someString = "init"
foobar.someInt = 1
foobar.clearChangeTracking(); // starting point

foobar.someString = "modified"
foobar.someInt = 2
		
let changeset = foobar.changeset() // changes since starting point
do {
  let redo = try foobar.undo(changeset!) // revert to starting point

  // Current state:
  // foobar.someString == "init"
  // foobar.someInt == 1

  let _ = try foobar.undo(redo) // redo == (undo an undo)

  // Current state:
  // foobar.someString == "modified"
  // foobar.someInt == 2
			
} catch _ {}
```

Complex objects are supported  via container classes:

- ZDCDictionary
- ZDCOrderedDictionary
- ZDCSet
- ZDCOrderedSet
- ZDCArray

Example #2

```swift
class FooBuzz: ZDCRecord { // < Just extend ZDCRecord

  @objc dynamic var someInt: Int = 0 // add your properties

  // or use smart containers !
  let dict = ZDCDictionary<String, String>() 
}

let foobuzz = FooBuzz()
foobuzz.someInt = 1
foobuzz.dict["foo"] = "buzz"
foobuzz.clearChangeTracking() // starting point
		
foobuzz.someInt = 2
foobuzz.dict["foo"] = "modified"
		
let changeset = foobuzz.changeset() // changes since starting point
do {
  let redo = try foobuzz.undo(changeset!) // revert to starting point
  
  // Current state:
  // foobuzz.someInt == 1
  // foobuzz.dict["foo"] == "buzz"

  let _ = try foobuzz.undo(redo) // redo == (undo an undo)

  // Current state:
  // foobuzz.someInt == 2
  // foobuzz.dict["foo"] == "modified"
			
} catch _ {}
```

&nbsp;

## Merge

You can also merge changes ! (i.e. from the cloud)

```swift
let local = FooBuzz()
local.someInt = 1
local.dict["foo"] = "buzz"
local.clearChangeTracking() // starting point
		
let cloud = local.copy() as! FooBuzz
var changesets = Array<Dictionary<String, Any>>()
	
// local modifications
	
local.someInt = 2
local.dict["foo"] = "modified"
	
changesets.append(local.changeset() ?? Dictionary())
// ^ pending local changes (not yet pushed to cloud)

// cloud modifications
			
cloud.dict["duck"]  = "quack"
		
// Now merge cloud version into local.
// Automatically take into account our pending local changes.

do {
  try local.merge(cloudVersion: cloud, pendingChangesets: changesets)
	
  // Merged state:
  // local.someInt == 2
  // local.dict["foo"] == "modified"
  // local.dict["duck"] == "quack"
} catch _ {}
```

&nbsp;

## Motivation

**Syncing data with the cloud requires the ability to properly merge changes. And properly merging changes requires knowing what's been changed.**

It's a topic that's often glossed over in tutorials, and so people tend to forget about it... until it's actually time to code. And then all hell breaks loose!

Syncing objects with the cloud means knowing how to merge changes from multiple devices. And this is harder than expected, because by default, this is the only information you have to perform the merge:

1. the current version of the object, as it appears in the cloud
2. the current version of the object, as it sits in your database

But something is missing. If property `someInt` is different between the two versions, that could mean:

- it was changed only by a remote device
- it was changed only by the local device
- it was changed by both devices

In order to properly perform the merge, you need to know the answer to this question.

What's missing is a list of changes that have been made to the LOCAL object. That is, changes that have been made, but haven't yet been pushed to the cloud. With that information, we can perform a proper merge. Because now we know:

1. the current version of the object, as it appears in the cloud
2. the current version of the object, as it sits in your database
3. a list of changes that have been made to the local object, including changed keys, and their original values

So if you want to merge changes properly, you're going to need to track this information. You can do it the hard way (manually), or the easy way (using some base class that provides the tracking for you automatically). Either way, you're not out of the woods yet!

It's somewhat trivial to track the changes to a simple record. That is, an object with just a few key/value pairs. And where all the values are primitive (numbers, booleans, strings). But what about when your app gets more advanced, and you need more complex objects?

What if one of your properties is an array? Or a dictionary? Or a set?

Truth be told, it's not THAT hard to code this stuff. It's not rocket science. But it does require **a TON of unit testing** to get all the little edge-cases correct. Which means you could spend all that time writing those unit tests yourself, or you could use an open-source version that's already been battle-tested by the community. (And then spend your extra time making your app awesome.)

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

## NSObject complaints

> "That's not pure Swift bro"

It's unfortunate, but it's true that we still need to rely on KVO from Objective-C to get the basic required functionality for a task like this. I know many people have requested this feature from the Swift team, and certainly several steps have been taken toward achieving this goal. But it appears we'll have to wait for another major Swift version before we can truly move to a pure Swift approach.

The good news is that when that finally happens, we'll have all the logic and all the unit tests ready. And the transition will be a breeze.

&nbsp;

## Immutability: Classes vs Structs in Swift

In order to get automatic change tracking, we're forced to use KVO (since there's no Swift alternative yet). This means we're forced to use classes instead of structs. This scares some people.

Well, **Fear Not !**

**An immutable class instance gives you the same benefits as a struct**. That is, you can pass it around your app without fear of side-effects (because you can't modify something that's immutable.)

ZDCSyncable gives you the ability to make any of your instances immutable:

```
myCustomSwiftObject.makeImmutable() // Boom! Cannot be modified now!
```

And now that the object is immutable, there's no danger of passing it around your app !

(If you're wondering how this works: The change tracking already monitors the objects for changes. So once you mark an object as immutable, attempts to modify the object will throw an exception. If you want to make changes, you just copy the object, and then modify the copy.)

