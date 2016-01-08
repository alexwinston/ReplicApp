//
//  RCHighlightWindow.m
//  Replicapp
//
//  Created by Alex Winston on 7/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RCHighlightWindow.h"


@implementation RCHighlightWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned long)styleMask backing:(NSBackingStoreType)backingType defer:(BOOL)flag
{
	return [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:backingType defer:flag];
}

- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned long)styleMask backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag screen:(NSScreen *)aScreen
{
	return [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:bufferingType defer:flag screen:aScreen];
}

//- (NSRect)constrainFrameRect:(NSRect)frameRect toScreen:(NSScreen *)aScreen
//{
//	return [aScreen frame];
//}

- (BOOL) acceptsMouseMovedEvents
{
    return YES;
}

- (BOOL) canBecomeKeyWindow
{
    return YES;
}

- (NSPoint)displayPointForScreenPoint:(NSPoint)screenPt
{
    NSPoint result = [self convertScreenToBase:screenPt];
    result.y = [self frame].size.height - result.y;
    
    return result;
}

@end
