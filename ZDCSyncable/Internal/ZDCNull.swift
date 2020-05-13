/// ZDCSyncable
/// https://github.com/4th-ATechnologies/ZDCSyncable
///
/// Undo, redo & merge capabilities for structs & classes in pure Swift.

import Foundation

/**
 * ZDCNull is used internally to represent nil/null.
 * Do NOT use it directly. If you want to store null, then you should use NSNull.
 *
 * Why:
 *   We needed our own special version because we needed a way to differentiate from NSNull.
 *
 * Where it's used:
 *   In changeset dictionaries, ZDCNull is used as a placeholder to represent the absence of value.
 *   For example, if the originalValue of an object is ZDCNull, this would mean the object was added.
 *
 * ZDCNull is a singleton.
 */
internal struct ZDCNull: Codable {
	
	var description: String {
		return "<ZDCNull>"
	}
	
	var debugDescription: String {
		return "<ZDCNull>"
	}
}
