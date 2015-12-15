//
//  AppPickerWindowController.h
//  
//
//  Created by codefalling on 15/10/20.
//
//

#import <Cocoa/Cocoa.h>

@interface AppPickerWindowController : NSWindowController<NSTableViewDelegate, NSTableViewDataSource>
- (NSString *)generateFilter;
- (void)showDialog;
@property (nonatomic, strong)NSTextView *addedToTextView;
@end
