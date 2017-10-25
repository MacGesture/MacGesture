#import "utils.h"

NSString *frontBundleName(void) {
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
    BOOL result = NO;
    for (NSString *filter in wildFilters) {
        NSString *wildcard = filter;
        if (ignoreCase) {
            wildcard = [filter lowercaseString];
        }
        BOOL negate = NO;
        if([wildcard hasPrefix:@"!"]) {
            negate = YES;
            wildcard = [wildcard substringFromIndex:1];
        }
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"self LIKE %@", wildcard];
        BOOL match = [pred evaluateWithObject:bundleName];
        if (match && !negate) {
            result = YES;
        } else if (match && negate) {
            result = NO;
        }
    }
    return result;
}

bool wildcardString(NSString *bundleName, NSString *wildFilter, BOOL ignoreCase) {
    NSArray *filterArray = [wildFilter componentsSeparatedByCharactersInSet:
            [NSCharacterSet characterSetWithCharactersInString:@"|\n"]];
    return wildcardArray(bundleName, filterArray, ignoreCase);
}



