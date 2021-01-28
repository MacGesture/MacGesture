//
// Created by codefalling on 15/10/17.
// Copyright (c) 2015 MacGesture. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RulesList.h"
#import "AppleScriptsList.h"
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

- (NSString *)appleScriptIdAtIndex:(NSUInteger)index {
    return _rulesList[index][@"apple_script_id"];
}

- (BOOL)enabledAtIndex:(NSUInteger)index {
    if (_rulesList[index][@"enabled"] == nil) {
        _rulesList[index][@"enabled"] = @(YES);
    }
    return [_rulesList[index][@"enabled"] boolValue];
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
    [rulesList addRuleWithDirection:gesture filter:@"*safari|*chrome" filterType:FILTER_TYPE_WILDCARD actionType:ACTION_TYPE_SHORTCUT shortcutKeyCode:keycode shortcutFlag: flag appleScriptId:nil note:note];
}

- (void)reInit {
    [self clear];
    
    addWildcardShortcutRule(self, @"UR", kVK_ANSI_RightBracket, NSEventModifierFlagShift|NSEventModifierFlagCommand, @"Next Tab");
    addWildcardShortcutRule(self, @"UL", kVK_ANSI_LeftBracket, NSEventModifierFlagShift|NSEventModifierFlagCommand, @"Prev Tab");
    addWildcardShortcutRule(self, @"DL", kVK_ANSI_F, NSEventModifierFlagCommand|NSEventModifierFlagControl, @"Full screen");
    addWildcardShortcutRule(self, @"DR", kVK_ANSI_W, NSEventModifierFlagCommand, @"Close Tab");
    addWildcardShortcutRule(self, @"R", kVK_RightArrow, NSEventModifierFlagCommand, @"Next");
    addWildcardShortcutRule(self, @"L", kVK_LeftArrow, NSEventModifierFlagCommand, @"Back");
}

+ (RulesList *)sharedRulesList {
    static dispatch_once_t pred;
    static RulesList *rulesList = nil;
    dispatch_once(&pred, ^{
        rulesList = [[RulesList alloc] init];
    });
    
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
    // Fix issue #36. Dunno why it sends Control+Up as Fn+Control+Up. Invert the behavior.
    if (flags == kCGEventFlagMaskControl && [[NSUserDefaults standardUserDefaults] boolForKey:@"invertFnWhenControl"]) {
        flags ^= kCGEventFlagMaskSecondaryFn;
    }
    CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStateHIDSystemState);
    CGEventRef event = CGEventCreateKeyboardEvent(source, virtualKey, true);
    CGEventSetFlags(event, flags);
    CGEventPost(kCGHIDEventTap, event);
    CFRelease(event);
    
    event = CGEventCreateKeyboardEvent(source, virtualKey, false);
    CGEventSetFlags(event, flags);
    CGEventPost(kCGHIDEventTap, event);
    CFRelease(event);
    
    CFRelease(source);
}

- (bool)executeActionAt:(NSUInteger)index {
    NSAppleScript *script;
    NSString *appleScriptId;
    NSString *appleScript;
    NSDictionary *errorDict;
    NSAppleEventDescriptor *returnDescriptor;
    switch ([self actionTypeAtIndex:index]) {
        case ACTION_TYPE_SHORTCUT:
            pressKeyWithFlags([self shortcutKeycodeAtIndex:index], [self shortcutFlagAtIndex:index]);
            break;
        case ACTION_TYPE_APPLE_SCRIPT:
            appleScriptId = [self appleScriptIdAtIndex:index];
            appleScript = [[AppleScriptsList sharedAppleScriptsList] getScriptById:appleScriptId];
            script = [[NSAppleScript alloc] initWithSource:appleScript];
            returnDescriptor = [script executeAndReturnError:&errorDict];
            if (errorDict != nil) {
                NSLog(@"Execute Apple Script: returnDescriptor: %@, errorDict: %@", returnDescriptor, errorDict);
                NSUserNotification *userNotification = [NSUserNotification new];
                userNotification.title = @"MacGesture AppleScript Error";
                userNotification.informativeText = errorDict[NSAppleScriptErrorMessage];
                userNotification.hasActionButton = NO;
                [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:userNotification];
            }
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
            //if ([gesture isEqualToString:[self directionAtIndex:i]]) {
            if (wildcardString(gesture, [self directionAtIndex:i], NO)) {
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

- (bool)handleGesture:(NSString *)gesture isLastGesture:(BOOL)last {
    // if last, only match rules without trigger_on_every_match
    // if last = false, only match rules with trigger_on_every_match
    NSString *frontApp = frontBundleName();
    NSUInteger i = 0;
    for (; i < [self count]; i++) {
        if ([self enabledAtIndex:i]) {
            if ((last ^ [self triggerOnEveryMatchAtIndex:i]) && [self matchFilter:frontApp atIndex:i]) {
                //if ([gesture isEqualToString:[self directionAtIndex:i]]) {
                if (wildcardString(gesture, [self directionAtIndex:i], NO)) {
                    break;
                }
            }
        }
    }
    
    if (i != [self count]) {
        [self executeActionAt:i];
        return YES;
    }
    return NO;
}

- (NSString *)noteAtIndex:(NSUInteger)index {
    NSString *value = _rulesList[index][@"note"];
    return value ? value : @"";
}

- (BOOL)triggerOnEveryMatchAtIndex:(NSUInteger)index {
    NSNumber *b = _rulesList[index][@"trigger_on_every_match"];
    return [b boolValue];
}

- (void)setTriggerOnEveryMatch:(BOOL)match atIndex:(NSUInteger)index {
    _rulesList[index][@"trigger_on_every_match"] = [[NSNumber alloc] initWithBool:match];
    [self save];
}

- (void)setNote:(NSString *)note atIndex:(NSUInteger)index {
    _rulesList[index][@"note"] = note;
    [self save];
}

- (void)setAppleScriptId:(NSString *)id atIndex:(NSUInteger)index {
    _rulesList[index][@"apple_script_id"] = id;
    [self save];
}

- (void)addRuleWithDirection:(NSString *)direction
                      filter:(NSString *)filter
                  filterType:(FilterType)filterType
                  actionType:(ActionType)actionType
             shortcutKeyCode:(NSUInteger)shortcutKeyCode
                shortcutFlag:(NSUInteger)shortcutFlag
               appleScriptId:(NSString *)appleScriptId
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
        rule[@"apple_script_id"] = appleScriptId;
    }
    rule[@"note"] = note;
    rule[@"enabled"] = @(YES);
    [_rulesList addObject:rule];
    [self save];
}

- (void)moveRuleFrom:(NSInteger)from
              ruleTo:(NSInteger)to {
    if (from != to) {
        NSMutableDictionary *rule = _rulesList[from];
        [_rulesList removeObjectAtIndex:from];
        if (to >= [_rulesList count]) {
            [_rulesList addObject:rule];
        } else {
            [_rulesList insertObject:rule atIndex:to];
        }
        [self save];
    }
    //[_rulesList exchangeObjectAtIndex:from withObjectAtIndex:to];
}

- (void)removeRuleAtIndex:(NSInteger)index {
    [_rulesList removeObjectAtIndex:index];
    [self save];
}

- (void)toggleRule:(NSUInteger)index {
    BOOL current = [_rulesList[index][@"enabled"] boolValue];
    _rulesList[index][@"enabled"] = @(!current);
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
            // need ignore case here
            regex = [NSRegularExpression regularExpressionWithPattern:[self filterAtIndex:index] options:0 error:&error];
            if ([regex firstMatchInString:text options:0 range:NSMakeRange(0, [text length])]) {
                return YES;
            }
            break;
        case FILTER_TYPE_WILDCARD:
            return wildcardString(text, [self filterAtIndex:index], YES);
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
