//
//  AppPickerWindowController.m
//  
//
//  Created by codefalling on 15/10/20.
//
//

#import "AppPickerWindowController.h"
#import "RulesList.h"
#import "utils.h"

#pragma mark - Filter data -

@interface FilterData : NSObject

@property (atomic) NSInteger checkedState;
@property (strong) NSImage *icon;
@property (copy) NSString *text;

@end

@implementation FilterData

- (instancetype)initWithText:(NSString *)text icon:(NSImage *)icon checkedState:(NSInteger)checkedState {

    if (self = [super init]) {
        _checkedState = checkedState;
        _icon = icon;
        _text = text;
    }
    
    return self;
}

@end

#pragma mark - Picker window controller -

@interface AppPickerWindowController () <NSTableViewDelegate, NSTableViewDataSource>

@end

@implementation AppPickerWindowController

NSMutableString *_filter;
NSMutableArray<FilterData *> *_filters;
NSMutableArray<NSButton *> *_checkBoxes;

- (instancetype)initWithWindowNibName:(NSString *)windowNibName {

    if (self = [super initWithWindowNibName:windowNibName]) {
        _filters = [NSMutableArray arrayWithCapacity:10];
        _checkBoxes = [NSMutableArray arrayWithCapacity:10];
    }

    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{

        for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications]) {
            // Must be a regular app...
            if (app.activationPolicy != NSApplicationActivationPolicyRegular) continue;
            // ...with a valid Bundle ID
            if (!app.bundleIdentifier) continue;
            [_filters addObject:[[FilterData alloc] initWithText:app.bundleIdentifier
                icon:[self getImageForApp:app.bundleIdentifier icon:app.icon]
                checkedState:NSControlStateValueOff]
            ];
        }
        
        if (!self.addedToTextView) {

            dispatch_async(dispatch_get_main_queue(), ^{
                [self.filtersTableView reloadData];
                [self.loadingLabel setStringValue:NSLocalizedString(@"Loading…", nil)];
            });

            NSString *originalFilter = [[RulesList sharedRulesList] filterAtIndex:self.indexForParentWindow];
            NSArray<NSString *> *filters = [originalFilter componentsSeparatedByString:@"|"];
            for (NSString *filter in filters) {
                if (!filter.length) continue;
                NSUInteger index = [_filters indexOfObjectPassingTest:
                  ^BOOL(FilterData *obj, NSUInteger idx, BOOL *stop) {
                    return obj.text == filter;
                }];
                if (index == NSNotFound) {
                    [_filters addObject:[[FilterData alloc] initWithText:filter
                        icon:[self getImageForApp:filter]
                        checkedState:NSControlStateValueOn]
                    ];
                } else {
                    _filters[index].checkedState = NSControlStateValueOn;
                }
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.filtersTableView reloadData];
            [self.loadingLabel setHidden:YES];
        });

    });
}

#pragma mark - Helpers

- (NSString *)generateFilter {
    return [_filter copy];
}

- (NSImage *)getImageForApp:(NSString *)bundleIdentifier icon:(NSImage *)icon {
    static NSImage *emptyIcon;
    if (!emptyIcon) emptyIcon = [[NSImage alloc] initWithSize:NSMakeSize(16, 16)];
    return icon ?: emptyIcon;
}

- (NSImage *)getImageForApp:(NSString *)bundleIdentifier {
    return [self getImageForApp:bundleIdentifier icon:nil];
}

#pragma mark - Table view delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _filters.count;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 20;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)column row:(NSInteger)row {

    if ([column.identifier isEqualToString:@"CheckBox"]) {
        NSButton *checkBox = [NSButton new];
        [checkBox setButtonType:NSSwitchButton];
        checkBox.state = _filters[row].checkedState;
        checkBox.title = @"";
        checkBox.tag = row;
        [_checkBoxes addObject:checkBox];
        return checkBox;
    } else if ([column.identifier isEqualToString:@"Icon"]) {
        NSImageView *imageView = [NSImageView new];
        imageView.image = _filters[row].icon;
        return imageView;
    } else {
        NSTextField *textField = [NSTextField new];
        textField.bezeled = NO;
        textField.editable = NO;
        textField.drawsBackground = NO;
        textField.stringValue = _filters[row].text;
        return textField;
    }
}

#pragma mark - Actions

- (void)showDialog {
//    NSWindow *window = self.window;
//    [NSApp runModalForWindow:window];
//    [NSApp endSheet:window];
//    [window orderOut:self];    // show dialog
}

- (IBAction)okBtnDidClick:(id)sender {

    // Generate filter
    _filter = [NSMutableString stringWithCapacity:32];

    NSWindowController<AppPickerCallback> *targetWindow = self.parentWindow;
    NSTextView *targetTextView = self.addedToTextView;

    for (NSButton *btn in _checkBoxes) {
        if (btn.state != NSControlStateValueOn) continue;
        if (targetTextView) {
            NSMutableString *list = targetTextView.string.mutableCopy;
            if (list.length) [list appendString:@"\n"];
            [list appendString:_filters[btn.tag].text];
            targetTextView.string = list.copy;
        } else {
            [_filter appendString:_filters[btn.tag].text];
            [_filter appendString:@"|"];
        }
    }
    
    if (!targetTextView && targetWindow) {
        _filter = [[[_filter componentsSeparatedByString:@"|"]
            mappedArrayUsingBlock:^NSString *(NSString *obj, NSUInteger idx) {
                return obj.length > 0 ? obj : nil;
            }] componentsJoinedByString:@"|"].mutableCopy;
        [targetWindow rulePickCallback:_filter atIndex:_indexForParentWindow];
    }

//    [NSApp stopModal];
    [self close];
}

- (IBAction)cancelBtnDidClick:(id)sender {
//    [NSApp stopModal];
    [self close];
}

@end
