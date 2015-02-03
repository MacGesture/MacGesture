//
//  AppDelegate.h
//  MouseGesture
//
//  Created by keakon on 11-11-9.
//  Copyright (c) 2011年 keakon.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MenuController;

@interface AppDelegate : NSObject <NSApplicationDelegate> {
	MenuController *menuController;
}

- (BOOL)toggleEnable;

@end
