//
//  AppPrefsWindowController.m
//


#import "AppPrefsWindowController.h"
#import "RulesList.h"
#import "AppleScriptsList.h"
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tableViewSelectionChanged:)
                                                 name:NSTableViewSelectionDidChangeNotification
                                               object:[self appleScriptTableView]];
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

- (IBAction) addShortcutRule:(id)sender {
    [[RulesList sharedRulesList] addRuleWithDirection:@"DR" filter:@"*safari|*chrome" filterType:FILTER_TYPE_WILDCARD actionType:ACTION_TYPE_SHORTCUT shortcutKeyCode:0 shortcutFlag:0 appleScriptId:nil note:@"note"];
    [_rulesTableView reloadData];
}

- (IBAction) addAppleScriptRule:(id)sender {
    [[RulesList sharedRulesList] addRuleWithDirection:@"DR" filter:@"*safari|*chrome" filterType:FILTER_TYPE_WILDCARD actionType:ACTION_TYPE_APPLE_SCRIPT shortcutKeyCode:0 shortcutFlag:0 appleScriptId:@"" note:@"note"];
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
    [self addView:self.appleScriptPreferenceView label:@"AppleScript" image:[NSImage imageNamed:@"AppleScript_Editor_Logo.png"]];
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

- (IBAction)createAppleScript:(id)sender {
    [[AppleScriptsList sharedAppleScriptsList] addAppleScript:@"New AppleScript"
                                                       script:@""];
    [[AppleScriptsList sharedAppleScriptsList] save];
    [[self appleScriptTableView] reloadData];
    [[self appleScriptTableView] selectRowIndexes:[NSIndexSet indexSetWithIndex:[[AppleScriptsList sharedAppleScriptsList] count] - 1] byExtendingSelection:NO];
}

- (IBAction)loadExampleAppleScript:(id)sender {
    NSString* path = [[NSBundle mainBundle] pathForResource:@"ChromeCloseTabsToTheRight"
                                                     ofType:@"applescript"];
    NSError* error = nil;
    [[AppleScriptsList sharedAppleScriptsList] addAppleScript:@"Close Tabs To The Right In Chrome"
                                                       script:[NSString stringWithContentsOfFile:path
                                                                                        encoding:NSUTF8StringEncoding
                                                                                           error:&error]];
    [[AppleScriptsList sharedAppleScriptsList] save];
    [[self appleScriptTableView] reloadData];
    [[self appleScriptTableView] selectRowIndexes:[NSIndexSet indexSetWithIndex:[[AppleScriptsList sharedAppleScriptsList] count] - 1] byExtendingSelection:NO];
}

- (IBAction)removeAppleScript:(id)sender {
    NSInteger index = [[self appleScriptTableView] selectedRow];
    if (index != -1) {
        [[AppleScriptsList sharedAppleScriptsList] removeAtIndex:index];
        [[AppleScriptsList sharedAppleScriptsList] save];
        [[self appleScriptTableView] reloadData];
        index = MIN(index, [[AppleScriptsList sharedAppleScriptsList] count] - 1);
        [[self appleScriptTableView] selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
        [[self rulesTableView] reloadData];
    }
}

static volatile int alreadyInQueue = 0;
static BOOL isEditing = NO;
static dispatch_source_t sourceVNode;
static dispatch_source_t sourceWrite;

- (IBAction)editAppleScriptInExternalEditor:(id)sender {
    NSInteger index = [[self appleScriptTableView] selectedRow];
    if (index == -1) {
        return ;
    }
    
    if (!isEditing) {
        NSString *scriptId = [[AppleScriptsList sharedAppleScriptsList] idAtIndex:index];
        NSError *error = nil;
        
        NSString *path = [NSString stringWithFormat:@"%@/%@", NSTemporaryDirectory(), scriptId];
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil];
        
        path = [NSString stringWithFormat:@"%@/%@", path, @"MacGesture.applescript"];
        
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        [[[AppleScriptsList sharedAppleScriptsList] scriptAtIndex:index] writeToFile:path atomically:NO
                                                                            encoding:NSUTF8StringEncoding error:&error];
        
        // From http://stackoverflow.com/questions/12343833/cocoa-monitor-a-file-for-modifications
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        int fildes = open([path UTF8String], O_EVTONLY);
        
        sourceVNode = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fildes,
                                                                       DISPATCH_VNODE_DELETE | DISPATCH_VNODE_WRITE | DISPATCH_VNODE_EXTEND |
                                                                       DISPATCH_VNODE_ATTRIB | DISPATCH_VNODE_LINK | DISPATCH_VNODE_RENAME |
                                                                       DISPATCH_VNODE_REVOKE, queue);
        
        sourceWrite = dispatch_source_create(DISPATCH_SOURCE_TYPE_WRITE, fildes, 0, queue);
        
        dispatch_block_t handler = ^{
            if (OSAtomicCompareAndSwapInt(0, 1, &alreadyInQueue)) {
                dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 500 * NSEC_PER_MSEC); // 500ms delay
                dispatch_after(time, dispatch_get_main_queue(), ^{
                    NSInteger index = [[AppleScriptsList sharedAppleScriptsList] getIndexById:scriptId];
                    if (index != -1) {
                        NSError *error = nil;
                        NSString *content = [NSString stringWithContentsOfFile:path
                                                                      encoding:NSUTF8StringEncoding
                                                                         error:&error];
                        if (content != nil) {
                            [[AppleScriptsList sharedAppleScriptsList] setScriptAtIndex:index script:content];
                            [[AppleScriptsList sharedAppleScriptsList] save];
                            
                            NSInteger currentIndex = [[self appleScriptTableView] selectedRow];
                            NSString *currentId = [[AppleScriptsList sharedAppleScriptsList] idAtIndex:currentIndex];
                            if (currentId == scriptId && ![content isEqualToString:[[self appleScriptTextField] stringValue]]) {
                                [[self appleScriptTextField] setStringValue:content];
                            }
                        }
                    }
                    alreadyInQueue = 0;
                });
            }
        };
        
        dispatch_source_set_event_handler(sourceVNode, ^{
            unsigned long flags = dispatch_source_get_data(sourceVNode);
            if (flags & DISPATCH_VNODE_WRITE) {
                handler();
            }
            
            if(flags & DISPATCH_VNODE_DELETE)
            {
                dispatch_source_cancel(sourceVNode);
                dispatch_source_cancel(sourceWrite);
            }
        });
        dispatch_source_set_cancel_handler(sourceVNode, ^(void) {
            close(fildes);
        });
        dispatch_resume(sourceVNode);
        
        dispatch_source_set_event_handler(sourceWrite, ^{
            handler();
        });
        dispatch_source_set_cancel_handler(sourceWrite, ^(void) {
            close(fildes);
        });
        dispatch_resume(sourceWrite);
        
        [[NSWorkspace sharedWorkspace] openFile:path];

        isEditing = YES;
        [[self editInExternalEditorButton] setTitle:@"Stop"];
    } else {
        isEditing = NO;
        
        if (sourceVNode) {
            dispatch_source_cancel(sourceVNode);
        }
        
        if (sourceWrite) {
            dispatch_source_cancel(sourceWrite);
        }
        [[self editInExternalEditorButton] setTitle:@"Edit in External Editor"];
    }
    
}

- (IBAction)appleScriptSelectionChanged:(NSNotification *)notification {
    NSComboBox *comboBox = (NSComboBox *)[notification object];
    NSInteger row = [comboBox tag];
    [[RulesList sharedRulesList] setAppleScriptId:[[AppleScriptsList sharedAppleScriptsList] idAtIndex:[comboBox indexOfSelectedItem]] atIndex:row];
}

- (void)tableViewSelectionChanged:(NSNotification* )notification
{
    NSInteger selectedRow = [[self appleScriptTableView] selectedRow];
    
    if (selectedRow != -1) {
        [[self appleScriptTextField] setEnabled:YES];
        [[self appleScriptTextField] setStringValue:[[AppleScriptsList sharedAppleScriptsList] scriptAtIndex:selectedRow]];
    } else {
        [[self appleScriptTextField] setEnabled:NO];
        [[self appleScriptTextField] setStringValue:@""];
    }
}

#pragma mark -
#pragma mark NSComboBoxDataSource Implementation

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox {
    return [[AppleScriptsList sharedAppleScriptsList] count];
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index {
    return [[AppleScriptsList sharedAppleScriptsList] titleAtIndex:index];
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
    } else if ([control.identifier isEqualToString:@"Apple Script"]) {  // edit apple script
        [[AppleScriptsList sharedAppleScriptsList] setScriptAtIndex:[[self appleScriptTableView] selectedRow] script:control.stringValue];
    } else if ([control.identifier isEqualToString:@"Title"]) {  // edit title
        [[AppleScriptsList sharedAppleScriptsList] setTitleAtIndex:[[self appleScriptTableView] selectedRow] title:control.stringValue];
    }
    [[RulesList sharedRulesList] save];
    [[AppleScriptsList sharedAppleScriptsList] save];
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
    if (tableView == [self rulesTableView]) {
        return [[RulesList sharedRulesList] count];
    } else {
        return [[AppleScriptsList sharedAppleScriptsList] count];
    }
}

#pragma mark -
#pragma mark NSTableViewDelegate Implementation

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 25;
}

- (NSView *)tableViewForRules:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSView *result = nil;
    RulesList *rulesList = [RulesList sharedRulesList];
    if ([tableColumn.identifier isEqualToString:@"Gesture"] || [tableColumn.identifier isEqualToString:@"Filter"] || [tableColumn.identifier isEqualToString:@"Note"]) {
        NSTextField *textField = [[NSTextField alloc] init];
        [textField.cell setWraps:NO];
        [textField.cell setScrollable:YES];
        [textField setEditable:YES];
        [textField setBezeled:NO];
        [textField setDrawsBackground:NO];
        if ([tableColumn.identifier isEqualToString:@"Gesture"]) {
            textField.stringValue = [rulesList directionAtIndex:row];
            textField.identifier = @"Gesture";
        } else if ([tableColumn.identifier isEqualToString:@"Filter"]) {
            textField.stringValue = [rulesList filterAtIndex:row];
            textField.identifier = @"Filter";
        } else if ([tableColumn.identifier isEqualToString:@"Note"]) {
            textField.stringValue = [rulesList noteAtIndex:row];
            textField.identifier = @"Note";
        }
        textField.delegate = self;
        textField.tag = row;
        result = textField;
    } else if ([tableColumn.identifier isEqualToString:@"Action"]) {
        if ([rulesList actionTypeAtIndex:row] == ACTION_TYPE_SHORTCUT) {
            SRRecorderControlWithTagid *recordView = [[SRRecorderControlWithTagid alloc] init];
            
            recordView.delegate = self;
            [recordView setAllowedModifierFlags:SRCocoaModifierFlagsMask requiredModifierFlags:0 allowsEmptyModifierFlags:YES];
            recordView.tagid = row;
            recordView.objectValue = @{
                                       @"keyCode" : @([rulesList shortcutKeycodeAtIndex:row]),
                                       @"modifierFlags" : @([rulesList shortcutFlagAtIndex:row]),
                                       };
            result = recordView;
        } else if ([rulesList actionTypeAtIndex:row] == ACTION_TYPE_APPLE_SCRIPT) {
            NSComboBox *comboBox = [[NSComboBox alloc]init];
            [comboBox setUsesDataSource:YES];
            [comboBox setDataSource:self];
            [comboBox setEditable:NO];
            [comboBox setTag:row];
            NSInteger index = [[AppleScriptsList sharedAppleScriptsList] getIndexById:[rulesList appleScriptIdAtIndex:row]];
            if (index != -1) {
                [comboBox selectItemAtIndex:index];
            }
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(appleScriptSelectionChanged:)
                                                         name:NSComboBoxSelectionDidChangeNotification
                                                       object:comboBox];
            result = comboBox;
        }
    }
    return result;
}

- (NSView *)tableViewForAppleScripts:(NSTableColumn *)tableColumn row:(NSInteger)row {
    AppleScriptsList *appleScriptsList = [AppleScriptsList sharedAppleScriptsList];
    NSTextField *textField = [[NSTextField alloc] init];
    [textField.cell setWraps:NO];
    [textField.cell setScrollable:YES];
    [textField setEditable:YES];
    [textField setBezeled:NO];
    [textField setDrawsBackground:NO];
    [textField setDelegate:self];
    [textField setLineBreakMode:NSLineBreakByTruncatingMiddle];
    [textField setStringValue:[appleScriptsList titleAtIndex:row]];
    [textField setIdentifier:@"Title"];
    return textField;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (tableView == [self rulesTableView]) {
        return [self tableViewForRules:tableColumn row:row];
    } else if (tableView == [self appleScriptTableView]) {
        return [self tableViewForAppleScripts:tableColumn row:row];
    }
    return nil;
}

@end
