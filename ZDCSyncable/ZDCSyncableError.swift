/// ZDCSyncable
/// https://github.com/4th-ATechnologies/ZDCSyncable
///
/// Undo, redo & merge capabilities for structs & objects in pure Swift.

import Foundation

/// Common errors emitted from the ZDCSyncable protocol.
///
enum ZDCSyncableError: Error {
	
	/// The object has unsaved changes, and the requested operation only works on a clean object.
	///
	case hasChanges
	
	/// The given changeset is malformed.
	/// If you passed an array of changesets, then at least one of them is malformed.
	///
	case malformedChangeset
	
	/// The changeset appears to be mismatched.
	/// It does not line-up properly with the current state of the object.
	///
	case mismatchedChangeset
	
	/// This error will be emitted if the merge(cloudVersion:pendingChangesets:) function is invoked,
	/// but the cloudVersion parameter doesn't match the type of the receiver.
	///
	/// For example, if the receiver is a ZDCDictionary, but you invoke the merge function, and pass a ZDCArray.
	/// 
	case incorrectType
}
