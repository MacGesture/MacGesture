//
// Created by zcw on 15/12/15.
// Copyright (c) 2015 MacGesture. All rights reserved.
//

#import "BlockAllowFilter.h"

#define KEY_BLOCK_LIST @"filterBlackList"
#define KEY_ALLOW_LIST @"filterWhiteList"
#define KEY_IS_IN_ALLOW_MODE @"filterIsInWhiteMode"
static BlockAllowFilter *filterSingle;

@implementation BlockAllowFilter {
}

+ (BlockAllowFilter *)current {
    if (!filterSingle) {
        filterSingle = [BlockAllowFilter new];
    }
    
    return filterSingle;
}

- (BOOL)isInAllowListMode {
    return [[NSUserDefaults standardUserDefaults] boolForKey:KEY_IS_IN_ALLOW_MODE];
}

- (void)setIsInAllowListMode:(BOOL)isInAllowListMode {
    [[NSUserDefaults standardUserDefaults] setBool:isInAllowListMode forKey:KEY_IS_IN_ALLOW_MODE];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray *)blockList {
    return [[NSUserDefaults standardUserDefaults] arrayForKey:KEY_BLOCK_LIST];
}

- (void)setBlockList:(NSArray *)blockList {
    [[NSUserDefaults standardUserDefaults] setObject:blockList
                                              forKey:KEY_BLOCK_LIST];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)blockListText {
    NSArray *list = [self blockList];
    if (list) {
        return [list componentsJoinedByString:@"\n"];
    } else {
        return @"";
    }
}

- (void)setBlockListText:(NSString *)blockListText {
    NSMutableArray *a = [NSMutableArray new];
    for (NSString *text in [blockListText componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n"]]) {
        NSString *trimed = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (trimed.length > 0) {
            [a addObject:trimed];
        }
        
    }
    self.blockList = a;
}

- (NSArray *)allowList {
    return [[NSUserDefaults standardUserDefaults] arrayForKey:KEY_ALLOW_LIST];
}

- (void)setAllowList:(NSArray *)allowList {
    [[NSUserDefaults standardUserDefaults] setObject:allowList
                                              forKey:KEY_ALLOW_LIST];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)allowListText {
    NSArray *list = [self allowList];
    if (list) {
        return [list componentsJoinedByString:@"\n"];
    } else {
        return @"";
    }
}

- (void)setAllowListText:(NSString *)allowListText {
    NSMutableArray *a = [NSMutableArray new];
    for (NSString *text in [allowListText componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n"]]) {
        NSString *trimed = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (trimed.length > 0) {
            [a addObject:trimed];
        }
        
    }
    self.allowList = a;
}

- (BOOL)bundleName:(NSString *)bundleName fitWithRules:(NSArray *)rules {
    for (NSString *filter in rules) {
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"self LIKE %@", [filter lowercaseString]];
        if ([pred evaluateWithObject:[bundleName lowercaseString]]) return YES;
    }
    return NO;
}

- (BOOL)shouldHookMouseEventForApp:(NSString *)bundleName {
    if ([self isInAllowListMode]) {
        return [self bundleName:bundleName fitWithRules:self.allowList];
    } else {
        return ![self bundleName:bundleName fitWithRules:self.blockList];
    }
}

- (void)compatibleProcedureWithPreviousVersionBlockRules {
    NSString *s = [[NSUserDefaults standardUserDefaults] stringForKey:@"blockFilter"];
    if (s) {
        self.isInAllowListMode = NO;
        self.blockListText = [s stringByReplacingOccurrencesOfString:@"|" withString:@"\n"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"blockFilter"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
    } else {
        //nothing
    }
}


@end
