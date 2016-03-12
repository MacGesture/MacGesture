//
//  AppPrefsWindowController.m
//


#import "AppPrefsWindowController.h"
#import "RulesList.h"
#import "SRRecorderControlWithTagid.h"
#import "NSBundle+LoginItem.h"
#import "BlackWhiteFilter.h"
#import "HexColors.h"
#import "MGOptionsDefine.h"

@interface AppPrefsWindowController ()
@property AppPickerWindowController *pickerWindowController;
@end

// A hack for the private getter of contentSubview
@interface DBPrefsWindowController (PrivateMethodHack)
-(NSView *)contentSubview;
@end

@implementation AppPrefsWindowController

@synthesize rulesTableView = _rulesTableView;

static NSSize const PREF_WINDOW_SIZES[3] = {{658, 315}, {800, 500}, {1000, 640}};
static NSInteger const PREF_WINDOW_SIZECOUNT = 3;
static NSInteger currentRulesWindowSizeIndex = 0;
static NSInteger currentFiltersWindowSizeIndex = 0;

- (void)changeSize:(NSInteger *)index changeSizeButton:(NSButton *)button preferenceView:(NSView *)view {
    *index += 1;
    *index %= PREF_WINDOW_SIZECOUNT;

    NSString *title;

    if (*index != PREF_WINDOW_SIZECOUNT - 1) {
        title = @"Go bigger";
    } else {
        title = @"Reset size";
    }

    [button setTitle:title];

    [view setFrameSize:PREF_WINDOW_SIZES[*index]];
    [self changeWindowSizeToFitInsideView:view];
    [self crossFadeView:view withView:view];
}

- (IBAction)blockFilterDidEdit:(id)sender {
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)windowDidLoad {
    [super windowDidLoad];
//    [self.blockFilter bind:NSValueBinding toObject:[NSUserDefaults standardUserDefaults]  withKeyPath:@"blockFilter" options:nil];
    
    self.autoStartAtLogin.state = [[NSBundle mainBundle] isLoginItem] ? NSOnState : NSOffState;
    self.versionCode.stringValue = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    [self refreshFilterRadioAndTextViewState];
    self.blackListTextView.string = BWFilter.blackListText;
    self.whiteListTextView.string = BWFilter.whiteListText;
    self.blackListTextView.font = [NSFont systemFontOfSize:14];
    self.whiteListTextView.font = [NSFont systemFontOfSize:14];
}

- (void)refreshFilterRadioAndTextViewState {
//    self.blackListModeRadio.cell stat
    NSLog(@"BWFilter.isInWhiteListMode: %d", BWFilter.isInWhiteListMode);
    [self.blackListModeRadio setState:BWFilter.isInWhiteListMode ? NSOffState : NSOnState];
    [self.whiteListModeRadio setState:BWFilter.isInWhiteListMode ? NSOnState : NSOffState];
    NSColor *notActive = self.window.backgroundColor;//[NSColor hx_colorWithHexString:@"ffffff" alpha:0];//[NSColor colorWithCGColor: self.filtersPrefrenceView.layer.backgroundColor];
    //[NSColor hx_colorWithHexString:@"E3E6EA"];
    NSColor *active = [NSColor hx_colorWithHexRGBAString:@"#ffffff"];
    self.blackListTextView.backgroundColor = BWFilter.isInWhiteListMode ? notActive : active;
//    ((NSScrollView *)(self.blackListTextView.superview.superview)).backgroundColor=BWFilter.isInWhiteListMode?notActive:active;
    self.whiteListTextView.backgroundColor = BWFilter.isInWhiteListMode ? active : notActive;
//    ((NSScrollView *)(self.whiteListTextView.superview.superview)).backgroundColor=BWFilter.isInWhiteListMode?active:notActive;

    [self.whiteListTextView.superview.superview needsLayout];
    [self.whiteListTextView.superview.superview needsDisplay];
    [self.blackListTextView.superview.superview needsLayout];
    [self.blackListTextView.superview.superview needsDisplay];
}

- (IBAction)addRule:(id)sender {
    [[RulesList sharedRulesList] addRuleWithDirection:@"DR" filter:@"*safari|*chrome" filterType:FILTER_TYPE_WILDCARD actionType:ACTION_TYPE_SHORTCUT shortcutKeyCode:0 shortcutFlag:0 appleScript:nil note:@"note"];
    [_rulesTableView reloadData];
}

- (IBAction)removeRule:(id)sender {
    [[RulesList sharedRulesList] removeRuleAtIndex:_rulesTableView.selectedRow];
    [_rulesTableView reloadData];
}

- (IBAction)changeSizeOfPreferenceWindow:(id)sender {
    [self changeSize:&currentRulesWindowSizeIndex changeSizeButton:[self changeRulesWindowSizeButton] preferenceView:[self rulesPreferenceView]];

//    NSRect rectOfRules=self.rulesPreferenceView.frame;
//    rectOfRules.size.width=1000;
//    rectOfRules.size.height=640;
//    rectOfRules.origin.x=0;
//    rectOfRules.origin.y=0;
//    self.rulesPreferenceView.frame=rectOfRules;
//    [self.rulesPreferenceView needsLayout];
//    [self.rulesPreferenceView needsDisplay];
//    [self.rulesTableView sizeToFit]
//    self.window size
//    [self loadViewForIdentifier:@"Rules" animate:YES];
}

- (void)changeWindowSizeToFitInsideView:(NSView *)view {
    NSRect frame = [view bounds];
    NSView *p = [self contentSubview];
    frame.origin.y = NSHeight([p frame]) - NSHeight([view bounds]);
    [view setFrame:frame];
}

- (IBAction)resetRules:(id)sender {
    [[RulesList sharedRulesList] reInit];
    [[RulesList sharedRulesList] save];
    [_rulesTableView reloadData];
}

- (void)setupToolbar {
    [self addView:self.generalPreferenceView label:@"General"];
    [self addView:self.rulesPreferenceView label:@"Rules"];
    [self addView:self.filtersPrefrenceView label:@"Filters" image:[NSImage imageNamed:@"list@2x.png"]];
    [self addFlexibleSpacer];
    [self addView:self.aboutPreferenceView label:@"About"];

    // Optional configuration settings.
    [self setCrossFade:[[NSUserDefaults standardUserDefaults] boolForKey:@"fade"]];
    [self setShiftSlowsAnimation:[[NSUserDefaults standardUserDefaults] boolForKey:@"shiftSlowsAnimation"]];

}

- (IBAction)blockFilterPickBtnDidClick:(id)sender {
//    self.pickerWindowController = [[AppPickerWindowController alloc] initWithWindowNibName:@"AppPickerWindowController"];
//
//
////    [self.pickerWindowController  showDialog];
//    [self.pickerWindowController  showWindow:self];
//
//    if([windowController generateFilter]){
//        _blockFilter.stringValue = [windowController generateFilter];
//        [[NSUserDefaults standardUserDefaults] setObject:[windowController generateFilter] forKey:@"blockFilter"];
//    }
//    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)close {
    [[NSUserDefaults standardUserDefaults] synchronize];
    [super close];
}

- (IBAction)autoStartAction:(id)sender {
    switch (self.autoStartAtLogin.state) {
        case NSOnState:
            [[NSBundle mainBundle] addToLoginItems];
            break;
        case NSOffState:
            [[NSBundle mainBundle] removeFromLoginItems];
            break;
    }
}

- (IBAction)whiteBlackRadioClicked:(id)sender {
    if (sender == self.whiteListModeRadio) {
        BWFilter.isInWhiteListMode = YES;
    } else if (sender == self.blackListModeRadio) {
        BWFilter.isInWhiteListMode = NO;
    }

    [self refreshFilterRadioAndTextViewState];
}

- (IBAction)filterViewGoBiggerClicked:(id)sender {
    [self changeSize:&currentFiltersWindowSizeIndex changeSizeButton:[self changeFiltersWindowSizeButton] preferenceView:[self filtersPrefrenceView]];
}

- (IBAction)filterViewApplyClicked:(id)sender {
    BWFilter.blackListText = [self.blackListTextView string];
    BWFilter.whiteListText = [self.whiteListTextView string];
    [self refreshFilterRadioAndTextViewState];
    self.blackListTextView.string = BWFilter.blackListText;
    self.whiteListTextView.string = BWFilter.whiteListText;
}

- (IBAction)filterBlackListAddClicked:(id)sender {
    self.pickerWindowController = [[AppPickerWindowController alloc] initWithWindowNibName:@"AppPickerWindowController"];
    self.pickerWindowController.addedToTextView = self.blackListTextView;
    [self.pickerWindowController showWindow:self];
}

- (IBAction)filterWhiteListAddClicked:(id)sender {
    self.pickerWindowController = [[AppPickerWindowController alloc] initWithWindowNibName:@"AppPickerWindowController"];
    self.pickerWindowController.addedToTextView = self.whiteListTextView;
    [self.pickerWindowController showWindow:self];
}

- (IBAction)colorChanged:(id)sender {
//    SET_LINE_COLOR(self.lineColorWell.color);
    [MGOptionsDefine setLineColor:self.lineColorWell.color];
}
     
- (IBAction)chooseFont:(id)sender {
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    [fontManager setSelectedFont:[NSFont fontWithName:[self.fontNameTextField stringValue] size:[self.fontNameTextField floatValue]] isMultiple:NO];
    [fontManager setTarget:self];
    
    NSFontPanel *fontPanel = [fontManager fontPanel:YES];
    [fontPanel makeKeyAndOrderFront:self];
}

- (void)changeFont:(nullable id)sender {
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    NSFont *font = [fontManager convertFont:[NSFont systemFontOfSize:[NSFont systemFontSize]]];
    [[NSUserDefaults standardUserDefaults] setObject:[font fontName] forKey:@"noteFontName"];
    [[NSUserDefaults standardUserDefaults] setDouble:[font pointSize] forKey:@"noteFontSize"];
}

- (IBAction)resetDefaults:(id)sender {
    NSUserDefaults * defs = [NSUserDefaults standardUserDefaults];
    NSDictionary * dict = [defs dictionaryRepresentation];
    for (NSString *key in dict) {
        [defs removeObjectForKey:key];
    }
    [defs synchronize];
    
    [MGOptionsDefine resetColor];
}

- (IBAction)pickBtnDidClick:(id)sender {
    if ([_rulesTableView selectedRow] == -1) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Select a filter first!"];
        [alert runModal];
        return ;
    }
    
    self.pickerWindowController = [[AppPickerWindowController alloc] initWithWindowNibName:@"AppPickerWindowController"];
    self.pickerWindowController.parentWindow = self;
    self.pickerWindowController.indexForParentWindow = [_rulesTableView selectedRow];
    [self.pickerWindowController showWindow:self];
    
    //    [windowController showDialog];
    //    if([windowController generateFilter]){
    //        [[RulesList sharedRulesList] setWildFilter:[windowController generateFilter] atIndex:index];
    //    }
    //    [[RulesList sharedRulesList] save];
    //    [_rulesTableView reloadData];
}

#pragma mark -
#pragma mark SRRecorderControlDelegate Implementation

- (void)shortcutRecorderDidEndRecording:(SRRecorderControl *)aRecorder {
    NSInteger id = ((SRRecorderControlWithTagid *) aRecorder).tagid;
    NSUInteger keycode = [aRecorder.objectValue[@"keyCode"] unsignedIntegerValue];
    NSUInteger flag = [[aRecorder objectValue][@"modifierFlags"] unsignedIntegerValue];
    [[RulesList sharedRulesList] setShortcutWithKeycode:keycode withFlag:flag atIndex:id];
}

#pragma mark -
#pragma mark NSControlTextEditingDelegate Implementation

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {
    // control is editfield,control.id == row,control.identifier == "Gesture"|"Filter"|Other(only saving)
    if ([control.identifier isEqualToString:@"Gesture"]) {    // edit gesture
        NSString *gesture = [control.stringValue uppercaseString];
        NSCharacterSet *invalidGestureCharacters = [NSCharacterSet characterSetWithCharactersInString:@"ULDR"];
        invalidGestureCharacters = [invalidGestureCharacters invertedSet];
        if ([gesture rangeOfCharacterFromSet:invalidGestureCharacters].location != NSNotFound) {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"Gesture should only contain \"ULDR\""];
            [alert runModal];
            return NO;
        }
        [control setStringValue:gesture];
        [[RulesList sharedRulesList] setDirection:gesture atIndex:control.tag];
    } else if ([control.identifier isEqualToString:@"Filter"]) {  // edit filter
        [[RulesList sharedRulesList] setWildFilter:control.stringValue atIndex:control.tag];
    } else if ([control.identifier isEqualToString:@"Note"]) {  // edit filter
        [[RulesList sharedRulesList] setNote:control.stringValue atIndex:control.tag];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    return YES;
}

#pragma mark -
#pragma mark AppPickerCallback Implementation

- (void)rulePickCallback:(NSString *)rulesStringSplitedByStick atIndex:(NSInteger)index {
    [[RulesList sharedRulesList] setWildFilter:rulesStringSplitedByStick atIndex:index];
    [[RulesList sharedRulesList] save];
    [_rulesTableView reloadData];
}

#pragma mark -
#pragma mark NSTableViewDataSource Implementation

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [[RulesList sharedRulesList] count];
}

#pragma mark -
#pragma mark NSTableViewDelegate Implementation

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 25;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSView *result = nil;
    RulesList *rulesList = [RulesList sharedRulesList];
    if ([tableColumn.identifier isEqualToString:@"Gesture"] || [tableColumn.identifier isEqualToString:@"Filter"] || [tableColumn.identifier isEqualToString:@"Note"]) {
        NSTextField *textfiled = [[NSTextField alloc] init];
        [textfiled.cell setWraps:NO];
        [textfiled.cell setScrollable:YES];
        [textfiled setEditable:YES];
        [textfiled setBezeled:NO];
        [textfiled setDrawsBackground:NO];
        if ([tableColumn.identifier isEqualToString:@"Gesture"]) {
            textfiled.stringValue = [rulesList directionAtIndex:(NSUInteger) row];
            textfiled.identifier = @"Gesture";
        } else if ([tableColumn.identifier isEqualToString:@"Filter"]) {
            textfiled.stringValue = [rulesList filterAtIndex:(NSUInteger) row];
            textfiled.identifier = @"Filter";
        } else if ([tableColumn.identifier isEqualToString:@"Note"]) {
            textfiled.stringValue = [rulesList noteAtIndex:(NSUInteger) row];
            textfiled.identifier = @"Note";
        }
        textfiled.delegate = self;
        textfiled.tag = row;
        result = textfiled;
    } else if ([tableColumn.identifier isEqualToString:@"Action"]) {
        // "Action"
        // No only shortcut action support
        
        SRRecorderControl *recordView = [[SRRecorderControlWithTagid alloc] init];
        
        recordView.delegate = self;
        [recordView setAllowedModifierFlags:SRCocoaModifierFlagsMask requiredModifierFlags:0 allowsEmptyModifierFlags:YES];
        ((SRRecorderControlWithTagid *) recordView).tagid = row;
        recordView.objectValue = @{
                                   @"keyCode" : @([rulesList shortcutKeycodeAtIndex:row]),
                                   @"modifierFlags" : @([rulesList shortcutFlagAtIndex:row]),
                                   };
        result = recordView;
    }
    return result;
}

@end
