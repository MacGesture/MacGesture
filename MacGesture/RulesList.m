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
    return (FilterType)[((NSMutableDictionary *) _rulesList[index])[@"filterType"] integerValue];
}

- (ActionType)actionTypeAtIndex:(NSUInteger)index {
    return (ActionType)[((NSMutableDictionary *) _rulesList[index])[@"actionType"] integerValue];
}

- (NSUInteger)shortcutKeycodeAtIndex:(NSUInteger)index {
    NSUInteger keycode = [((NSMutableDictionary *) _rulesList[index])[@"shortcut_code"] unsignedIntegerValue];
    NSUInteger flag = [((NSMutableDictionary *) _rulesList[index])[@"shortcut_flag"] unsignedIntegerValue];
    return keycode;
}

- (NSUInteger)shortcutFlagAtIndex:(NSUInteger)index {
    NSUInteger flag = [((NSMutableDictionary *) _rulesList[index])[@"shortcut_flag"] unsignedIntegerValue];
    return flag;
}


- (NSInteger)count {
    return [_rulesList count];
}

- (void)clear{
    [_rulesList removeAllObjects];
}

- (void)save {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:self.nsData forKey:@"rules"];

    [userDefaults synchronize];
}

+ (id)readRulesList {
    id result;

    NSUserDefaults *defaults= [NSUserDefaults standardUserDefaults];
    result = [defaults objectForKey:@"rules"];
    return  result;
}

- (void)reInit {
    RulesList *rulesList = self;
    [rulesList clear];

#define XOR ^
#define ADD_RULE(_gesture,_keycode,_flag) [rulesList addRuleWithDirection:_gesture filter:@"*safari|*chrome" filterType:FILETER_TYPE_WILD actionType:ACTION_TYPE_SHORTCUT shortcutKeyCode:_keycode shortcutFlag: _flag appleScript:nil];
    ADD_RULE(@"UR",kVK_ANSI_RightBracket,NSShiftKeyMask XOR NSCommandKeyMask);
    ADD_RULE(@"UL",kVK_ANSI_LeftBracket,NSShiftKeyMask XOR NSCommandKeyMask);
    ADD_RULE(@"DL",kVK_ANSI_F,NSCommandKeyMask XOR NSControlKeyMask);
    ADD_RULE(@"DR",kVK_ANSI_W,NSCommandKeyMask);
    ADD_RULE(@"R",kVK_RightArrow,NSCommandKeyMask);
    ADD_RULE(@"L",kVK_LeftArrow,NSCommandKeyMask);
#undef ADD_RULE
#undef XOR
}


+ (RulesList *)sharedRulesList {
    static RulesList *rulesList = nil;
    NSData *data;
    if(data = [self readRulesList]){
        rulesList = [[RulesList alloc] initWithNsData:data];
    }

    if(rulesList == nil){
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

- (bool)executeActionAt:(NSUInteger)i{
    pressKeyWithFlags([self shortcutKeycodeAtIndex:i], [self shortcutFlagAtIndex:i]);
    return YES;
}

- (bool)handleGesture:(NSString *)gesture {

    for(int i=0;i<[self count];i++){
        if(wildLike(frontBundleName(), [self filterAtIndex:i])){
            // wild filter ensured
            if([gesture isEqualToString:[self directionAtIndex:i]]){
                return [self executeActionAt:i];
            }
        }
    }
    return NO;
}

- (void)addRuleWithDirection:(NSString *)direction
                      filter:(NSString *)filter
                  filterType:(FilterType)filterType
                  actionType:(ActionType)actionType
             shortcutKeyCode:(NSUInteger)shortcutKeyCode
                shortcutFlag:(NSUInteger)shortcutFlag
                 appleScript:(NSString *)appleScript
{
    NSMutableDictionary *rule = [[NSMutableDictionary alloc] init];
    rule[@"direction"] = direction;
    rule[@"filter"] = filter;
    rule[@"filterType"] = @(filterType);
    rule[@"actionType"] = @(actionType);
    if(actionType == ACTION_TYPE_SHORTCUT) {
        rule[@"shortcut_code"] = @(shortcutKeyCode);
        rule[@"shortcut_flag"] = @(shortcutFlag);

    }else if(actionType == ACTION_TYPE_APPLE_SCRIPT){
        rule[@"applescript"] = appleScript;
    }

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