/**
 * Syncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZDCSwiftWorkarounds : NSObject

+ (void *)addressOf:(id)value;

/**
 * Swift wants to be overly explicit about when and where exceptions can be thrown.
 * This doesn't really work for us, because we need to throw exceptions from overriden functions.
 *
 * For example, we need the ability to throw an exception if you try to mutate an immutable object.
 * This is a simple concept, but Swift gets all Swifty about it, and screws it up.
 *
 * So we have to drop into objective-c to get the job done.
 */
+ (void)throwImmutableException:(Class)class;
+ (void)throwImmutableException:(Class)class forKey:(nullable NSString *)key;

@end

NS_ASSUME_NONNULL_END
