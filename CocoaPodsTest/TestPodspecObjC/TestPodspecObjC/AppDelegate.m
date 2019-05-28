#import "AppDelegate.h"

// Using module-style import
@import ZDCSyncable;

// Or using classic-style import
//#import <ZDCSyncable/ZDCSyncable.h>


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	ZDCDictionary<NSString*, NSString*> *dict = [[ZDCDictionary alloc] init];
	dict[@"foo"] = @"bar";
}

@end
