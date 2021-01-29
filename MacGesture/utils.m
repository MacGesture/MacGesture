#import "utils.h"

NSString *frontBundleName() {
    NSRunningApplication *runningApp = [[NSWorkspace sharedWorkspace] frontmostApplication];

    if (!runningApp.bundleIdentifier) {
        return @"";
    }
    return runningApp.bundleIdentifier;
}

bool wildcardArray(NSString *bundleName, NSArray *wildFilters, BOOL ignoreCase) {
    if (ignoreCase) {
        bundleName = [bundleName lowercaseString];
    }
    for (NSString *filter in wildFilters) {
        NSString *wildcard = filter;
        if (ignoreCase) {
            wildcard = [filter lowercaseString];
        }
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"self LIKE %@", wildcard];
        if ([pred evaluateWithObject:bundleName]) {
            return YES;
        }
    }
    return NO;
}

bool wildcardString(NSString *bundleName, NSString *wildFilter, BOOL ignoreCase) {
    NSArray *filterArray = [wildFilter componentsSeparatedByCharactersInSet:
            [NSCharacterSet characterSetWithCharactersInString:@"|\n"]];
    return wildcardArray(bundleName, filterArray, ignoreCase);
}



