
#import <Cocoa/Cocoa.h>
#import "utils.h"
#import <UserNotifications/UserNotifications.h>
#import <ServiceManagement/ServiceManagement.h>

NSString *frontBundleName(void) {
    NSRunningApplication *runningApp = [[NSWorkspace sharedWorkspace] frontmostApplication];
    
    if (!runningApp.bundleIdentifier) {
        return @"";
    }
    return runningApp.bundleIdentifier;
}

void MGNotify(NSString *title, NSString *text) {
    UNUserNotificationCenter *center = UNUserNotificationCenter.currentNotificationCenter;
    [center requestAuthorizationWithOptions:UNAuthorizationOptionAlert | UNAuthorizationOptionSound
                          completionHandler:^(BOOL granted, NSError *error) {
        if (!granted) return;
        UNMutableNotificationContent *content = [UNMutableNotificationContent new];
        content.title = title;
        content.body = text ?: @"";
        content.sound = UNNotificationSound.defaultSound;
        [center addNotificationRequest:[UNNotificationRequest requestWithIdentifier:NSUUID.UUID.UUIDString
            content:content trigger:nil] withCompletionHandler:nil];
    }];
}

NSData *MGArchive(id object) {
    return [NSKeyedArchiver archivedDataWithRootObject:object requiringSecureCoding:NO error:NULL];
}

id MGUnarchive(NSData *data, Class cls) {
    if (!data) return nil;
    NSSet *classes = [NSSet setWithObjects:cls, NSArray.class, NSMutableArray.class, NSDictionary.class,
        NSMutableDictionary.class, NSString.class, NSMutableString.class, NSNumber.class, nil];
    return [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:data error:NULL];
}

// Cached `self LIKE <wildcard>` predicate, built once per pattern
NSPredicate *likePredicate(NSString *wildcard) {
    static NSCache<NSString *, NSPredicate *> *cache;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ cache = [NSCache new]; });
    NSPredicate *pred = [cache objectForKey:wildcard];
    if (!pred) {
        pred = [NSPredicate predicateWithFormat:@"self LIKE %@", wildcard];
        [cache setObject:pred forKey:wildcard];
    }
    return pred;
}

BOOL wildcardArray(NSString *bundleName, NSArray *wildFilters, BOOL ignoreCase) {
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
        BOOL match = [likePredicate(wildcard) evaluateWithObject:bundleName];
        if (match && !negate) {
            result = YES;
        } else if (match && negate) {
            result = NO;
        }
    }
    return result;
}

BOOL wildcardString(NSString *bundleName, NSString *wildFilter, BOOL ignoreCase) {
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

@implementation NSObject (Utils)

- (id)parsedKindOf:(Class)class
{
    return [self isKindOfClass:class] ? self : nil;
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
    if (@available(macOS 13.0, *))
        return SMAppService.mainAppService.status == SMAppServiceStatusEnabled;

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
    if (@available(macOS 13.0, *)) {
        NSError *error;
        if (!(active ? [SMAppService.mainAppService registerAndReturnError:&error]
                     : [SMAppService.mainAppService unregisterAndReturnError:&error]))
            NSLog(@"Login item update failed: %@", error);
        return;
    }

    NSURL *bundleURL = [NSBundle mainBundle].bundleURL;

    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);

    if (loginItems)
    {
        LSSharedFileListItemRef item;

        if (active)
        {
            item = LSSharedFileListInsertItemURL(loginItems,
                kLSSharedFileListItemLast, NULL, NULL, (__bridge CFURLRef)bundleURL, NULL, NULL);

            if (item) CFRelease(item);
        }
        else
        {
            item = [self itemRefWithListRef:loginItems];

            if (item)
                LSSharedFileListItemRemove(loginItems, item);

            if (item) CFRelease(item);
        }

        CFRelease(loginItems);
    }
}

@end

#pragma clang diagnostic pop
