//
//  RCCursorView.h
//  Replicapp
//
//  Created by Alex Winston on 7/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RCCursorView : NSView {
    IBOutlet NSWindow *cursorPositionWindow;
    IBOutlet NSTextField *cursorPositionTextField;
}
- (void)updateCursorPosition:(NSPoint)pt;
- (void)updateCursorPosition:(NSPoint)pt withDisplay:(NSPoint)visiblePt;
@end
