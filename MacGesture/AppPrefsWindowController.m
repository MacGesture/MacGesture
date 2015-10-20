//
//  AppPrefsWindowController.m
//


#import "AppPrefsWindowController.h"
#import "AppDelegate.h"
#import "RulesList.h"
#import "SRRecorderControl.h"
#import "SRRecorderControlWithTagid.h"
#import "AppPickerWindowController.h"

@implementation AppPrefsWindowController

@synthesize rulesTableView = _rulesTableView;

- (void)windowDidLoad {
    [super windowDidLoad];
    [self.openPreOnStartup bind:NSValueBinding toObject:[NSUserDefaults standardUserDefaults]  withKeyPath:@"openPrefOnStartup" options:nil];
    [self.blockFilter bind:NSValueBinding toObject:[NSUserDefaults standardUserDefaults]  withKeyPath:@"blockFilter" options:nil];
    [self.showGesturePreview bind:NSValueBinding toObject:[NSUserDefaults standardUserDefaults]  withKeyPath:@"showGesturePreview" options:nil];
    [self.autoCheckUpdate bind:NSValueBinding toObject:self.updater withKeyPath:@"automaticallyChecksForUpdates" options:nil];
    [self.autoDownUpdate bind:NSValueBinding toObject:self.updater withKeyPath:@"automaticallyDownloadsUpdates" options:nil];

}

- (IBAction)addRule:(id)sender {
    [[RulesList sharedRulesList] addRuleWithDirection:@"DR" filter:@"*safari|*chrome" filterType:FILETER_TYPE_WILD actionType:ACTION_TYPE_SHORTCUT shortcutKeyCode:0 shortcutFlag:0 appleScript:nil];
    [_rulesTableView reloadData];
}

- (IBAction)removeRule:(id)sender {
    [[RulesList sharedRulesList] removeRuleAtIndex:_rulesTableView.selectedRow];
    [_rulesTableView reloadData];
}
- (IBAction)resetRules:(id)sender {
    [[RulesList sharedRulesList] reInit];
    [[RulesList sharedRulesList] save];
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
    }
    [[RulesList sharedRulesList] save];
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
    }else{
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
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
    if([tableColumn.identifier isEqualToString:@"Gesture"] || [tableColumn.identifier isEqualToString:@"Filter"]){
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
        NSButton* btnView = [[NSButton alloc] init];
        [btnView setButtonType:NSPushOnPushOffButton];
        btnView.title = @"Pick";
        btnView.tag = row;
        [btnView setTarget:self];
        [btnView setAction:@selector(pickBtnDidClick:)];
        result = btnView;
    }



    return result;
}

@end
