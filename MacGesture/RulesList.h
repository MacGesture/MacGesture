//
// Created by codefalling on 15/10/17.
// Copyright (c) 2015 Chivalry Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MASShortcut;


@interface RulesList : NSObject
typedef enum {
    FILETER_TYPE_WILD, // for example chrom*
            FILETER_TYPE_REGEX
} FilterType;

typedef enum {
    ACTION_TYPE_SHORTCUT,
    ACTION_TYPE_APPLE_SCRIPT
} ActionType;


- (void)addRuleWithDirection:(NSString *)direction
                      filter:(NSString *)filter
                  filterType:(FilterType)filterType
                  actionType:(ActionType)actionType
             shortcutKeyCode:(NSUInteger)shortcutKeyCode // when actionType == ACTION_TYPE_SHORTCUT required,or 0
                shortcutFlag:(NSUInteger)shortcutFlag // when actionType == ACTION_TYPE_SHORTCUT required,or 0
                 appleScript:(NSString *)appleScript // when actionType == ACTION_TYPE_APPLE_SCRIPT required,or nil
                        note:(NSString *)note;

- (void)removeRuleAtIndex:(NSInteger)index;

- (NSInteger)count;

- (NSString *)directionAtIndex:(NSUInteger)index;

- (NSString *)filterAtIndex:(NSUInteger)index;

- (FilterType)filterTypeAtIndex:(NSUInteger)index;

- (ActionType)actionTypeAtIndex:(NSUInteger)index;

- (NSString *)noteAtIndex:(NSUInteger)index;

- (NSUInteger)shortcutKeycodeAtIndex:(NSUInteger)index;

- (NSUInteger)shortcutFlagAtIndex:(NSUInteger)index;

- (void)setShortcutWithKeycode:(NSUInteger)keycode withFlag:(NSUInteger)flag atIndex:(NSUInteger)index;

- (void)setWildFilter:(NSString *)filter atIndex:(NSUInteger)index;

- (void)setDirection:(NSString *)direction atIndex:(NSUInteger)index;

- (void)setNote:(NSString *)note atIndex:(NSUInteger)index;

- (bool)handleGesture:(NSString *)gesture;

- (NSInteger)suitedRuleWithGesture:(NSString *)gesture;

- (BOOL)appSuitedRule:(NSString*)bundleId;

- (void)reInit;

- (void)save;

- (NSData *)nsData;

- (RulesList *)initWithNsData:(NSData *)data;

+ (RulesList *)sharedRulesList;


@end