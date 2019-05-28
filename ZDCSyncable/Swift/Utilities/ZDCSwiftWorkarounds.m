/**
 * Syncable
 * <GitHub URL goes here>
**/

#import "ZDCSwiftWorkarounds.h"

@implementation ZDCSwiftWorkarounds

+ (void *)addressOf:(id)value
{
	if (value)
		return (__bridge void *)(value);
	else
		return 0;
}

+ (void)throwImmutableException:(Class)class
{
	[self throwImmutableException:class forKey:nil];
}

+ (void)throwImmutableException:(Class)class forKey:(nullable NSString *)key
{
	NSString *reason;
	if (key) {
		reason = [NSString stringWithFormat:
		    @"Attempting to mutate immutable object. Class = %@, property = %@", NSStringFromClass(class), key];
	}
	else {
		reason = [NSString stringWithFormat:
		    @"Attempting to mutate immutable object. Class = %@", NSStringFromClass(class)];
	}
	
	NSDictionary *userInfo = @{
		NSLocalizedRecoverySuggestionErrorKey:
			@"To make modifications you should create a copy of the object."
			@" You may then make changes to the copy before saving it back to the database."
	};
	
	@throw [NSException exceptionWithName:@"ZDCObjectException" reason:reason userInfo:userInfo];
}

@end
