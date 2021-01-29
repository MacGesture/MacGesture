//
//  AppPickerWindowController.h
//  
//
//  Created by codefalling on 15/10/20.
//
//

#import <Cocoa/Cocoa.h>

@protocol AppPickerCallback;

@interface AppPickerWindowController : NSWindowController <NSTableViewDelegate, NSTableViewDataSource>
- (NSString *)generateFilter;

- (void)showDialog;

@property(nonatomic, strong) NSTextView *addedToTextView;
@property(nonatomic, strong) NSWindowController <AppPickerCallback> *parentWindow;
@property(nonatomic, strong) IBOutlet NSTableView *filtersTableView;
@property(nonatomic, assign) NSUInteger indexForParentWindow;
@property(nonatomic, strong) IBOutlet NSTextField *loadingLabel;

@end

@protocol AppPickerCallback
- (void)rulePickCallback:(NSString *)rulesStringSplitedByStick atIndex:(NSInteger)index;

@end
