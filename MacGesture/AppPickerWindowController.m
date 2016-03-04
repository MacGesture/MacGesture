//
//  AppPickerWindowController.m
//  
//
//  Created by codefalling on 15/10/20.
//
//

#import "AppPickerWindowController.h"
#import "RulesList.h"

@interface AppPickerWindowController ()

@end

@implementation AppPickerWindowController

NSMutableArray *_filtersText;
NSMutableArray *_filtersIcon;
NSMutableArray *_filtersChecked;
NSMutableArray *_checkBoxs;
NSMutableString *_filter;

- (instancetype)initWithWindowNibName:(NSString *)windowNibName {
    self = [super initWithWindowNibName:windowNibName];
    _filtersText = [[NSMutableArray alloc] init];
    _filtersIcon = [[NSMutableArray alloc] init];
    _filtersChecked = [[NSMutableArray alloc] init];
    _checkBoxs = [[NSMutableArray alloc] init];
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
    
    NSImage* emptyIcon = [[NSImage alloc] initWithSize:NSMakeSize(64,64)];

    for(NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications]){
        if(app.activationPolicy == NSApplicationActivationPolicyRegular) {
            if (app.bundleIdentifier) {
                [_filtersText addObject:app.bundleIdentifier];

                if (app.icon) {
                    [_filtersIcon addObject:app.icon];
                } else {
                    [_filtersIcon addObject:emptyIcon];
                }

                [_filtersChecked addObject:@(NSOffState)];
            }
        }
    }
    
    NSString *originalFilter = [[RulesList sharedRulesList] filterAtIndex:self.indexForParentWindow];
    NSArray *filters = [originalFilter componentsSeparatedByString:@"|"];
    for (NSString *filter in filters) {
        if ([filter length]) {
            NSUInteger index = [_filtersText indexOfObject:filter];
            if (index == NSNotFound) {
                [_filtersText addObject:filter];
                [_filtersIcon addObject:emptyIcon];
                [_filtersChecked addObject:@(NSOnState)];
            } else {
                _filtersChecked[index] = @(NSOnState);
            }
        }
    }
    [self.filtersTableView reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_filtersText count];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 20;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSView *result;
    if([tableColumn.identifier isEqualToString:@"CheckBox"]){
        NSButton *checkbox = [[NSButton alloc] init];
        [checkbox setButtonType:NSSwitchButton];
        checkbox.state = [_filtersChecked[row] intValue];
        [checkbox setTitle:@""];
        checkbox.tag = row;
        [_checkBoxs addObject:checkbox];
        result = checkbox;

    }else if([tableColumn.identifier isEqualToString:@"Icon"]){
        NSImageView *imageView = [[NSImageView alloc] init];
        imageView.image = _filtersIcon[row];
        return imageView;
    }else{
        NSTextField *textField = [[NSTextField alloc] init];
        textField.bezeled = NO;
        textField.stringValue = _filtersText[row];
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
//            [_filter appendString:((NSRunningApplication *)(_runningApps[btn.tag])).bundleIdentifier];
//            [_filter appendString:@"|"];
            if(self.addedToTextView){
                self.addedToTextView.string=[NSString stringWithFormat:@"%@\n%@",self.addedToTextView.string,_filtersText[btn.tag]];
            }else{
                [_filter appendString:_filtersText[btn.tag]];
                [_filter appendString:@"|"];
                if(self.parentWindow){
                    [self.parentWindow rulePickCallback:_filter atIndex:self.indexForParentWindow];
                }
            }
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
