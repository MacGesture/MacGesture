//
//  AppleScriptCommand.m
//  MacGesture
//
//  Created by MacBookAir on 1/25/17.
//  Copyright © 2017 Chivalry Software. All rights reserved.
//

#import "AppleScriptCommand.h"

@implementation AppleScriptCommand

-(id)executeCommand {
    [[AppDelegate appDelegate] showPreferences];
    return nil;
}

@end
