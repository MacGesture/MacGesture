//
//  AppPrefsWindowController.m
//


#import "AppPrefsWindowController.h"
#import "AppDelegate.h"
#import "RulesList.h"
#import "SRRecorderControl.h"
#import "SRRecorderControlWithTagid.h"
#import "AppPickerWindowController.h"
#import "NSBundle+LoginItem.h"


@implementation AppPrefsWindowController

@synthesize rulesTableView = _rulesTableView;


- (IBAction)blockFilterDidEdit:(id)sender {
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self.openPreOnStartup bind:NSValueBinding toObject:[NSUserDefaults standardUserDefaults]  withKeyPath:@"openPrefOnStartup" options:nil];
    [self.blockFilter bind:NSValueBinding toObject:[NSUserDefaults standardUserDefaults]  withKeyPath:@"blockFilter" options:nil];
    [self.showGesturePreview bind:NSValueBinding toObject:[NSUserDefaults standardUserDefaults]  withKeyPath:@"showGesturePreview" options:nil];
    [self.showGestureNote bind:NSValueBinding toObject:[NSUserDefaults standardUserDefaults]  withKeyPath:@"showGestureNote" options:nil];
    [self.disableMousePathBtn bind:NSValueBinding toObject:[NSUserDefaults standardUserDefaults]  withKeyPath:@"disableMousePath" options:nil];

    [self.autoCheckUpdate bind:NSValueBinding toObject:self.updater withKeyPath:@"automaticallyChecksForUpdates" options:nil];
    [self.autoDownUpdate bind:NSValueBinding toObject:self.updater withKeyPath:@"automaticallyDownloadsUpdates" options:nil];

    self.autoStartAtLogin.state = [[NSBundle mainBundle] isLoginItem]?NSOnState : NSOffState;
    self.versionCode.stringValue = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
}

- (IBAction)addRule:(id)sender {
    [[RulesList sharedRulesList] addRuleWithDirection:@"DR" filter:@"*safari|*chrome" filterType:FILETER_TYPE_WILD actionType:ACTION_TYPE_SHORTCUT shortcutKeyCode:0 shortcutFlag:0 appleScript:nil note:@"note"];
    [_rulesTableView reloadData];
}

- (IBAction)removeRule:(id)sender {
    [[RulesList sharedRulesList] removeRuleAtIndex:_rulesTableView.selectedRow];
    [_rulesTableView reloadData];
}

- (IBAction)goBiggerOfGestureView:(id)sender {
    [self.rulesPreferenceView setFrameSize:NSSizeFromCGSize(CGSizeMake(800,800))];
    NSRect frame = [self.rulesPreferenceView bounds];
    NSView* p= [self performSelector:@selector(contentSubview)];
    frame.origin.y = NSHeight([p frame]) - NSHeight([self.rulesPreferenceView bounds]);
    [self.rulesPreferenceView setFrame:frame];
//    NSRect rectOfRules=self.rulesPreferenceView.frame;
//    rectOfRules.size.width=1000;
//    rectOfRules.size.height=640;
//    rectOfRules.origin.x=0;
//    rectOfRules.origin.y=0;
//    self.rulesPreferenceView.frame=rectOfRules;
//    [self.rulesPreferenceView needsLayout];
//    [self.rulesPreferenceView needsDisplay];

//    [self.rulesTableView sizeToFit];
    [self crossFadeView:self.rulesPreferenceView withView:self.rulesPreferenceView];

//    self.window size
    [self loadViewForIdentifier:@"Rules" animate:YES];
}


- (IBAction)resetRules:(id)sender {
    [[RulesList sharedRulesList] reInit];
    [[RulesList sharedRulesList] save];
    [_rulesTableView reloadData];
}

- (void)setupToolbar{
    [self addView:self.generalPreferenceView label:@"General"];
    [self addView:self.rulesPreferenceView label:@"Rules"];

    [self addView:self.updatesPreferenceView label:@"Updates"];
    [self addFlexibleSpacer];
    [self addView:self.aboutPreferenceView label:@"About"];

    // Optional configuration settings.
    [self setCrossFade:[[NSUserDefaults standardUserDefaults] boolForKey:@"fade"]];
    [self setShiftSlowsAnimation:[[NSUserDefaults standardUserDefaults] boolForKey:@"shiftSlowsAnimation"]];


}
- (IBAction)blockFilterPickBtnDidClick:(id)sender {
    AppPickerWindowController *windowController = [[AppPickerWindowController alloc] initWithWindowNibName:@"AppPickerWindowController"];

    [windowController showDialog];

    if([windowController generateFilter]){
        _blockFilter.stringValue = [windowController generateFilter];
        [[NSUserDefaults standardUserDefaults] setObject:[windowController generateFilter] forKey:@"blockFilter"];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)autoCheckUpdateDidClick:(id)sender {
    //self.updater.automaticallyChecksForUpdates = (bool)(self.autoCheckUpdate.intValue);

}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [[RulesList sharedRulesList] count];
}


- (void)shortcutRecorderDidEndRecording:(SRRecorderControl *)aRecorder {
    NSInteger id = ((SRRecorderControlWithTagid *)aRecorder).tagid;
    NSUInteger keycode = [aRecorder.objectValue[@"keyCode"] unsignedIntegerValue];
    NSUInteger flag = [[aRecorder objectValue][@"modifierFlags"] unsignedIntegerValue];
    [[RulesList sharedRulesList] setShortcutWithKeycode:keycode withFlag:flag atIndex:id];
}

- (void)close {
    [[NSUserDefaults standardUserDefaults] synchronize];
    [super close];
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {
    // control is editfield,control.id == row,control.identifier == "Gesture"|"Filter"|Other(only saving)
    if([control.identifier isEqualToString:@"Gesture"]){    // edit gesture
        [[RulesList sharedRulesList] setDirection:control.stringValue atIndex:control.tag];
    }else if([control.identifier isEqualToString:@"Filter"]){  // edit filter
        [[RulesList sharedRulesList] setWildFilter:control.stringValue atIndex:control.tag];
    }else if([control.identifier isEqualToString:@"Note"]){  // edit filter
        [[RulesList sharedRulesList] setNote:control.stringValue atIndex:control.tag];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    return YES;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 25;
}

- (void)pickBtnDidClick:(id)sender{
    AppPickerWindowController *windowController = [[AppPickerWindowController alloc] initWithWindowNibName:@"AppPickerWindowController"];

    [windowController showDialog];
    NSInteger index = ((NSButton*)sender).tag;
    if([windowController generateFilter]){
        [[RulesList sharedRulesList] setWildFilter:[windowController generateFilter] atIndex:index];
    }
    [[RulesList sharedRulesList] save];
    [_rulesTableView reloadData];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {

    NSView *result = nil;
    RulesList *rulesList = [RulesList sharedRulesList];
    if([tableColumn.identifier isEqualToString:@"Gesture"] || [tableColumn.identifier isEqualToString:@"Filter"] || [tableColumn.identifier isEqualToString:@"Note"]){
        NSTextField *textfiled = [[NSTextField alloc] init];
        [textfiled.cell setWraps:NO];
        [textfiled.cell setScrollable:YES];
        textfiled.editable = YES;
        textfiled.bezeled = NO;
        if([tableColumn.identifier isEqualToString:@"Gesture"]){
            textfiled.stringValue = [rulesList directionAtIndex:(NSUInteger)row];
            textfiled.identifier = @"Gesture";
        }else if([tableColumn.identifier isEqualToString:@"Filter"]){
            textfiled.stringValue = [rulesList filterAtIndex:(NSUInteger)row];
            textfiled.identifier = @"Filter";
        }else if([tableColumn.identifier isEqualToString:@"Note"]){
            textfiled.stringValue = [rulesList noteAtIndex:(NSUInteger)row];
            textfiled.identifier = @"Note";
        }
        textfiled.delegate = self;
        textfiled.tag = row;
        result = textfiled;
    }else if([tableColumn.identifier isEqualToString:@"Action"]){
        // "Action"
        // No only shortcut action support

        SRRecorderControl *recordView = [[SRRecorderControlWithTagid alloc] init];

        recordView.delegate = self;
        [recordView setAllowedModifierFlags:SRCocoaModifierFlagsMask requiredModifierFlags:0 allowsEmptyModifierFlags:YES];
                ((SRRecorderControlWithTagid *)recordView).tagid = row;
        recordView.objectValue = @{
                @"keyCode": @([rulesList shortcutKeycodeAtIndex:row]),
                @"modifierFlags": @([rulesList shortcutFlagAtIndex:row]),
        };
        result = recordView;
    }else if([tableColumn.identifier isEqualToString:@"AppPicker"]){
        // Pick button
        NSButton* btnView = [[NSButton alloc] init];
        [btnView setButtonType:NSPushOnPushOffButton];
        btnView.title = @"Pick";
        btnView.tag = row;
        [btnView setTarget:self];
        [btnView setAction:@selector(pickBtnDidClick:)];
        btnView.bezelStyle = NSRoundedBezelStyle;
        result = btnView;
    }



    return result;
}


- (IBAction)autoStartAction:(id)sender {
    switch (self.autoStartAtLogin.state) {
        case NSOnState:     [[NSBundle mainBundle] addToLoginItems]; break;
        case NSOffState:    [[NSBundle mainBundle] removeFromLoginItems]; break;
    }
}


@end
