#import "utils.h"

NSString *frontBundleName() {
    NSRunningApplication* runningApp = [[NSWorkspace sharedWorkspace] frontmostApplication];
    
    if (!runningApp.bundleIdentifier) {
        return @"";
    }
    return runningApp.bundleIdentifier;
}

bool wildcardArray(NSString *bundleName, NSArray *wildFilters) {
    for(NSString *filter in wildFilters){
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"self LIKE %@", [filter lowercaseString]];
        if ([pred evaluateWithObject:[bundleName lowercaseString]]) {
            return YES;
        }
    }
    return NO;
}

bool wildcardString(NSString *bundleName, NSString *wildFilter) {
    NSArray *filterArray = [wildFilter componentsSeparatedByCharactersInSet:
            [NSCharacterSet characterSetWithCharactersInString:@"@\n"]];
    return wildcardArray(bundleName, filterArray);
}



