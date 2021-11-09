//
//  AppPickerWindowController.h
//  
//
//  Created by codefalling on 15/10/20.
//
//

#import <Cocoa/Cocoa.h>

@protocol AppPickerCallback

@required
- (void)rulePickCallback:(NSString *)rulesStringSplitedByStick atIndex:(NSInteger)index;

@end

@interface AppPickerWindowController : NSWindowController

@property(nonatomic, weak) NSWindowController<AppPickerCallback> *parentWindow;
@property(nonatomic, assign) NSUInteger indexForParentWindow;

@property(nonatomic, strong) IBOutlet NSTableView *filtersTableView;
@property(nonatomic, strong) IBOutlet NSTextField *loadingLabel;
@property(nonatomic, strong) NSTextView *addedToTextView;

- (NSString *)generateFilter;
- (void)showDialog;

@end
