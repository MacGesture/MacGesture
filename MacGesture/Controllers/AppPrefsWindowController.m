//
//  AppPrefsWindowController.m
//


#import "AppPrefsWindowController.h"
#import "RulesList.h"
#import "AppleScriptsList.h"
#import "SRRecorderControlWithTagid.h"
#import "BlockAllowFilter.h"
#import "MGOptionsDefine.h"
#import "AppDelegate.h"
#import "utils.h"

#pragma mark Preferences controller Interface

@interface AppPrefsWindowController () <WKNavigationDelegate>

@property (nonatomic, strong) AppPickerWindowController *pickerWindowController;

@end

// A hack for the private getter of contentSubview
@interface DBPrefsWindowController (PrivateMethodHack)
-(NSView *)contentSubview;
@end

@interface VerticalTextFieldCell: NSTextFieldCell @end

#pragma mark -
#pragma mark Preferences controller Implementation

@implementation AppPrefsWindowController

@synthesize rulesTableView = _rulesTableView;

static NSSize const PREF_WINDOW_SIZES[3] = {{660, 520}, {800, 660}, {1000, 800}};
static NSInteger const PREF_WINDOW_SIZECOUNT = 3;
static NSInteger currentRulesWindowSizeIndex = 0;
static NSInteger currentFiltersWindowSizeIndex = 0;

static NSDictionary<NSString *, NSString *> *languages;
static NSArray<NSString *> *languagesOrder;

static NSArray<id> *previewPositions;

static NSUserDefaults *defaults;

#define MacGestureRuleDataType @"MacGestureRuleDataType"

static NSArray *exampleAppleScripts;
static BOOL isBigSur = NO;

+ (void)initialize
{
    if (@available(macOS 11.0, *))
        isBigSur = YES;

    languages = @{
        @"": NSLocalizedString(@"System default", nil),
        @"en": NSLocalizedString(@"English", nil),
        @"zh-Hans": NSLocalizedString(@"Chinese", nil),
    }; languagesOrder = @[ @"", @"en", @"zh-Hans" ];

    // Future translations:
//    NSLocalizedString(@"Czech", nil)
//    NSLocalizedString(@"Slovak", nil)

    previewPositions = @[
        @[ @(MGPreviewPositionCenter), NSLocalizedString(@"Center", nil) ],
        @[ @(MGPreviewPositionTopLeft), NSLocalizedString(@"Top Left", nil) ],
        @[ @(MGPreviewPositionTopCenter), NSLocalizedString(@"Top Center", nil) ],
        @[ @(MGPreviewPositionTopRight), NSLocalizedString(@"Top Right", nil) ],
        @[ @(MGPreviewPositionBottomLeft), NSLocalizedString(@"Bottom Left", nil) ],
        @[ @(MGPreviewPositionBottomCenter), NSLocalizedString(@"Bottom Center", nil) ],
        @[ @(MGPreviewPositionBottomRight), NSLocalizedString(@"Bottom Right", nil) ],
    ];

    defaults = [NSUserDefaults standardUserDefaults];

    exampleAppleScripts = @[@"ChromeCloseTabsToTheRight", @"Close Tabs To The Right In Chrome",
            @"OpenMacGesturePreferences", @"Open MacGesture Preferences",
            @"SearchInWeb", @"Search in Web"];

    assert(languages.count == languagesOrder.count);
}

- (void)changeSize:(NSInteger *)index changeSizeButton:(NSButton *)button preferenceView:(NSView *)view {
    *index += 1;
    *index %= PREF_WINDOW_SIZECOUNT;

    button.title = (*index != PREF_WINDOW_SIZECOUNT - 1) ?
        NSLocalizedString(@"Go Bigger", nil) :
        NSLocalizedString(@"Reset Size", nil);

    [view setFrameSize:PREF_WINDOW_SIZES[*index]];
    [self changeWindowSizeToFitInsideView:view];
    [self crossFadeView:view withView:view];
}

- (void)displayViewForIdentifier:(NSString *)identifier animate:(BOOL)animate
{
    if ([identifier isEqual:NSLocalizedString(@"About", nil)])
        [self checkAboutWebViewDisplay];

    [super displayViewForIdentifier:identifier animate:animate];

//    BOOL rules = [identifier isEqual:NSLocalizedString(@"Gestures", nil)];
//
//    if (rules) {
//        self.window.styleMask |= NSWindowStyleMaskResizable;
//        self.window.minSize = PREF_WINDOW_SIZES[0];
//        self.window.maxSize = PREF_WINDOW_SIZES[PREF_WINDOW_SIZECOUNT-1];
//    }
//    else
//        self.window.styleMask &= ~NSWindowStyleMaskResizable;
//
////    self.rulesPreferenceView.translatesAutoresizingMaskIntoConstraints = YES;
////    self.rulesPreferenceView.autoresizingMask |= NSViewWidthSizable | NSViewHeightSizable;
}

- (IBAction)aboutAuthorButtonPressed:(NSButton *)sender {
    NSURL *url = [NSURL URLWithString:sender.alternateTitle];
    if (url) [[NSWorkspace sharedWorkspace] openURL:url];
}

- (void)checkAboutWebViewDisplay {
    if (_webView) return;

    NSURL *url = [[NSBundle mainBundle] URLForResource:@"README" withExtension:@"html"];

    _webView = [[WKWebView alloc] initWithFrame:_webViewBox.bounds];
    _webView.navigationDelegate = self;
    _webView.autoresizingMask = _webViewBox.autoresizingMask;
    _webView.layer.cornerRadius = 4;
    _webView.layer.masksToBounds = YES;
    _webView.layer.borderWidth = 1;
    _webView.layer.borderColor = [NSColor colorWithWhite:0.1 alpha:0.1].CGColor;

    [_webViewBox addSubview:_webView];
    [_webView loadFileURL:url allowingReadAccessToURL:url];
}

- (IBAction)openREADMEInBrowser:(id)sender {
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"README" withExtension:@"html"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (void)windowDidLoad {
    [super windowDidLoad];

    NSWindow *window = [self window];
    window.delegate = self;

    self.autoStartAtLogin.state =
        [LoginServicesHelper isLoginItem] ?
            NSOnState : NSOffState;
    self.versionCode.stringValue = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    [self refreshFilterRadioAndTextViewState];
    self.blockListTextView.string = BWFilter.blockListText;
    self.allowListTextView.string = BWFilter.allowListText;
    self.blockListTextView.font = [NSFont systemFontOfSize:14];
    self.allowListTextView.font = [NSFont systemFontOfSize:14];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tableViewSelectionChanged:)
                                                 name:NSTableViewSelectionDidChangeNotification
                                               object:[self appleScriptTableView]];

    NSArray<NSString *> *langs = languagesOrder;
    langs = [langs mappedArrayUsingBlock:^NSString *(NSString *obj, NSUInteger idx) {
        return languages[obj] ?: obj;
    }];

    [_languageComboBox addItemsWithTitles:langs];

    NSArray<NSString *> *previewPoss = [previewPositions mappedArrayUsingBlock:
      ^NSString *(NSArray<id> *obj, NSUInteger idx) {
        return obj[1];
    }];

    [_previewPositionComboBox addItemsWithTitles:previewPoss];

    if (isBigSur) {
        NSRect rect = _gestureSizeSlider.frame;
        rect.origin.y -= 5; rect.size.height += 6;
        _gestureSizeSlider.frame = rect;
    }

    self.windowResizingBehavior = (isBigSur) ?
        DBPrefsWindowResizingRightAnchored : DBPrefsWindowResizingCentered;

    NSString *language = [defaults arrayForKey:@"AppleLanguages"].firstObject;
    NSUInteger idx = ([languagesOrder containsObject:language]) ?
        [languagesOrder indexOfObject:language] : 0;
    [_languageComboBox selectItemAtIndex:idx];

    MGPreviewPosition position = [MGOptionsDefine getPreviewPosition];
    idx = 0;
    for (NSArray<id> *pos in previewPositions)
        if ([pos[0] integerValue] == position)
            idx = [previewPositions indexOfObject:pos];
    [_previewPositionComboBox selectItemAtIndex:idx];

    for (NSUInteger i = 0;i < [exampleAppleScripts count];i += 2) {
        NSMenuItem *item = [[NSMenuItem alloc] init];
        [item setTitle:exampleAppleScripts[i+1]];
        [item setTag:i];
        [item setAction:@selector(exampleAppleScriptSelected:)];
        [[[self loadAppleScriptExampleButton] menu] addItem:item];
    }

    _rulesTableView.rowHeight = 36;
    _appleScriptTableView.rowHeight = 36;

    [[self rulesTableView] registerForDraggedTypes:@[MacGestureRuleDataType]];
}

- (BOOL)windowShouldClose:(id)sender {

    __auto_type delegate = _delegate;

    [[self window] orderOut:self];

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PrefsDidClose" object:nil];

        if ([delegate respondsToSelector:@selector(appPrefsDidClose)])
            [delegate appPrefsDidClose];
    }];

    return YES;
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
}

//- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize
//{
//    if (_rulesPreferenceView.superview) {
//        CGFloat titleHeight = self.contentSubview.superview.superview.frame.size.height -
//                              self.contentSubview.superview.frame.size.height;
//        NSRect superRect = _rulesPreferenceView.superview.frame;
//        _rulesPreferenceView.frame = NSMakeRect(0, superRect.size.height-frameSize.height, frameSize.width, frameSize.height-(frameSize.height - self.contentSubview.superview.frame.size.height));
//    }
//
//    return frameSize;
//}

- (void)refreshFilterRadioAndTextViewState {
    NSLog(@"BWFilter.isInAllowListMode: %d", BWFilter.isInAllowListMode);

    BOOL blocking = !BWFilter.isInAllowListMode;
    _blockListModeRadio.state = (blocking) ? NSOnState : NSOffState;
    _blockListModeAddButton.enabled = blocking;
    _allowListModeRadio.state = (blocking) ? NSOffState : NSOnState;
    _allowListModeAddButton.enabled = !blocking;

    NSColor *notActive = self.window.backgroundColor;
    NSColor *active = [NSColor textBackgroundColor];

    _blockListTextView.backgroundColor = !blocking ? notActive : active;
    _allowListTextView.backgroundColor = !blocking ? active : notActive;

//    [_allowListTextView.superview.superview needsLayout];
//    [_allowListTextView.superview.superview needsDisplay];
//    [_blockListTextView.superview.superview needsLayout];
//    [_blockListTextView.superview.superview needsDisplay];
}

- (IBAction)addShortcutRule:(id)sender {
    [[RulesList sharedRulesList] addRuleWithDirection:@"DR" filter:@"*safari|*chrome" filterType:FILTER_TYPE_WILDCARD actionType:ACTION_TYPE_SHORTCUT shortcutKeyCode:0 shortcutFlag:0 appleScriptId:nil note:@"note"];
    [_rulesTableView reloadData];
}

- (IBAction)addAppleScriptRule:(id)sender {
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

- (NSString *)toolbarImageNameAdjusted:(NSString *)originalName {
    NSString *name = originalName;
    if (isBigSur) name = [name stringByAppendingString:@"-big_sur"];
    return name;
}

- (void)setupToolbar {
    [self addView:self.generalPreferenceView label:NSLocalizedString(@"General", nil)
            image:[NSImage imageNamed:[self toolbarImageNameAdjusted:@"prefs-general"]]];
    [self addView:self.rulesPreferenceView label:NSLocalizedString(@"Gestures", nil)
            image:[NSImage imageNamed:[self toolbarImageNameAdjusted:@"prefs-gestures"]]];
    [self addView:self.filtersPrefrenceView label:NSLocalizedString(@"Filters", nil)
            image:[NSImage imageNamed:[self toolbarImageNameAdjusted:@"prefs-filters"]]];
    [self addView:self.appleScriptPreferenceView label:NSLocalizedString(@"AppleScript", nil)
            image:[NSImage imageNamed:[self toolbarImageNameAdjusted:@"prefs-applescript"]]];
    if (!isBigSur) [self addFlexibleSpacer];
    [self addView:self.aboutPreferenceView label:NSLocalizedString(@"About", nil)
            image:[NSImage imageNamed:[self toolbarImageNameAdjusted:@"prefs-about"]]];

    // Optional configuration settings.
    self.crossFade = isBigSur; // Pre-Big Sur OSes glitch when crossfading // [defaults boolForKey:@"fade"]]
    self.shiftSlowsAnimation = [defaults boolForKey:@"shiftSlowsAnimation"];
}

- (void)close {
    [defaults synchronize];
    [super close];
}

- (IBAction)autoStartAction:(id)sender {
    [LoginServicesHelper makeLoginItemActive:
        self.autoStartAtLogin.state == NSOnState];
}

- (IBAction)allowBlockRadioClicked:(id)sender {
    if (sender == self.allowListModeRadio) {
        BWFilter.isInAllowListMode = YES;
    } else if (sender == self.blockListModeRadio) {
        BWFilter.isInAllowListMode = NO;
    }
    
    [self refreshFilterRadioAndTextViewState];
}

- (IBAction)filterViewGoBiggerClicked:(id)sender {
    [self changeSize:&currentFiltersWindowSizeIndex changeSizeButton:[self changeFiltersWindowSizeButton] preferenceView:[self filtersPrefrenceView]];
}

- (IBAction)filterViewApplyClicked:(id)sender {
    BWFilter.blockListText = [self.blockListTextView string];
    BWFilter.allowListText = [self.allowListTextView string];
    [self refreshFilterRadioAndTextViewState];
    self.blockListTextView.string = BWFilter.blockListText;
    self.allowListTextView.string = BWFilter.allowListText;
}

- (IBAction)filterBlockListAddClicked:(id)sender {
    self.pickerWindowController = [[AppPickerWindowController alloc] initWithWindowNibName:@"AppPickerWindowController"];
    self.pickerWindowController.addedToTextView = self.blockListTextView;
    [self.pickerWindowController showWindow:self];
}

- (IBAction)filterAllowListAddClicked:(id)sender {
    self.pickerWindowController = [[AppPickerWindowController alloc] initWithWindowNibName:@"AppPickerWindowController"];
    self.pickerWindowController.addedToTextView = self.allowListTextView;
    [self.pickerWindowController showWindow:self];
}

- (IBAction)colorChanged:(id)sender {
    if (sender == _lineColorWell)
        [MGOptionsDefine setLineColor:_lineColorWell.color];
    else if (sender == _previewColorWell)
        [MGOptionsDefine setPreviewColor:_previewColorWell.color];
    else if (sender == _previewBgColorWell)
        [MGOptionsDefine setPreviewBgColor:_previewBgColorWell.color];
    else if (sender == _noteColorWell)
        [MGOptionsDefine setNoteColor:_noteColorWell.color];
    else if (sender == _noteBgColorWell)
        [MGOptionsDefine setNoteBgColor:_noteBgColorWell.color];
}

- (IBAction)chooseFont:(id)sender {
    NSFontManager *fontManager = [NSFontManager sharedFontManager];

    [fontManager setSelectedFont:[NSFont fontWithName:[self.fontNameTextField stringValue] size:[self.fontSizeTextField floatValue]] isMultiple:NO];
    [fontManager setTarget:self];
    
    NSFontPanel *fontPanel = [fontManager fontPanel:YES];

    if (fontPanel.isVisible) {
        [fontPanel close];
        return;
    }

    [fontPanel makeKeyAndOrderFront:self];
    // This allow to change note color via font panel
    [fontManager setSelectedAttributes:@{
        NSForegroundColorAttributeName: [MGOptionsDefine getNoteColor]
    } isMultiple:NO]; // Must setup color AFTER displayed or it will keeps black...
}

- (NSFontPanelModeMask)validModesForFontPanel:(NSFontPanel *)fontPanel
{
    return NSFontPanelModeMaskFace | NSFontPanelModeMaskSize |
        NSFontPanelModeMaskCollection; // | NSFontPanelModeMaskTextColorEffect;
}

- (void)changeFont:(nullable id)sender {
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    NSFont *font = [fontManager convertFont:[NSFont systemFontOfSize:[NSFont systemFontSize]]];
    [defaults setObject:[font fontName] forKey:@"noteFontName"];
    [defaults setDouble:[font pointSize] forKey:@"noteFontSize"];
}

// These two functions repond to text color change.
- (void)setColor:(NSColor *)col forAttribute:(NSString *)attr {
//    if ([attr isEqualToString:@"NSColor"]) {
//        [MGOptionsDefine setNoteColor:col];
//    }
}

- (void)changeAttributes:(id)sender{
    NSDictionary * newAttributes = [sender convertAttributes:@{}];
    NSLog(@"attr:%@",newAttributes);
}

- (IBAction)resetDefaults:(id)sender {
    NSUserDefaults * defs = defaults;
    NSURL *defaultPrefsFile = [[NSBundle mainBundle]
                               URLForResource:@"DefaultPreferences" withExtension:@"plist"];
    NSDictionary *defaultPrefs =
    [NSDictionary dictionaryWithContentsOfURL:defaultPrefsFile];
    for (NSString *key in defaultPrefs) {
        [defs setObject:defaultPrefs[key] forKey:key];
    }
    [defs synchronize];
    
    [MGOptionsDefine restoreDefaults];
}

- (IBAction)pickBtnDidClick:(id)sender {
    if ([_rulesTableView selectedRow] == -1) {
        NSAlert *alert = [NSAlert new];
        alert.alertStyle = NSAlertStyleInformational;
        alert.messageText = NSLocalizedString(@"Please select a filter first!", nil);
        [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
        [alert runModal];
        return;
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
                                                     ofType:@"applescript-src"];
    NSError* error = nil;
    [[AppleScriptsList sharedAppleScriptsList] addAppleScript:exampleAppleScripts[index+1]
        script:[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error]];
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
        NSAlert *alert = [NSAlert new];
        alert.alertStyle = NSAlertStyleInformational;
        alert.messageText = NSLocalizedString(@"Please select an AppleScript first!", nil);
        [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
        [alert runModal];
        return;
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
    NSInteger idx = [_languageComboBox indexOfSelectedItem] % languagesOrder.count;
    if (idx != 0)
        [defaults setObject:@[languagesOrder[idx]] forKey:@"AppleLanguages"];
    else [defaults removeObjectForKey:@"AppleLanguages"];
    
    NSUserNotification *notification = [NSUserNotification new];
    notification.title = @"MacGesture";
    notification.informativeText = NSLocalizedString(@"Restart MacGesture to take effect", nil);
    notification.soundName = NSUserNotificationDefaultSoundName;
    notification.hasActionButton = NO;
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

- (IBAction)previewPositionChanged:(id)sender {
    NSInteger idx = [_previewPositionComboBox indexOfSelectedItem] % previewPositions.count;
    MGPreviewPosition position = [previewPositions[idx][0] integerValue];
    [MGOptionsDefine setPreviewPosition:position];
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
        
        NSUserNotification *notification = [NSUserNotification new];
        notification.title = @"MacGesture";
        notification.informativeText = NSLocalizedString(@"Restart MacGesture to take effect", nil);
        notification.soundName = NSUserNotificationDefaultSoundName;
        notification.hasActionButton = NO;
        
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
        
        NSUserNotification *notification = [NSUserNotification new];
        notification.title = @"MacGesture";
        notification.informativeText = NSLocalizedString(@"Export succeeded", nil);
        notification.soundName = NSUserNotificationDefaultSoundName;
        notification.hasActionButton = NO;
        
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

- (void)recorderControlDidEndRecording:(SRRecorderControl *)aRecorder {
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
            NSAlert *alert = [NSAlert new];
            alert.alertStyle = NSAlertStyleInformational;
            alert.messageText = NSLocalizedString(@"Gesture can only contain \"ULDRZud?*\"", nil);
            [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
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
    return 36;
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

    NSDictionary<NSString *, NSNumber *> *columns =
        @{ @"Gesture": @1, @"Filter": @2, @"Note": @3, @"Action": @4, @"TriggerOnEveryMatch": @5 };
    NSInteger thisColumn = [columns[tableColumn.identifier] integerValue];

    if (thisColumn >= 1 && thisColumn <= 3) { // Gesture, Filter, Note

        NSTextField *textField = [NSTextField new];
        textField.cell = [VerticalTextFieldCell new];
        textField.cell.wraps = NO;
        textField.cell.scrollable = YES;
        textField.editable = YES;
        textField.bezeled = NO;
        textField.drawsBackground = NO;
        textField.enabled = isEnabled;
        textField.identifier = tableColumn.identifier;
        if      (thisColumn == 1) textField.stringValue = [rulesList directionAtIndex:row];
        else if (thisColumn == 2) textField.stringValue = [rulesList filterAtIndex:row];
        else if (thisColumn == 3) textField.stringValue = [rulesList noteAtIndex:row];
        textField.delegate = self;
        textField.tag = row;
        result = textField;

    } else if (thisColumn == 4) { // Action

        if ([rulesList actionTypeAtIndex:row] == ACTION_TYPE_SHORTCUT) {

            SRRecorderControlWithTagid *recordView = [[SRRecorderControlWithTagid alloc] init];
            
            // TODO: Nicer types
            NSUInteger keyCode = [rulesList shortcutKeycodeAtIndex:row];
            NSUInteger modFlag = [rulesList shortcutFlagAtIndex:row];
            
            recordView.delegate = self;
            [recordView setAllowedModifierFlags:SRCocoaModifierFlagsMask
                requiredModifierFlags:0 allowsEmptyModifierFlags:YES];
            recordView.tagid = row;
            recordView.objectValue = [SRShortcut shortcutWithCode:
                keyCode modifierFlags:modFlag characters:nil charactersIgnoringModifiers:nil];
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
                    name:NSComboBoxSelectionDidChangeNotification object:comboBox];
            
            result = comboBox;
        }

    } else if (thisColumn == 5) { // Trigger

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
    NSTextField *textField = [NSTextField new];
    textField.cell = [VerticalTextFieldCell new];
    textField.cell.controlView.frame = textField.bounds;
    textField.cell.wraps = NO;
    textField.cell.scrollable = YES;
    textField.editable = YES;
    textField.bezeled = NO;
    textField.drawsBackground = NO;
    textField.delegate = self;
    textField.lineBreakMode = NSLineBreakByTruncatingMiddle;
    textField.stringValue = [appleScriptsList titleAtIndex:row];
    textField.identifier = @"Title";
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

#pragma mark -
#pragma mark WKNavigationDelegate Implementation

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
    decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    WKNavigationActionPolicy action = WKNavigationActionPolicyAllow;

    NSURL *url = navigationAction.request.URL;

    if (![url.absoluteString hasPrefix:@"file://"]) {
        [[NSWorkspace sharedWorkspace] openURL:navigationAction.request.URL];
        action = WKNavigationActionPolicyCancel;
    }

    decisionHandler(action);
}

@end

#pragma mark -
#pragma mark Non-clickable text field

@interface NonClickableTextField: NSTextField @end

@implementation NonClickableTextField

- (NSView *)hitTest:(NSPoint)point
{
    return nil;
}

@end

#pragma mark -
#pragma mark Vertically centered Text field cell

@implementation VerticalTextFieldCell

- (NSRect)titleRectForBounds:(NSRect)rect
{
    CGFloat stringHeight = self.attributedStringValue.size.height;
    NSRect titleRect = [super titleRectForBounds:rect];
    CGFloat oldOriginY = rect.origin.y;
    titleRect.origin.y = rect.origin.y + (rect.size.height - stringHeight) / 2.0;
    titleRect.size.height = titleRect.size.height - (titleRect.origin.y - oldOriginY);
    return titleRect;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    [super drawInteriorWithFrame:[self titleRectForBounds:cellFrame] inView:controlView];
}

- (void)prepareForInterfaceBuilder
{
    [super prepareForInterfaceBuilder];
}

@end

#pragma mark -
#pragma mark Text view with placeholder

@interface NSTextViewWithPlaceHolder: NSTextView

@property (nonatomic, copy) IBInspectable NSString *placeholder;
@property (nonatomic, strong) NSAttributedString *placeholderAttributed;

@end

@implementation NSTextViewWithPlaceHolder

- (void)setPlaceholder:(NSString *)placeholder {
    _placeholder = placeholder ?: @"";
    _placeholderAttributed = [[NSAttributedString alloc] initWithString:placeholder attributes:@{
        NSForegroundColorAttributeName: [NSColor colorWithWhite:0.5 alpha:0.5],
        NSFontAttributeName: [NSFont systemFontOfSize:14],
    }];
}

- (BOOL)becomeFirstResponder
{
    self.needsDisplay = YES;
    return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
    self.needsDisplay = YES;
    return [super resignFirstResponder];
}

- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];
    if (self.string.length == 0 && self != self.window.firstResponder)
        [_placeholderAttributed drawAtPoint:NSMakePoint(2, 2)];
}

@end
