//
//  MenuController.h
//  MouseGesture
//
//  Created by keakon on 11-11-18.
//  Copyright (c) 2011年 keakon.net. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MenuController : NSWindowController {
	NSMenu *statusMenu;
	NSMenuItem *toggleEnableItem;
	NSMenuItem *toggleLaunchAtStartupItem;
	NSStatusItem *statusItem;
	BOOL isLaunchAtStartup;
}

@property (retain, nonatomic) IBOutlet NSMenu *statusMenu;

- (IBAction)toggleEnable:(id)sender;
- (IBAction)toggleLaunchAtStartup:(id)sender;

@end
