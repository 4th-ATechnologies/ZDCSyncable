/**
 * ZDCSyncable
 * <GitHub URL goes here>
**/

#import "ZDCObject.h"
#import "ZDCSyncableProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * The ZDCRecord class is designed to be subclassed.
 *
 * It provides the following set of features for your subclass:
 * - instances can be made immutable (via `-[ZDCObject makeImmutable]` method)
 * - it implements the ZDCSyncable protocol and thus:
 * - it tracks all changes and can provide a changeset (which encodes the changes info)
 * - it supports undo & redo
 * - it supports merge operations
 */
@interface ZDCRecord : ZDCObject <ZDCSyncable>

//
// SUBCLASS ME !
//

@end

NS_ASSUME_NONNULL_END
