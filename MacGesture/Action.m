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

@end