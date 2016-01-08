//
//  RCHighlightView.h
//  Replicapp
//
//  Created by Alex Winston on 7/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "RCCursorView.h"
#import "RCHighlightWindow.h"

@interface RCHighlightView : NSView {
    IBOutlet RCHighlightWindow *selectionHighlightWindow;
    
    IBOutlet NSWindow *cursorPositionWindow;
    IBOutlet RCCursorView *cursorPositionView;
    
    NSRect highlightRect;
    CGRect flippedHighlightRect;
}
- (void)enable;
- (void)disable;
@end
