//
// Created by codefalling on 15/10/17.
// Copyright (c) 2015 Chivalry Software. All rights reserved.
//


#import "RulesList.h"
#import <Carbon/Carbon.h>
#import "utils.h"

@implementation RulesList {

}

NSMutableArray *_rulesList;  // private

- (NSString *)directionAtIndex:(NSUInteger)index {
    return ((NSMutableDictionary *) _rulesList[index])[@"direction"];
}

- (NSString *)filterAtIndex:(NSUInteger)index {
    return ((NSMutableDictionary *) _rulesList[index])[@"filter"];
}

- (FilterType)filterTypeAtIndex:(NSUInteger)index {
    return (FilterType) [((NSMutableDictionary *) _rulesList[index])[@"filterType"] integerValue];
}

- (ActionType)actionTypeAtIndex:(NSUInteger)index {
    return (ActionType) [((NSMutableDictionary *) _rulesList[index])[@"actionType"] integerValue];
}

- (NSUInteger)shortcutKeycodeAtIndex:(NSUInteger)index {
    NSUInteger keycode = [((NSMutableDictionary *) _rulesList[index])[@"shortcut_code"] unsignedIntegerValue];
    return keycode;
}

- (NSUInteger)shortcutFlagAtIndex:(NSUInteger)index {
    NSUInteger flag = [((NSMutableDictionary *) _rulesList[index])[@"shortcut_flag"] unsignedIntegerValue];
    return flag;
}

- (NSInteger)count {
    return [_rulesList count];
}

- (void)clear {
    [_rulesList removeAllObjects];
}

- (void)save {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:self.nsData forKey:@"rules"];

    [userDefaults synchronize];
}

+ (id)readRulesList {
    id result;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    result = [defaults objectForKey:@"rules"];
    return result;
}

static inline void addRule(RulesList *rulesList, NSString *gesture, NSInteger keycode, NSInteger flag, NSString *note) {
    [rulesList addRuleWithDirection:gesture filter:@"*safari|*chrome" filterType:FILETER_TYPE_WILD actionType:ACTION_TYPE_SHORTCUT shortcutKeyCode:keycode shortcutFlag: flag appleScript:nil note:note];
}

- (void)reInit {
    [self clear];
    
    addRule(self, @"UR", kVK_ANSI_RightBracket, NSShiftKeyMask|NSCommandKeyMask, @"Next Tab");
    addRule(self, @"UL", kVK_ANSI_LeftBracket, NSShiftKeyMask|NSCommandKeyMask, @"Prev Tab");
    addRule(self, @"DL", kVK_ANSI_F, NSCommandKeyMask|NSControlKeyMask, @"Full screen");
    addRule(self, @"DR", kVK_ANSI_W, NSCommandKeyMask, @"Close Tab");
    addRule(self, @"R", kVK_RightArrow, NSCommandKeyMask, @"Next");
    addRule(self, @"L", kVK_LeftArrow, NSCommandKeyMask, @"Back");
}

+ (RulesList *)sharedRulesList {
    static RulesList *rulesList = nil;
    NSData *data;
    if ((data = [self readRulesList])) {
        rulesList = [[RulesList alloc] initWithNsData:data];
    }

    if (rulesList == nil) {
        rulesList = [[RulesList alloc] init];
        [rulesList reInit];
        [rulesList save];
    }
    return rulesList;
}

static inline void pressKeyWithFlags(CGKeyCode virtualKey, CGEventFlags flags) {
    CGEventRef event = CGEventCreateKeyboardEvent(NULL, virtualKey, true);
    CGEventSetFlags(event, flags);
    CGEventPost(kCGSessionEventTap, event);
    CFRelease(event);

    event = CGEventCreateKeyboardEvent(NULL, virtualKey, false);
    CGEventSetFlags(event, flags);
    CGEventPost(kCGSessionEventTap, event);
    CFRelease(event);
}

- (bool)executeActionAt:(NSUInteger)i {
    pressKeyWithFlags([self shortcutKeycodeAtIndex:i], [self shortcutFlagAtIndex:i]);
    return YES;
}

- (NSInteger)suitedRuleWithGesture:(NSString *)gesture {
    for (NSUInteger i = 0; i < [self count]; i++) {
        if (wildcardString(frontBundleName(), [self filterAtIndex:i])) {
            // wild filter ensured
            if ([gesture isEqualToString:[self directionAtIndex:i]]) {
                return i;
            }
        }
    }
    return -1;
}

- (BOOL)frontAppSuitedRule {
    for (NSUInteger i = 0; i < [self count]; i++) {
        if (wildcardString(frontBundleName(), [self filterAtIndex:i])) {
            return YES;
        }
    }
    return NO;
}

- (bool)handleGesture:(NSString *)gesture {
    NSInteger i = [self suitedRuleWithGesture:gesture];
    if (i != -1) {
        [self executeActionAt:i];
        return YES;
    }
    if (gesture.length < 2) {
        return NO;
    } else {
        return YES;
    }
}

- (NSString *)noteAtIndex:(NSUInteger)index {
    NSString *value = ((NSMutableDictionary *) _rulesList[index])[@"note"];
    return value ? value : @"";
}

- (void)setNote:(NSString *)note atIndex:(NSUInteger)index {
    ((NSMutableDictionary *) _rulesList[index])[@"note"] = note;
    [self save];
}

- (void)addRuleWithDirection:(NSString *)direction
                      filter:(NSString *)filter
                  filterType:(FilterType)filterType
                  actionType:(ActionType)actionType
             shortcutKeyCode:(NSUInteger)shortcutKeyCode
                shortcutFlag:(NSUInteger)shortcutFlag
                 appleScript:(NSString *)appleScript
                        note:(NSString *)note; {
    NSMutableDictionary *rule = [[NSMutableDictionary alloc] init];
    rule[@"direction"] = direction;
    rule[@"filter"] = filter;
    rule[@"filterType"] = @(filterType);
    rule[@"actionType"] = @(actionType);
    if (actionType == ACTION_TYPE_SHORTCUT) {
        rule[@"shortcut_code"] = @(shortcutKeyCode);
        rule[@"shortcut_flag"] = @(shortcutFlag);

    } else if (actionType == ACTION_TYPE_APPLE_SCRIPT) {
        rule[@"applescript"] = appleScript;
    }
    rule[@"note"] = note;
    [_rulesList addObject:rule];
    [self save];
}


- (void)removeRuleAtIndex:(NSInteger)index {
    [_rulesList removeObjectAtIndex:index];
    [self save];
}


- (void)setShortcutWithKeycode:(NSUInteger)keycode withFlag:(NSUInteger)flag atIndex:(NSUInteger)index {
    _rulesList[index][@"shortcut_code"] = @(keycode);
    _rulesList[index][@"shortcut_flag"] = @(flag);
    _rulesList[index][@"actionType"] = @(ACTION_TYPE_SHORTCUT);
    [self save];
}

- (void)setWildFilter:(NSString *)filter atIndex:(NSUInteger)index {
    _rulesList[index][@"filter"] = filter;
    _rulesList[index][@"filterType"] = @(FILETER_TYPE_WILD);
    [self save];
}

- (void)setDirection:(NSString *)direction atIndex:(NSUInteger)index {
    _rulesList[index][@"direction"] = direction;
    [self save];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _rulesList = [[NSMutableArray alloc] init];
    }

    return self;
}

- (NSData *)nsData {
    return [NSKeyedArchiver archivedDataWithRootObject:_rulesList];
}

- (RulesList *)initWithNsData:(NSData *)data {
    self = [self init];
    if (self) {
        _rulesList = [[NSMutableArray alloc] initWithArray:[NSKeyedUnarchiver unarchiveObjectWithData:data]];
    }

    return self;
}

@end