//
// Created by zcw on 15/12/15.
// Copyright (c) 2015 Chivalry Software. All rights reserved.
//

#import "BlackWhiteFilter.h"

#define KEY_BLACK_LIST @"filterBlackList"
#define KEY_WHITE_LIST @"filterWhiteList"
#define KEY_IS_IN_WHITE_MODE @"filterIsInWhiteMode"
static BlackWhiteFilter *filterSingle;

@implementation BlackWhiteFilter {
}

+ (BlackWhiteFilter *)current {
    if (!filterSingle) {
        filterSingle = [BlackWhiteFilter new];
    }

    return filterSingle;
}

- (BOOL)isInWhiteListMode {
    return [[NSUserDefaults standardUserDefaults] boolForKey:KEY_IS_IN_WHITE_MODE];
}

- (void)setIsInWhiteListMode:(BOOL)isInWhiteListMode {
    [[NSUserDefaults standardUserDefaults] setBool:isInWhiteListMode forKey:KEY_IS_IN_WHITE_MODE];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray *)blackList {
    return [[NSUserDefaults standardUserDefaults] arrayForKey:KEY_BLACK_LIST];
}

- (void)setBlackList:(NSArray *)blackList {
    [[NSUserDefaults standardUserDefaults] setObject:blackList
                                              forKey:KEY_BLACK_LIST];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)blackListText {
    NSArray *list = [self blackList];
    if (list) {
        return [list componentsJoinedByString:@"\n"];
    } else {
        return @"";
    }
}

- (void)setBlackListText:(NSString *)blackListText {
    NSMutableArray *a = [NSMutableArray new];
    for (NSString *text in [blackListText componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n"]]) {
        NSString *trimed = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (trimed.length > 0) {
            [a addObject:trimed];
        }

    }
    self.blackList = a;
}

- (NSArray *)whiteList {
    return [[NSUserDefaults standardUserDefaults] arrayForKey:KEY_WHITE_LIST];
}

- (void)setWhiteList:(NSArray *)whiteList {
    [[NSUserDefaults standardUserDefaults] setObject:whiteList
                                              forKey:KEY_WHITE_LIST];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)whiteListText {
    NSArray *list = [self whiteList];
    if (list) {
        return [list componentsJoinedByString:@"\n"];
    } else {
        return @"";
    }
}

- (void)setWhiteListText:(NSString *)whiteListText {
    NSMutableArray *a = [NSMutableArray new];
    for (NSString *text in [whiteListText componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n"]]) {
        NSString *trimed = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (trimed.length > 0) {
            [a addObject:trimed];
        }

    }
    self.whiteList = a;
}

- (BOOL)bundleName:(NSString *)bundleName fitWithRules:(NSArray *)rules {
    for (NSString *filter in rules) {
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"self LIKE %@", [filter lowercaseString]];
        if ([pred evaluateWithObject:[bundleName lowercaseString]]) return YES;
    }
    return NO;
}

- (BOOL)shouldHookMouseEventForApp:(NSString *)bundleName {
    if ([self isInWhiteListMode]) {
        return [self bundleName:bundleName fitWithRules:self.whiteList];
    } else {
        return ![self bundleName:bundleName fitWithRules:self.blackList];
    }
}

- (void)compatibleProcedureWithPreviousVersionBlockRules {
    NSString *s = [[NSUserDefaults standardUserDefaults] stringForKey:@"blockFilter"];
    if (s) {
        self.isInWhiteListMode = NO;
        self.blackListText = [s stringByReplacingOccurrencesOfString:@"|" withString:@"\n"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"blockFilter"];
        [[NSUserDefaults standardUserDefaults] synchronize];

    } else {
        //nothing
    }
}


@end