//
//  CanvasWindowController.m
//  MouseGesture
//
//  Created by keakon on 11-11-18.
//  Copyright (c) 2011年 keakon.net. All rights reserved.
//

#import "CanvasWindowController.h"
#import "CanvasWindow.h"
#import "CanvasView.h"

@implementation CanvasWindowController

- (id)init {
	self = [super init];
	if (self) {
		NSRect frame = NSScreen.mainScreen.frame;
		NSWindow *window = [[CanvasWindow alloc] initWithContentRect:frame];
		NSView *view = [[CanvasView alloc] initWithFrame:frame];
		window.contentView = view;
		[view release];
		window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces;
		self.window = window;
		[window orderFront:self];
		[window release];
		
		[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handleScreenParametersChange:) name:NSApplicationDidChangeScreenParametersNotification object:nil]; 
	}
	return self;
}

- (BOOL)enable {
	return enable;
}

- (void)setEnable:(BOOL)shouldEnable {
	enable = shouldEnable;
	if (shouldEnable) {
		[self.window orderFront:self];
	} else {
		[self.window orderOut:self];
	}
	[self.window.contentView setEnable:shouldEnable];
}

- (void)handleMouseEvent:(NSEvent *)event {
	switch (event.type) {
		case NSRightMouseDown:
			[self.window.contentView mouseDown:event];
			break;
		case NSRightMouseDragged:
			[self.window.contentView mouseDragged:event];
			break;
		case NSRightMouseUp:
			[self.window.contentView mouseUp:event];
			break;
		default:
			break;
	}
}

- (void)handleScreenParametersChange:(NSNotification *)notification {
	NSRect frame = NSScreen.mainScreen.frame;
	[self.window setFrame:frame display:NO];
	[self.window.contentView resizeTo:frame];
}

@end
