#import "utils.h"

NSString *frontBundleName() {
    NSRunningApplication* runningApp = [[NSWorkspace sharedWorkspace] frontmostApplication];
    return runningApp.bundleIdentifier;
}

bool wildLike(NSString *bundlename,NSString *wildfilter){
    NSArray *filterArray = [wildfilter componentsSeparatedByString: @"|"];
    for(NSString *filter in filterArray){
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"self LIKE %@", [filter lowercaseString]];
        if([pred evaluateWithObject:[bundlename lowercaseString]]) return YES;
    }
    return NO;
}