//
//  ReplicappAppDelegate.h
//  Replicapp
//
//  Created by Alex Winston on 7/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "RCCursorView.h"
#import "RCHighlightWindow.h"
#import "RCHighlightView.h"

@interface ReplicappAppDelegate : NSObject <NSApplicationDelegate, NSUserNotificationCenterDelegate> {
    IBOutlet RCHighlightWindow *selectionHighlightWindow;
    IBOutlet RCHighlightView *selectionHighlightView;
    
    IBOutlet NSWindow *cursorPositionWindow;
    IBOutlet RCCursorView *cursorPositionView;
    
    NSStatusItem *statusBar;
    NSPopUpButton *statusWindowPopUpButton;
}

@end
