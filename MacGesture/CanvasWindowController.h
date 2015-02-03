//
//  CanvasWindowController.h
//  MouseGesture
//
//  Created by keakon on 11-11-18.
//  Copyright (c) 2011年 keakon.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CanvasWindowController : NSWindowController {
	BOOL enable;
}

@property (assign, nonatomic) BOOL enable;

- (void)handleMouseEvent:(NSEvent *)event;
- (void)handleScreenParametersChange:(NSNotification *)notification;

@end
