//
// Created by zcw on 15/12/15.
// Copyright (c) 2015 Chivalry Software. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface BlockAllowFilter : NSObject
@property(nonatomic, assign) BOOL isInAllowListMode;
@property(nonatomic, strong) NSArray *allowList;
@property(nonatomic, strong) NSArray *blockList;
@property(nonatomic, strong) NSString *allowListText;
@property(nonatomic, strong) NSString *blockListText;

+ (BlockAllowFilter *)current;

#define BWFilter [BlockAllowFilter current]

- (BOOL)shouldHookMouseEventForApp:(NSString *)bundleName;

- (void)compatibleProcedureWithPreviousVersionBlockRules;
@end