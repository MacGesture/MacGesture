//
//  AppPrefsWindowController.h
//

#import <Cocoa/Cocoa.h>
#import "DBPrefsWindowController.h"
#import "SRRecorderControl.h"


@interface AppPrefsWindowController : DBPrefsWindowController<NSTableViewDelegate, NSTableViewDataSource, SRRecorderControlDelegate, NSTextFieldDelegate>

@property (strong, nonatomic) IBOutlet NSView *generalPreferenceView;
@property (strong, nonatomic) IBOutlet NSView *rulesPreferenceView;
@property (strong, nonatomic) IBOutlet NSView *playbackPreferenceView;
@property (strong, nonatomic) IBOutlet NSView *updatesPreferenceView;
@property (strong, nonatomic) IBOutlet NSView *aboutPreferenceView;

@property (weak) IBOutlet NSTableView *rulesTableView;

@property (weak) IBOutlet NSButton *openPreOnStartup;
@property (weak) IBOutlet NSTextField *blockFilter;

@property (weak) IBOutlet NSButton *showGesturePreview;

@end
