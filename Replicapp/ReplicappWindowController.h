//
//  ReplicappWindowController.h
//  Replicapp
//
//  Created by Alex Winston on 8/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "INPopoverController.h"


@interface ReplicappWindowController : NSWindowController {
    NSInteger windowLevel;
    IBOutlet NSImageView *windowImageView;
    IBOutlet NSTextField *windowWarningTextField;
    
    IBOutlet NSView *titlebarButtonsView;
    IBOutlet NSView *settingsTitlebarView;
    INPopoverController *settingsTitlebarPopoverController;
    
    IBOutlet NSSlider *refreshSlider;
    
    IBOutlet NSButton *hasChangedNotificationButton;
    IBOutlet NSTextField *hasChangedNotificationTextField;
    IBOutlet NSSlider *hasChangedNotificationSlider;
    
    IBOutlet NSButton *noChangesNotificationButton;
    IBOutlet NSTextField *noChangesNotificationTextField;
    IBOutlet NSSlider *noChangesNotificationSlider;
    
    CGWindowID replicappWindowId;
    CGWindowID replicappWindowOwnerId;
    NSString *replicappWindowName;
    NSString *replicappWindowOwnerName;
    CGRect replicappRect;
    NSTimer *replicappTimer;
    
    NSBitmapImageRep *previousImageRep;
    NSDate *previousHasChangedDate;
    NSDate *previousNoChangesDate;
}
- (id)initWithWindowNibName:(NSString *)nibNameOrNil
                 windowInfo:(NSDictionary *)windowInfo
              highlightRect:(CGRect)highlightRect
        highlightScreenRect:(NSRect)highlightScreenRect;
- (void)replicappWindowImage;
- (IBAction)anchorTitlebarButtonClicked:(id)sender;
- (IBAction)settingsTitlebarButtonClicked:(id)sender;
- (IBAction)refreshSliderChanged:(id)sender;
- (IBAction)hasChangedButtonClicked:(id)sender;
- (IBAction)hasChangedSliderChanged:(id)sender;
- (IBAction)noChangesSliderChanged:(id)sender;
- (IBAction)noChangesButtonClicked:(id)sender;
@end
