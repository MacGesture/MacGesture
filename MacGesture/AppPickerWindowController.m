//
//  AppPickerWindowController.m
//  
//
//  Created by codefalling on 15/10/20.
//
//

#import "AppPickerWindowController.h"
#import "RulesList.h"

@interface FilterData : NSObject
{
}

@property (strong, nonatomic) NSString *text;
@property (strong, nonatomic) NSImage *icon;
@property NSInteger checkedState;

@end

@implementation FilterData

-(instancetype)initFilterData:(NSString*)text icon:(NSImage*)icon checkedState:(NSInteger) checkedState
{
    self = [super init];
    
    self.text = text;
    self.icon = icon;
    self.checkedState = checkedState;
    
    return self;
}

@end

@interface AppPickerWindowController ()

@end

@implementation AppPickerWindowController

NSMutableArray *_filters;
NSMutableArray *_checkBoxs;
NSMutableString *_filter;

- (instancetype)initWithWindowNibName:(NSString *)windowNibName {
    self = [super initWithWindowNibName:windowNibName];
    _filters = [[NSMutableArray alloc] init];
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
                FilterData * filter = [[FilterData alloc] initFilterData:app.bundleIdentifier icon:(app.icon ? app.icon : emptyIcon) checkedState:NSOffState];
                [_filters addObject:filter];
            }
        }
    }
    
    NSString *originalFilter = [[RulesList sharedRulesList] filterAtIndex:self.indexForParentWindow];
    NSArray *filters = [originalFilter componentsSeparatedByString:@"|"];
    for (NSString *filter in filters) {
        if ([filter length]) {
            NSUInteger index = [_filters indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                return [obj text] == filter;
            }];
            if (index == NSNotFound) {
                [_filters addObject:[[FilterData alloc] initFilterData:filter icon:emptyIcon checkedState:NSOffState]];
            } else {
                [_filters[index] setCheckedState:NSOnState];
            }
        }
    }
    [self.filtersTableView reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_filters count];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 20;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSView *result;
    if([tableColumn.identifier isEqualToString:@"CheckBox"]){
        NSButton *checkbox = [[NSButton alloc] init];
        [checkbox setButtonType:NSSwitchButton];
        checkbox.state = [_filters[row] checkedState];
        [checkbox setTitle:@""];
        checkbox.tag = row;
        [_checkBoxs addObject:checkbox];
        result = checkbox;

    }else if([tableColumn.identifier isEqualToString:@"Icon"]){
        NSImageView *imageView = [[NSImageView alloc] init];
        imageView.image = [_filters[row] icon];
        return imageView;
    }else{
        NSTextField *textField = [[NSTextField alloc] init];
        textField.bezeled = NO;
        textField.stringValue = [_filters[row] text];
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
    for (NSButton *btn in _checkBoxs) {
        if ([btn state] == NSOnState) { // YES
//            [_filter appendString:((NSRunningApplication *)(_runningApps[btn.tag])).bundleIdentifier];
//            [_filter appendString:@"|"];
            if (self.addedToTextView) {
                self.addedToTextView.string=[NSString stringWithFormat:@"%@\n%@",self.addedToTextView.string,[_filters[btn.tag] text]];
            } else {
                [_filter appendString:[_filters[btn.tag] text]];
                [_filter appendString:@"|"];
                if (self.parentWindow) {
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
