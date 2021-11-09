//
//  DBPrefsWindowController.m
//

#import "DBPrefsWindowController.h"

@interface DBPrefsWindowController()
@property (nonatomic, strong) NSMutableArray *toolbarIdentifiers;
@property (nonatomic, strong) NSMutableDictionary *toolbarViews;
@property (nonatomic, strong) NSMutableDictionary *toolbarItems;
@property (nonatomic, strong) NSViewAnimation *viewAnimation;
@property (nonatomic, strong) NSView *contentSubview;
@end

@implementation DBPrefsWindowController

#pragma mark -
#pragma mark Class Methods

+ (DBPrefsWindowController *)sharedPrefsWindowController{
    static DBPrefsWindowController *_sharedPrefsWindowController = nil;    
	if(!_sharedPrefsWindowController){
		_sharedPrefsWindowController = [[self alloc] initWithWindowNibName:[self nibName]];
	}
	return _sharedPrefsWindowController;
}

// Subclasses can override this to use a nib with a different name.
+ (NSString *)nibName{
   return @"Preferences";
}


#pragma mark -
#pragma mark Setup & Teardown

- (instancetype)initWithWindow:(NSWindow *)window{
	if((self = [super initWithWindow:nil])){
        // Set up an array and some dictionaries to keep track
        // of the views we'll be displaying.
        self.toolbarIdentifiers = [[NSMutableArray alloc] init];
        self.toolbarViews = [[NSMutableDictionary alloc] init];
        self.toolbarItems = [[NSMutableDictionary alloc] init];

        // Set up an NSViewAnimation to animate the transitions.
        self.viewAnimation = [[NSViewAnimation alloc] init];
        [self.viewAnimation setAnimationBlockingMode:NSAnimationNonblocking];
        [self.viewAnimation setAnimationCurve:NSAnimationEaseInOut];
        [self.viewAnimation setDelegate:(id<NSAnimationDelegate>)self];

        self.crossFade = YES;
        self.shiftSlowsAnimation = YES;
	}
	return self;
}

- (void)windowDidLoad{
    // Create a new window to display the preference views.
    // If the developer attached a window to this controller
    // in Interface Builder, it gets replaced with this one.
    NSWindow *window = 
    [[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,1000,1000)
                                styleMask:(NSWindowStyleMaskTitled |
                                           NSWindowStyleMaskClosable |
                                           NSWindowStyleMaskMiniaturizable)
                                  backing:NSBackingStoreBuffered
                                    defer:YES];
    [self setWindow:window];
    self.contentSubview = [[NSView alloc] initWithFrame:[[[self window] contentView] frame]];
    [self.contentSubview setAutoresizingMask:(NSViewMinYMargin | NSViewWidthSizable)];
    [[[self window] contentView] addSubview:self.contentSubview];
    [[self window] setShowsToolbarButton:NO];
}


#pragma mark -
#pragma mark Configuration

- (void)setupToolbar{
    // Subclasses must override this method to add items to the
    // toolbar by calling -addView:label: or -addView:label:image:.
}

- (void)addToolbarItemForIdentifier:(NSString *)identifier
                              label:(NSString *)label
                              image:(NSImage *)image
                           selector:(SEL)selector {
    [self.toolbarIdentifiers addObject:identifier];
    
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:identifier];
    [item setLabel:label];
    [item setImage:image];
    [item setTarget:self];
    [item setAction:selector];

    if ([identifier isEqualTo:NSToolbarFlexibleSpaceItemIdentifier])
        item.enabled = NO;
    
    (self.toolbarItems)[identifier] = item;
}

- (void)addFlexibleSpacer {
    [self addToolbarItemForIdentifier:NSToolbarFlexibleSpaceItemIdentifier label:nil image:nil selector:nil];
}

- (void)addView:(NSView *)view label:(NSString *)label{
    [self addView:view label:label image:[NSImage imageNamed:label]];
}

- (void)addView:(NSView *)view label:(NSString *)label image:(NSImage *)image{
    if(view == nil){
        return;
    }
	
    NSString *identifier = [label copy];
    (self.toolbarViews)[identifier] = view;
    [self addToolbarItemForIdentifier:identifier
                                label:label
                                image:image
                             selector:@selector(toggleActivePreferenceView:)];
}


#pragma mark -
#pragma mark Overriding Methods

- (IBAction)showWindow:(id)sender{
    // This forces the resources in the nib to load.
    [self window];

    // Clear the last setup and get a fresh one.
    [self.toolbarIdentifiers removeAllObjects];
    [self.toolbarViews removeAllObjects];
    [self.toolbarItems removeAllObjects];
    [self setupToolbar];

    if(![_toolbarIdentifiers count]){
        return;
    }

    if([[self window] toolbar] == nil){
        NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"DBPreferencesToolbar"];
        [toolbar setAllowsUserCustomization:NO];
        [toolbar setAutosavesConfiguration:NO];
        [toolbar setSizeMode:NSToolbarSizeModeDefault];
        [toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
        [toolbar setDelegate:(id<NSToolbarDelegate>)self];
        [[self window] setToolbar:toolbar];
    }

    NSString *firstIdentifier = (self.toolbarIdentifiers)[0];
    if ([firstIdentifier isEqualTo:NSToolbarFlexibleSpaceItemIdentifier])
        firstIdentifier = (self.toolbarIdentifiers)[1];
    [[[self window] toolbar] setSelectedItemIdentifier:firstIdentifier];
    [self displayViewForIdentifier:firstIdentifier animate:NO];

    [[self window] center];

    [super showWindow:sender];
}


#pragma mark -
#pragma mark Toolbar

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar{
	return self.toolbarIdentifiers;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar{
	return self.toolbarIdentifiers;
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar{
    return [self.toolbarIdentifiers filteredArrayUsingPredicate:
        [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, id bindings) {
        return ![evaluatedObject isEqualTo:NSToolbarFlexibleSpaceItemIdentifier];
    }]];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)identifier willBeInsertedIntoToolbar:(BOOL)willBeInserted{
	return (self.toolbarItems)[identifier];
}

- (void)toggleActivePreferenceView:(NSToolbarItem *)toolbarItem{
	[self displayViewForIdentifier:[toolbarItem itemIdentifier] animate:YES];
}

- (void)displayViewForIdentifier:(NSString *)identifier animate:(BOOL)animate{	
    // Find the view we want to display.
    NSView *newView = (self.toolbarViews)[identifier];

    // See if there are any visible views.
    NSView *oldView = nil;
    if([[self.contentSubview subviews] count] > 0) {
        // Get a list of all of the views in the window. Usually at this
        // point there is just one visible view. But if the last fade
        // hasn't finished, we need to get rid of it now before we move on.
        NSEnumerator *subviewsEnum = [[self.contentSubview subviews] reverseObjectEnumerator];

        // The first one (last one added) is our visible view.
        oldView = [subviewsEnum nextObject];

        // Remove any others.
        NSView *reallyOldView = nil;
        while((reallyOldView = [subviewsEnum nextObject]) != nil){
            [reallyOldView removeFromSuperviewWithoutNeedingDisplay];
        }
    }

    if((!newView && !oldView) || ![newView isEqualTo:oldView]){
        NSRect frame = [newView bounds];
        frame.origin.y = NSHeight([self.contentSubview frame]) - NSHeight([newView bounds]);
        [newView setFrame:frame];
        [self.contentSubview addSubview:newView];
        [[self window] setInitialFirstResponder:newView];

        if(animate && [self crossFade]){
            [self crossFadeView:oldView withView:newView];
        }else{
            [oldView removeFromSuperviewWithoutNeedingDisplay];
            [newView setHidden:NO];
            [[self window] setFrame:[self frameForView:newView] display:YES animate:animate];
        }

        if (_updateWindowTitle)
            self.window.title = [(self.toolbarItems)[identifier] label];
        else self.window.title = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"] ?:
                                 [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    }
}

- (void)loadViewForIdentifier:(NSString *)identifier animate:(BOOL)animate {
    [[[self window] toolbar] setSelectedItemIdentifier:identifier];
    [self displayViewForIdentifier:identifier animate:animate];
}


#pragma mark -
#pragma mark Cross-Fading Methods

- (void)crossFadeView:(NSView *)oldView withView:(NSView *)newView{
    [self.viewAnimation stopAnimation];

    if (!oldView || !newView) return;

    NSEventModifierFlags flags = self.window.currentEvent.modifierFlags;

    if (_shiftSlowsAnimation && (flags & NSEventModifierFlagShift) != 0) {
        [self.viewAnimation setDuration:1.25];
    } else {
        [self.viewAnimation setDuration:0.25];
    }

    NSDictionary *fadeOutDictionary = 
    @{NSViewAnimationTargetKey: oldView,
     NSViewAnimationEffectKey: NSViewAnimationFadeOutEffect};

    NSDictionary *fadeInDictionary = 
    @{NSViewAnimationTargetKey: newView,
     NSViewAnimationEffectKey: NSViewAnimationFadeInEffect};

    NSDictionary *resizeDictionary = 
    @{NSViewAnimationTargetKey: [self window],
     NSViewAnimationStartFrameKey: [NSValue valueWithRect:[[self window] frame]],
     NSViewAnimationEndFrameKey: [NSValue valueWithRect:[self frameForView:newView]]};

    NSArray *animationArray = @[
        fadeOutDictionary,
        fadeInDictionary,
        resizeDictionary,
    ];

    [self.viewAnimation setViewAnimations:animationArray];
    [self.viewAnimation startAnimation];
}

- (void)animationDidEnd:(NSAnimation *)animation{

    // Get a list of all of the views in the window. Hopefully
    // at this point there are two. One is visible and one is hidden.
    NSArray<NSView *> *views = [self.contentSubview.subviews copy];

    // This is our visible view. Just get past it.
    NSView *topMost = views.lastObject;

    // Remove everything else. There should be just one, but
    // if the user does a lot of fast clicking, we might have
    // more than one to remove.
    for (NSView *view in views)
        if (view != topMost)
            [view removeFromSuperview];

    // This is a work-around that prevents the first
    // toolbar icon from becoming highlighted.
    [[self window] makeFirstResponder:nil];
}

// Calculate the window size for the new view.
- (NSRect)frameForView:(NSView *)view{
    NSRect windowFrame = self.window.frame;
	NSRect contentRect = [self.window contentRectForFrameRect:windowFrame];
	CGFloat windowTitleAndToolbarHeight = NSHeight(windowFrame) - NSHeight(contentRect);

    CGFloat x = windowFrame.origin.x;

    if (_windowResizingBehavior != DBPrefsWindowResizingLeftAnchored) {
        CGFloat diff = NSWidth(contentRect) - NSWidth(view.frame);
        if (_windowResizingBehavior == DBPrefsWindowResizingRightAnchored)
            x += diff;
        else x += diff/2;
    }

	windowFrame.size.height = NSHeight(view.frame) + windowTitleAndToolbarHeight;
	windowFrame.size.width = NSWidth(view.frame);
	windowFrame.origin.y = NSMaxY(self.window.frame) - NSHeight(windowFrame);
    windowFrame.origin.x = x;
	
	return windowFrame;
}

// Close the window with cmd+w incase the app doesn't have an app menu
- (void)keyDown:(NSEvent *)theEvent{
    NSString *key = [theEvent charactersIgnoringModifiers];
    if(([theEvent modifierFlags] & NSEventModifierFlagCommand) && [key isEqualToString:@"w"]){
        [self close];
    }else{
        [super keyDown:theEvent];
    }
}

@end
