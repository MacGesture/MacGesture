
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

@implementation NSArray (Utils)

- (NSArray<__kindof NSObject *> *)mappedArrayUsingBlock:(__kindof NSObject *(NS_NOESCAPE ^)(id, NSUInteger))block
{
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:self.count];

    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id remapped = block(obj, idx);
        if (remapped) [results addObject:remapped];
    }];

    return results;
}

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"

@implementation LoginServicesHelper

+ (LSSharedFileListItemRef)itemRefWithListRef:(LSSharedFileListRef)listRef {
    NSURL *bundleURL = [NSBundle mainBundle].bundleURL;
    CFArrayRef arr = LSSharedFileListCopySnapshot(listRef, NULL);

    for (NSInteger i = 0; i < CFArrayGetCount(arr); ++i) {
        LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)CFArrayGetValueAtIndex(arr, i);
        CFURLRef urlRef;
        OSStatus error = LSSharedFileListItemResolve(itemRef, 0, &urlRef, NULL);

        if (error != noErr) {
            continue;
        }

        if (CFEqual(urlRef, (__bridge CFURLRef)bundleURL)) {
            CFRetain(itemRef);
            CFRelease(arr);
            CFRelease(urlRef);
            return itemRef;
        }
        CFRelease(urlRef);
    }
    CFRelease(arr);
    return NULL;
}

+ (BOOL)isLoginItem {
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (!loginItems) return NO;

    LSSharedFileListItemRef loginItemRef = [self itemRefWithListRef:loginItems];
    if (!loginItemRef) {
        CFRelease(loginItems);
        return NO;
    }
    CFRelease(loginItems);
    CFRelease(loginItemRef);
    return YES;
}

+ (void)makeLoginItemActive:(BOOL)active
{
    NSURL *bundleURL = [NSBundle mainBundle].bundleURL;

    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);

    if (loginItems)
    {
        LSSharedFileListItemRef item;

        if (active)
        {
            item = LSSharedFileListInsertItemURL(loginItems,
                kLSSharedFileListItemLast, NULL, NULL, (__bridge CFURLRef)bundleURL, NULL, NULL);

            if (item)
                CFRelease(item);
        }
        else
        {
            item = [self itemRefWithListRef:loginItems];

            if (item)
                LSSharedFileListItemRemove(loginItems, item);
        }

        CFRelease(loginItems);
    }
}

@end

#pragma clang diagnostic pop
