//
//  AppPickerWindowController.m
//  
//
//  Created by codefalling on 15/10/20.
//
//

#import "AppPickerWindowController.h"

@interface AppPickerWindowController ()

@end

@implementation AppPickerWindowController

NSMutableArray *_runningApps;
NSMutableArray *_checkBoxs;
NSMutableString *_filter;

- (instancetype)initWithWindowNibName:(NSString *)windowNibName {
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        _runningApps = [[NSMutableArray alloc] init];
        _checkBoxs = [[NSMutableArray alloc] init];
        for(NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications]){
            if(app.activationPolicy == NSApplicationActivationPolicyRegular) {
                [_runningApps addObject:app];
            }
        }
    }

    return self;
}

- (NSString *)generateFilter {
    if(_filter){
        return _filter;
    }
    return nil;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_runningApps count];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 20;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSView *result;
    if([tableColumn.identifier isEqualToString:@"CheckBox"]){
        NSButton *checkbox = [[NSButton alloc] init];
        [checkbox setButtonType:NSSwitchButton];
        checkbox.state = NSOffState;
        [checkbox setTitle:@""];
        checkbox.tag = row;
        [_checkBoxs addObject:checkbox];
        result = checkbox;

    }else if([tableColumn.identifier isEqualToString:@"Icon"]){
        NSImageView *imageView = [[NSImageView alloc] init];
        imageView.image = ((NSRunningApplication *)(_runningApps[row])).icon;
        return imageView;
    }else{
        NSTextField *textField = [[NSTextField alloc] init];
        textField.bezeled = NO;
        textField.stringValue = ((NSRunningApplication *)(_runningApps[row])).bundleIdentifier;
        result = textField;
    }

    return result;
}

- (void)showDialog {
//    NSWindow *win = [self window];
//    [NSApp runModalForWindow:win];
//    [NSApp endSheet:win];
//    [win orderOut:self];    // show dialog
}

- (IBAction)okBtnDidClick:(id)sender {
    // generate filter
    _filter = [[NSMutableString alloc] initWithString:@""];
    for(NSButton *btn in _checkBoxs){
        if([btn state] == NSOnState){ // YES
            [_filter appendString:((NSRunningApplication *)(_runningApps[btn.tag])).bundleIdentifier];
            [_filter appendString:@"|"];

        }
    }

//    [NSApp stopModal];
    [self close];
}

- (IBAction)concalBtnDidClick:(id)sender {
//    [NSApp stopModal];
    [self close];
}

@end
