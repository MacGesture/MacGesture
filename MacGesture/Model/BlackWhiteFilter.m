//
// Created by zcw on 15/12/15.
// Copyright (c) 2015 Chivalry Software. All rights reserved.
//

#import "BlackWhiteFilter.h"

#define KEY_BLACK_LIST @"filter_black_list"
#define KEY_WHITE_LIST @"filter_white_list"
static BlackWhiteFilter *filterSingle;
@implementation BlackWhiteFilter {}

+(BlackWhiteFilter *)current{
    if(!filterSingle){
        filterSingle=[BlackWhiteFilter new];
    }

    return filterSingle;
}

- (NSArray *)blackList {
    return [[NSUserDefaults standardUserDefaults] arrayForKey:KEY_BLACK_LIST];
}
- (void)setBlackList:(NSArray *)blackList {
    [[NSUserDefaults standardUserDefaults] setObject:blackList
                                              forKey:KEY_BLACK_LIST];
}

- (NSString *)blackListText {
    NSArray *list=[self blackList];
    if(list){
        return [list componentsJoinedByString:@"\n"];
    }else{
        return @"";
    }
}

- (void)setBlackListText:(NSString *)blackListText {
    NSMutableArray *a=[NSMutableArray new];
    for (NSString * text in [blackListText componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n"]]) {
        NSString *trimed=[text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if(trimed.length>0){
            [a addObject:trimed];
        }

    }
    self.blackList=a;
}


- (NSArray *)whiteList {
    return [[NSUserDefaults standardUserDefaults] arrayForKey:KEY_WHITE_LIST];

}

- (void)setWhiteList:(NSArray *)whiteList {
    [[NSUserDefaults standardUserDefaults] setObject:whiteList
                                              forKey:KEY_WHITE_LIST];
}

- (NSString *)whiteListText {
    NSArray *list=[self whiteList];
    if(list){
        return [list componentsJoinedByString:@"\n"];
    }else{
        return @"";
    }
}

- (void)setWhiteListText:(NSString *)whiteListText {
    NSMutableArray *a=[NSMutableArray new];
    for (NSString * text in [whiteListText componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n"]]) {
        NSString *trimed=[text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if(trimed.length>0){
            [a addObject:trimed];
        }

    }
    self.whiteList=a;
}


@end