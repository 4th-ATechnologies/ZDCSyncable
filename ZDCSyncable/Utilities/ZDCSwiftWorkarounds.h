/// ZDCSyncable
/// https://github.com/4th-ATechnologies/ZDCSyncable
///
/// Undo, redo & merge capabilities for structs & classes in pure Swift.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZDCSwiftWorkarounds : NSObject

/**
 * We need the ability to throw an exception due to a protocol contract violation.
 * Swift wants us to explicitly mark every function that can throw.
 *
 * But this isn't really what we want.
 * It's not a general error, it's a developer error.
 * Something one finds while implementing the ZDCSyncable protocol for the first time.
 *
 * So we drop into objective-c as a workaround.
 */
+ (void)throwSyncableException:(nullable Class)class forKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
