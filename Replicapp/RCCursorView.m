//
//  RCCursorView.m
//  Replicapp
//
//  Created by Alex Winston on 7/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RCCursorView.h"


@implementation RCCursorView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:[self bounds] xRadius:3 yRadius:3];
    [path addClip];
    
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.55] set];
    NSRectFill(dirtyRect);
    
    [super drawRect:dirtyRect]; 
}

- (void)updateCursorPositionFrameOrigin:(NSPoint)pt
{
    // Offset from cursor hotspot
    pt.x += 4.0;
    pt.y += -20.0;
    
    [cursorPositionWindow setFrameOrigin:pt];  
}

- (void)updateCursorPosition:(NSPoint)pt
{
    [cursorPositionTextField setStringValue:@"Replicapp"];
    
    [self updateCursorPositionFrameOrigin:pt];
}

- (void)updateCursorPosition:(NSPoint)pt withDisplay:(NSPoint)visiblePt
{
    NSNumberFormatter *cursorPositionFormatter = [[[NSNumberFormatter alloc] init] autorelease];
    [cursorPositionFormatter setFormat:@"#,###"];
    
    NSString *xValue = [cursorPositionFormatter stringFromNumber:[NSNumber numberWithInt:(int)visiblePt.x]];
    NSString *yValue = [cursorPositionFormatter stringFromNumber:[NSNumber numberWithInt:(int)visiblePt.y]];
    
    [cursorPositionTextField setStringValue:[NSString stringWithFormat:@"%@ x %@", xValue, yValue]];
    
    [self updateCursorPositionFrameOrigin:pt];
}

@end
