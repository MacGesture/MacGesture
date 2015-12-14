#import "utils.h"

NSString *frontBundleName() {
    NSRunningApplication* runningApp = [[NSWorkspace sharedWorkspace] frontmostApplication];
    return runningApp.bundleIdentifier;
}

bool wildLike(NSString *bundlename,NSString *wildfilter){
    NSArray *filterArray = [wildfilter componentsSeparatedByCharactersInSet:
            [NSCharacterSet characterSetWithCharactersInString:@"|\n"]];
    for(NSString *filter in filterArray){
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"self LIKE %@", [filter lowercaseString]];
        if([pred evaluateWithObject:[bundlename lowercaseString]]) return YES;
    }
    return NO;
}

bool wildLikeNameToArray(NSString *bundlename,NSArray *wildfilters){

    for(NSString *filter in wildfilters){
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"self LIKE %@", [filter lowercaseString]];
        if([pred evaluateWithObject:[bundlename lowercaseString]]) return YES;
    }
    return NO;
}

