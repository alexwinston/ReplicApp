//
//  RCImageView.m
//  Replicapp
//
//  Created by Alex Winston on 8/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RCImageView.h"


@implementation RCImageView

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    mouseDownPoint = [theEvent locationInWindow];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    NSPoint currentMousePoint = [NSEvent mouseLocation];
    
    [replicappWindow setFrameOrigin:NSMakePoint(currentMousePoint.x - mouseDownPoint.x,
                                                currentMousePoint.y - mouseDownPoint.y)];
}

- (void)drawRect:(NSRect)frame
{
    [super drawRect:frame];
}

@end
