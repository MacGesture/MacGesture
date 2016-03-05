//
// Created by codefalling on 15/10/17.
// Copyright (c) 2015 Chivalry Software. All rights reserved.
//

#import "Action.h"


@implementation Action {

}

@synthesize shortcut = _shortcut;
@synthesize type = _type;

- (instancetype)initWithShortcut:(MASShortcut *)shortcut {
    self = [self init];
    if (self) {
        self.shortcut = shortcut;
        self.type = SHORT_CUT_ACTION;
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {

    }
    return self;
}

static inline void pressKey(CGKeyCode virtualKey) {
    CGEventRef event = CGEventCreateKeyboardEvent(NULL, virtualKey, true);
    CGEventPost(kCGSessionEventTap, event);
    CFRelease(event);

    event = CGEventCreateKeyboardEvent(NULL, virtualKey, false);
    CGEventPost(kCGSessionEventTap, event);
    CFRelease(event);
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


@end