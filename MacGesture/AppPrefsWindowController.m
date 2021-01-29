//
//  AppPrefsWindowController.m
//


#import "AppPrefsWindowController.h"
#import "RulesList.h"
#import "AppleScriptsList.h"
#import "SRRecorderControlWithTagid.h"
#import "BlackWhiteFilter.h"
#import "HexColors.h"
#import "MGOptionsDefine.h"
#import "AppDelegate.h"

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

#define MacGestureRuleDataType @"MacGestureRuleDataType"

static NSArray *exampleAppleScripts;

+ (void)initialize {
    exampleAppleScripts = @[@"ChromeCloseTabsToTheRight", @"Close Tabs To The Right In Chrome",
            @"OpenMacGesturePreferences", @"Open MacGesture Preferences",
            @"SearchInWeb", @"Search in Web"];
}

- (void)changeSize:(NSInteger *)index changeSizeButton:(NSButton *)button preferenceView:(NSView *)view {
    *index += 1;
    *index %= PREF_WINDOW_SIZECOUNT;
    
    NSString *title;
    
    if (*index != PREF_WINDOW_SIZECOUNT - 1) {
        title = NSLocalizedString(@"Go bigger", nil);
    } else {
        title = NSLocalizedString(@"Reset size", nil);
    }
    
    [button setTitle:title];
    
    [view setFrameSize:PREF_WINDOW_SIZES[*index]];
    [self changeWindowSizeToFitInsideView:view];
    [self crossFadeView:view withView:view];
}

- (IBAction)blockFilterDidEdit:(id)sender {
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (LSSharedFileListItemRef)itemRefWithListRef:(LSSharedFileListRef)listRef {
    NSURL *bundleURL = [NSBundle mainBundle].bundleURL;
    CFArrayRef arr = LSSharedFileListCopySnapshot(listRef, NULL);
    
    for (NSInteger i = 0; i < CFArrayGetCount(arr); ++i) {
        LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)CFArrayGetValueAtIndex(arr, i);
        CFURLRef urlRef;
        OSStatus error = LSSharedFileListItemResolve(itemRef, 0, &urlRef, NULL);
        
        if (error != noErr) {
            continue;
        }
        
        if (CFEqual(urlRef, (__bridge CFURLRef)bundleURL)) {
            CFRetain(itemRef);
            CFRelease(arr);
            CFRelease(urlRef);
            return itemRef;
        }
        CFRelease(urlRef);
    }
    CFRelease(arr);
    return NULL;
}

- (BOOL)isLoginItem {
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (!loginItems) return NO;
    
    LSSharedFileListItemRef loginItemRef = [self itemRefWithListRef:loginItems];
    if (!loginItemRef) {
        CFRelease(loginItems);
        return NO;
    }
    CFRelease(loginItems);
    CFRelease(loginItemRef);
    return YES;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    //    [self.blockFilter bind:NSValueBinding toObject:[NSUserDefaults standardUserDefaults]  withKeyPath:@"blockFilter" options:nil];
    
    [[self window] setDelegate:self];
    
    
    self.autoStartAtLogin.state = [self isLoginItem] ? NSOnState : NSOffState;
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

    [[self languageComboBox] addItemsWithObjectValues:@[@"en", @"zh-Hans"]];
    
    NSArray *languages = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"];
    if (languages) {
        [[self languageComboBox] selectItemWithObjectValue:languages[0]];
    }
    
    for (NSUInteger i = 0;i < [exampleAppleScripts count];i += 2) {
        NSMenuItem *item = [[NSMenuItem alloc] init];
        [item setTitle:exampleAppleScripts[i+1]];
        [item setTag:i];
        [item setAction:@selector(exampleAppleScriptSelected:)];
        [[[self loadAppleScriptExampleButton] menu] addItem:item];
    }
    
    NSString *readme = [[NSBundle mainBundle] pathForResource:@"README" ofType:@"html"];
    NSString *content = [NSString stringWithContentsOfFile:readme encoding:NSUTF8StringEncoding error:NULL];
    
    [[[self webView] mainFrame] loadHTMLString:content baseURL:[NSURL URLWithString:readme]];

    [[self rulesTableView] registerForDraggedTypes:@[MacGestureRuleDataType]];
}

- (BOOL)windowShouldClose:(id)sender {
    [[self window] orderOut:self];
    return NO;
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
    [self addView:self.generalPreferenceView label:NSLocalizedString(@"General", nil) image:[NSImage imageNamed:@"General.png"]];
    [self addView:self.rulesPreferenceView label:NSLocalizedString(@"Rules", nil) image:[NSImage imageNamed:@"Rules.png"]];
    [self addView:self.filtersPrefrenceView label:NSLocalizedString(@"Filters", nil) image:[NSImage imageNamed:@"list@2x.png"]];
    [self addView:self.appleScriptPreferenceView label:NSLocalizedString(@"AppleScript", nil) image:[NSImage imageNamed:@"AppleScript_Editor_Logo.png"]];
    [self addFlexibleSpacer];
    [self addView:self.aboutPreferenceView label:NSLocalizedString(@"About", nil) image:[NSImage imageNamed:@"About.png"]];
    
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
    NSURL *bundleURL = [NSBundle mainBundle].bundleURL;
    LSSharedFileListRef loginItems;
    LSSharedFileListItemRef item, loginItemRef;
    switch (self.autoStartAtLogin.state) {
        case NSOnState:
            loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
            if (!loginItems) {
                return;
            }
            
            item = LSSharedFileListInsertItemURL(loginItems,
                                                 kLSSharedFileListItemLast,
                                                 NULL,
                                                 NULL,
                                                 (__bridge CFURLRef)bundleURL,
                                                 NULL,
                                                 NULL);
            
            if (item) {
                CFRelease(item);
            }
            CFRelease(loginItems);
            break;
        case NSOffState:
            loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
            if (!loginItems) {
                return;
            }
            
            loginItemRef = [self itemRefWithListRef:loginItems];
            if (!loginItemRef) {
                CFRelease(loginItems);
                return;
            }
            
            LSSharedFileListItemRemove(loginItems, loginItemRef);
            
            CFRelease(loginItems);
            CFRelease(loginItemRef);
            break;
        default:
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
    // This allow to change note color via font panel
    [fontManager setSelectedAttributes:@{NSForegroundColorAttributeName:[MGOptionsDefine getNoteColor]} isMultiple:NO]; //must setup color AFTER displayed or it will keeps black...
}

- (void)changeFont:(nullable id)sender {
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    NSFont *font = [fontManager convertFont:[NSFont systemFontOfSize:[NSFont systemFontSize]]];
    [[NSUserDefaults standardUserDefaults] setObject:[font fontName] forKey:@"noteFontName"];
    [[NSUserDefaults standardUserDefaults] setDouble:[font pointSize] forKey:@"noteFontSize"];
}

// These two functions repond to text color change.
- (void)setColor:(NSColor *)col forAttribute:(NSString *)attr {
    if ([attr isEqualToString:@"NSColor"]) {
        [MGOptionsDefine setNoteColor:col];
    }
}

- (void)changeAttributes:(id)sender{
    NSDictionary * newAttributes = [sender convertAttributes:@{}];
    NSLog(@"attr:%@",newAttributes);
}

- (IBAction)resetDefaults:(id)sender {
    NSUserDefaults * defs = [NSUserDefaults standardUserDefaults];
    NSURL *defaultPrefsFile = [[NSBundle mainBundle]
                               URLForResource:@"DefaultPreferences" withExtension:@"plist"];
    NSDictionary *defaultPrefs =
    [NSDictionary dictionaryWithContentsOfURL:defaultPrefsFile];
    for (NSString *key in defaultPrefs) {
        [defs setObject:defaultPrefs[key] forKey:key];
    }
    [defs synchronize];
    
    [MGOptionsDefine resetColors];
}

- (IBAction)pickBtnDidClick:(id)sender {
    if ([_rulesTableView selectedRow] == -1) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:NSLocalizedString(@"Okay, I know", nil)];
        [alert setAlertStyle:NSInformationalAlertStyle];
        [alert setMessageText:NSLocalizedString(@"Select a filter first!", nil)];
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

- (void)exampleAppleScriptSelected:(id)sender {
    NSInteger index = [sender tag];
    
    NSString* path = [[NSBundle mainBundle] pathForResource:exampleAppleScripts[index]
                                                     ofType:@"applescript"];
    NSError* error = nil;
    [[AppleScriptsList sharedAppleScriptsList] addAppleScript:exampleAppleScripts[index+1]
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
        if ([[AppleScriptsList sharedAppleScriptsList] count] > 0) {
            index = MIN(index, [[AppleScriptsList sharedAppleScriptsList] count] - 1);
            [[self appleScriptTableView] selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
        } else {
            [[self appleScriptTextField] setEnabled:NO];
            [[self appleScriptTextField] setStringValue:@""];
        }
        
        [[self rulesTableView] reloadData];
    }
}

static BOOL isEditing = NO;
static NSString *currentScriptPath = nil;
static NSString *currentScriptId = nil;

- (IBAction)editAppleScriptInExternalEditor:(id)sender {
    NSInteger index = [[self appleScriptTableView] selectedRow];
    if (index == -1) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:NSLocalizedString(@"Okay, I know", nil)];
        [alert setAlertStyle:NSInformationalAlertStyle];
        [alert setMessageText:NSLocalizedString(@"Select an AppleScript first!", nil)];
        [alert runModal];
        return ;
    }
    
    if (!isEditing) {
        currentScriptId = [[AppleScriptsList sharedAppleScriptsList] idAtIndex:index];
        NSError *error = nil;
        
        currentScriptPath = [NSString stringWithFormat:@"%@/%@", NSTemporaryDirectory(), currentScriptId];
        [[NSFileManager defaultManager] createDirectoryAtPath:currentScriptPath withIntermediateDirectories:NO attributes:nil error:nil];
        
        currentScriptPath = [NSString stringWithFormat:@"%@/%@", currentScriptPath, @"MacGesture.applescript"];
        
        [[NSFileManager defaultManager] removeItemAtPath:currentScriptPath error:&error];
        [[[AppleScriptsList sharedAppleScriptsList] scriptAtIndex:index] writeToFile:currentScriptPath atomically:YES
                                                                            encoding:NSUTF8StringEncoding error:&error];
        [[NSWorkspace sharedWorkspace] openFile:currentScriptPath];
        
        isEditing = YES;
        [[self editInExternalEditorButton] setTitle:NSLocalizedString(@"Stop",nil)];
    } else {
        NSError *error = nil;
        NSString *content = [NSString stringWithContentsOfFile:currentScriptPath
                                                      encoding:NSUTF8StringEncoding
                                                         error:&error];
        
        if (content != nil) {
            [[AppleScriptsList sharedAppleScriptsList] setScriptAtIndex:index script:content];
            [[AppleScriptsList sharedAppleScriptsList] save];
            
            NSInteger currentIndex = [[self appleScriptTableView] selectedRow];
            NSString *currentId = [[AppleScriptsList sharedAppleScriptsList] idAtIndex:currentIndex];
            if (currentId == currentScriptId && ![content isEqualToString:[[self appleScriptTextField] stringValue]]) {
                [[self appleScriptTextField] setStringValue:content];
            }
        }
        
        isEditing = NO;
        [[self editInExternalEditorButton] setTitle:NSLocalizedString(@"Edit in External Editor",nil)];
    }
    
    [[self appleScriptTableView] setEnabled:!isEditing];
    [[self loadAppleScriptExampleButton] setEnabled:!isEditing];
    [[self addAppleScriptButton] setEnabled:!isEditing];
    [[self removeAppleScriptButton] setEnabled:!isEditing];
    [[self appleScriptTextField] setEnabled:!isEditing];
    
}

- (IBAction)appleScriptSelectionChanged:(NSNotification *)notification {
    NSComboBox *comboBox = (NSComboBox *)[notification object];
    NSInteger row = [comboBox tag];
    [[RulesList sharedRulesList] setAppleScriptId:[[AppleScriptsList sharedAppleScriptsList] idAtIndex:[comboBox indexOfSelectedItem]] atIndex:row];
}

- (IBAction)onTriggerOnEveryMatchChanged:(id)sender {
    NSButton *button = sender;
    NSInteger index = [button tag];
    [[RulesList sharedRulesList] setTriggerOnEveryMatch:[button state] atIndex:index];
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

- (IBAction)showInStatusBarCheckChanged:(id)sender {
    [[AppDelegate appDelegate] updateStatusBarItem];
}

- (IBAction)languageChanged:(id)sender {
    NSString *language = [[self languageComboBox] objectValueOfSelectedItem];
    [[NSUserDefaults standardUserDefaults] setObject:@[language] forKey:@"AppleLanguages"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = @"MacGesture";
    notification.informativeText = NSLocalizedString(@"Restart MacGesture to take effect", nil);
    notification.soundName = NSUserNotificationDefaultSoundName;
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

- (IBAction)onToggleMacGestureEnabled:(id)sender {
    NSButton *button = (NSButton *)sender;
    bool enabled = [button state];
    [[AppDelegate appDelegate] setEnabled:enabled];
}

- (IBAction)doImport:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    
    if ([panel runModal] == NSModalResponseOK) {
        NSURL *url = [panel URL];
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:@"/bin/sh"];
        
        NSArray *arguments = @[@"-c",
                @"defaults import com.codefalling.MacGesture -"];
        
        [task setArguments:arguments];
        NSPipe *pipe = [NSPipe pipe];
        [task setStandardInput:pipe];
        
        NSFileHandle *file = [pipe fileHandleForWriting];
        
        [task launch];
        
        NSData *data = [NSData dataWithContentsOfURL:url];
        if (data) {
            [file writeData:data];
        }
        [file closeFile];
        
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"MacGesture";
        notification.informativeText = NSLocalizedString(@"Restart MacGesture to take effect", nil);
        notification.soundName = NSUserNotificationDefaultSoundName;
        
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }
}

- (IBAction)doExport:(id)sender {
    NSSavePanel *panel = [NSSavePanel savePanel];
    
    if ([panel runModal] == NSModalResponseOK) {
        NSURL *url = [panel URL];
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:@"/bin/sh"];
        
        NSArray *arguments = @[@"-c",
                @"defaults export com.codefalling.MacGesture -"];
        
        [task setArguments:arguments];
        NSPipe *pipe = [NSPipe pipe];
        [task setStandardOutput:pipe];
        
        NSFileHandle *file = [pipe fileHandleForReading];
        
        [task launch];
        
        NSData *data = [file readDataToEndOfFile];
        if (data) {
            [data writeToURL:url atomically:YES];
        }
        [file closeFile];
        
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"MacGesture";
        notification.informativeText = NSLocalizedString(@"Export succeeded", nil);
        notification.soundName = NSUserNotificationDefaultSoundName;
        
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }
}

-(IBAction)toggleRule:(id)sender {
    NSInteger row = [_rulesTableView clickedRow];
    if (row != -1) {
        [[RulesList sharedRulesList] toggleRule:row];
        [_rulesTableView reloadData];
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
        NSString *gesture = control.stringValue;
        NSCharacterSet *invalidGestureCharacters = [NSCharacterSet characterSetWithCharactersInString:@"ULDRZud?*"];
        invalidGestureCharacters = [invalidGestureCharacters invertedSet];
        if ([gesture rangeOfCharacterFromSet:invalidGestureCharacters].location != NSNotFound) {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:NSLocalizedString(@"Okay, I know", nil)];
            [alert setAlertStyle:NSInformationalAlertStyle];
            [alert setMessageText:NSLocalizedString(@"Gesture must only contain \"ULDRZud?*\"", nil)];
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

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard declareTypes:@[MacGestureRuleDataType] owner:self];
    [pboard setData:data forType:MacGestureRuleDataType];
    return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op {
    if(op == NSTableViewDropAbove) {
        return NSDragOperationMove;
    }
    return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation {
    NSPasteboard* pboard = [info draggingPasteboard];
    NSData* rowData = [pboard dataForType:MacGestureRuleDataType];
    NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
    NSInteger dragRow = [rowIndexes firstIndex];
    
    [[RulesList sharedRulesList] moveRuleFrom:dragRow ruleTo:row];
    [_rulesTableView noteNumberOfRowsChanged];
    if (dragRow < row) {
        [_rulesTableView moveRowAtIndex:dragRow toIndex:row-1];
    } else {
        [_rulesTableView moveRowAtIndex:dragRow toIndex:row];
    }
    return YES;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 25;
}

- (void)tableView:(NSTableView *)tableView
    didAddRowView:(NSTableRowView *)rowView
           forRow:(NSInteger)row {
    if (![[RulesList sharedRulesList] enabledAtIndex:row]) {
        [rowView setBackgroundColor:[[NSColor blackColor] colorWithAlphaComponent:0.3]];
    }
}

- (NSView *)tableViewForRules:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSView *result = nil;
    RulesList *rulesList = [RulesList sharedRulesList];
    BOOL isEnabled = [rulesList enabledAtIndex:row];
    if ([tableColumn.identifier isEqualToString:@"Gesture"] || [tableColumn.identifier isEqualToString:@"Filter"] || [tableColumn.identifier isEqualToString:@"Note"]) {
        NSTextField *textField = [[NSTextField alloc] init];
        [textField.cell setWraps:NO];
        [textField.cell setScrollable:YES];
        [textField setEditable:YES];
        [textField setBezeled:NO];
        [textField setDrawsBackground:NO];
        [textField setEnabled:isEnabled];
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
            [recordView setEnabled:isEnabled];
            
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
            [comboBox setEnabled:isEnabled];
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(appleScriptSelectionChanged:)
                                                         name:NSComboBoxSelectionDidChangeNotification
                                                       object:comboBox];
            
            result = comboBox;
        }
    } else if ([tableColumn.identifier isEqualToString:@"TriggerOnEveryMatch"]) {
        NSButton *checkButton = [[NSButton alloc] init];
        [checkButton setButtonType:NSSwitchButton];
        [checkButton setState:[rulesList triggerOnEveryMatchAtIndex:row]];
        [checkButton setTag:row];
        [checkButton setAction:@selector(onTriggerOnEveryMatchChanged:)];
        [checkButton setImagePosition:NSImageOnly];
        [checkButton setEnabled:isEnabled];
        
        result = checkButton;
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
