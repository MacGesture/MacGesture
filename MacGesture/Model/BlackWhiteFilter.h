//
// Created by zcw on 15/12/15.
// Copyright (c) 2015 Chivalry Software. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface BlackWhiteFilter : NSObject
@property (nonatomic, assign)BOOL isInWhiteListMode;
@property (nonatomic, strong)NSArray *whiteList;
@property (nonatomic, strong)NSArray *blackList;
@property (nonatomic, strong)NSString *whiteListText;
@property (nonatomic, strong)NSString *blackListText;

@end