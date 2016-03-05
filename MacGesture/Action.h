//
// Created by codefalling on 15/10/17.
// Copyright (c) 2015 Chivalry Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MASShortcut;

static const NSString* ACTION_SHORTCUT = @"shortcut";

typedef enum{
    SHORT_CUT_ACTION,
}ActionType;

@interface Action : NSObject

@property ActionType type;
@property MASShortcut *shortcut;

- (instancetype)initWithShortcut:(MASShortcut *)shortcut;

@end