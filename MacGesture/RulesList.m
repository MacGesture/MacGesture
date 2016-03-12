//
// Created by codefalling on 15/10/17.
// Copyright (c) 2015 Chivalry Software. All rights reserved.
//


#import "RulesList.h"
#import <Carbon/Carbon.h>
#import "utils.h"

@implementation RulesList {

}

NSMutableArray<NSMutableDictionary *> *_rulesList;  // private

- (NSString *)directionAtIndex:(NSUInteger)index {
    return _rulesList[index][@"direction"];
}

- (NSString *)filterAtIndex:(NSUInteger)index {
    return _rulesList[index][@"filter"];
}

- (FilterType)filterTypeAtIndex:(NSUInteger)index {
    return (FilterType) [_rulesList[index][@"filterType"] integerValue];
}

- (ActionType)actionTypeAtIndex:(NSUInteger)index {
    return (ActionType) [_rulesList[index][@"actionType"] integerValue];
}

- (NSUInteger)shortcutKeycodeAtIndex:(NSUInteger)index {
    NSUInteger keycode = [_rulesList[index][@"shortcut_code"] unsignedIntegerValue];
    return keycode;
}

- (NSUInteger)shortcutFlagAtIndex:(NSUInteger)index {
    NSUInteger flag = [_rulesList[index][@"shortcut_flag"] unsignedIntegerValue];
    return flag;
}

- (NSString *)appleScriptAtIndex:(NSUInteger)index {
    return _rulesList[index][@"applescript"];
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

static inline void addWildcardShortcutRule(RulesList *rulesList, NSString *gesture, NSInteger keycode, NSInteger flag, NSString *note) {
    [rulesList addRuleWithDirection:gesture filter:@"*safari|*chrome" filterType:FILTER_TYPE_WILDCARD actionType:ACTION_TYPE_SHORTCUT shortcutKeyCode:keycode shortcutFlag: flag appleScript:nil note:note];
}

- (void)reInit {
    [self clear];
    
    addWildcardShortcutRule(self, @"UR", kVK_ANSI_RightBracket, NSShiftKeyMask|NSCommandKeyMask, @"Next Tab");
    addWildcardShortcutRule(self, @"UL", kVK_ANSI_LeftBracket, NSShiftKeyMask|NSCommandKeyMask, @"Prev Tab");
    addWildcardShortcutRule(self, @"DL", kVK_ANSI_F, NSCommandKeyMask|NSControlKeyMask, @"Full screen");
    addWildcardShortcutRule(self, @"DR", kVK_ANSI_W, NSCommandKeyMask, @"Close Tab");
    addWildcardShortcutRule(self, @"R", kVK_RightArrow, NSCommandKeyMask, @"Next");
    addWildcardShortcutRule(self, @"L", kVK_LeftArrow, NSCommandKeyMask, @"Back");
}

+ (RulesList *)sharedRulesList {
    static RulesList *rulesList = nil;
    if (rulesList) {
        return rulesList;
    }
    
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

- (bool)executeActionAt:(NSUInteger)index {
    NSAppleScript *script;
    NSDictionary *errorDict;
    NSAppleEventDescriptor *returnDescriptor;
    switch ([self actionTypeAtIndex:index]) {
        case ACTION_TYPE_SHORTCUT:
            pressKeyWithFlags([self shortcutKeycodeAtIndex:index], [self shortcutFlagAtIndex:index]);
            break;
        case ACTION_TYPE_APPLE_SCRIPT:
            script = [[NSAppleScript alloc] initWithSource:[self appleScriptAtIndex:index]];
            returnDescriptor = [script executeAndReturnError:&errorDict];
            NSLog(@"returnDescriptor: %@, errorDict: %@", returnDescriptor, errorDict);
            break;
        default:
            break;
    }
    return YES;
}

- (NSInteger)suitedRuleWithGesture:(NSString *)gesture {
    NSString *frontApp = frontBundleName();
    for (NSUInteger i = 0; i < [self count]; i++) {
        if ([self matchFilter:frontApp atIndex:i]) {
            if ([gesture isEqualToString:[self directionAtIndex:i]]) {
                return i;
            }
        }
    }
    return -1;
}

- (BOOL)appSuitedRule:(NSString*)bundleId {
    for (NSUInteger i = 0; i < [self count]; i++) {
        if ([self matchFilter:bundleId atIndex:i]) {
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
    NSString *value = _rulesList[index][@"note"];
    return value ? value : @"";
}

- (void)setNote:(NSString *)note atIndex:(NSUInteger)index {
    _rulesList[index][@"note"] = note;
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
    _rulesList[index][@"filterType"] = @(FILTER_TYPE_WILDCARD);
    [self save];
}

- (void)setRegexFilter:(NSString *)filter atIndex:(NSUInteger)index {
    _rulesList[index][@"filter"] = filter;
    _rulesList[index][@"filterType"] = @(FILTER_TYPE_REGEX);
    [self save];
}

- (BOOL)matchFilter:(NSString *)text atIndex:(NSUInteger)index {
    NSRegularExpression *regex;
    NSError *error;
    switch ([self filterTypeAtIndex:index]) {
        case FILTER_TYPE_REGEX:
            regex = [NSRegularExpression regularExpressionWithPattern:[self filterAtIndex:index] options:0 error:&error];
            if ([regex firstMatchInString:text options:0 range:NSMakeRange(0, [text length])]) {
                return YES;
            }
            break;
        case FILTER_TYPE_WILDCARD:
            return wildcardString(text, [self filterAtIndex:index]);
            break;
    }
    return NO;
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