//
//  RCHighlightView.m
//  Replicapp
//
//  Created by Alex Winston on 7/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RCHighlightView.h"
#import "ReplicappWindowController.h"

#define KEYCODE_ESC 53
#define KEYCODE_RETURN 36
#define KEYCODE_SPACE 49
#define KEYCODE_DEL 117
#define KEYCODE_BS 51

@implementation RCHighlightView

+ (NSCursor *)resizeDownRightCursor {
    static NSCursor *resizeRightDownCursor = nil;
    if (nil == resizeRightDownCursor) {
        NSImage *cursorImage = [[[NSImage imageNamed:@"RCResizeDownRightCursor"] copy] autorelease];
        resizeRightDownCursor = [[NSCursor alloc] initWithImage:cursorImage hotSpot:NSMakePoint(8.0, 8.0)];
    }
    return resizeRightDownCursor;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)resetCursorRects
{
//    NSLog(@"resetCursorRects");
    [self addCursorRect:[self bounds] cursor:[NSCursor crosshairCursor]];
}

- (void)mouseMoved:(NSEvent *)event
{
    [cursorPositionView updateCursorPosition:[[self window] convertBaseToScreen:[event locationInWindow]]];
}

- (void)mouseDown:(NSEvent *)event
{
    NSLog(@"mouseDown");
    // Set the resize cursor
    [[RCHighlightView resizeDownRightCursor] set];
    
	highlightRect.origin = [event locationInWindow];
    
    CGEventRef cgEvent = CGEventCreate(NULL);
    flippedHighlightRect.origin = CGEventGetLocation(cgEvent);
    
    // http://stackoverflow.com/questions/21949021/getting-mouse-in-retina-coordinates?rq=1
    for (NSScreen *screen in [NSScreen screens]) {
        if (NSMouseInRect([event locationInWindow], [screen frame], NO)) {
            NSLog(@"convertRectToBacking");
            NSRect rect = [self convertRectToBacking:NSMakeRect(flippedHighlightRect.origin.x, flippedHighlightRect.origin.y, 1, 1)];
            flippedHighlightRect.origin.x = rect.origin.x;
            flippedHighlightRect.origin.y = rect.origin.y;
        }
    }
    
    CFRelease(cgEvent);
}

- (void)mouseDragged:(NSEvent *)event
{
    NSPoint currentPoint = [event locationInWindow];
    highlightRect.size = CGSizeMake(currentPoint.x - highlightRect.origin.x,
                                    currentPoint.y - highlightRect.origin.y);
    
    CGEventRef cgEvent = CGEventCreate(NULL);
    CGPoint flippedCurrentPoint = CGEventGetLocation(cgEvent);
    for (NSScreen *screen in [NSScreen screens]) {
        if (NSMouseInRect([event locationInWindow], [screen frame], NO)) {
            NSLog(@"convertPointToBacking");
            flippedCurrentPoint = [self convertPointToBacking:flippedCurrentPoint];
        }
    }
    flippedHighlightRect.size = CGSizeMake(flippedCurrentPoint.x - flippedHighlightRect.origin.x,
                                           flippedCurrentPoint.y - flippedHighlightRect.origin.y);
    
    CFRelease(cgEvent);
    
    [cursorPositionView updateCursorPosition:currentPoint
                                 withDisplay:[selectionHighlightWindow displayPointForScreenPoint:currentPoint]];
    
    [self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)event
{    
    CGEventRef mouseEvent = CGEventCreate(NULL);
    CGPoint mousePoint = CGEventGetLocation(mouseEvent);
    
    CFArrayRef windowArray = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID);
	for (NSDictionary *windowDictionary in (NSArray *)windowArray) {
        CGRect bounds;
		CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)[windowDictionary objectForKey:(id)kCGWindowBounds], &bounds);

        NSString *windowOwnerName = [windowDictionary objectForKey:(id)kCGWindowOwnerName];
        if (![windowOwnerName isEqualToString:@"Replicapp"] && CGRectContainsPoint(bounds, mousePoint)) {
            @try {
                // Controller is dealloced on windowWillClose
                ReplicappWindowController *replicappWindowController = [[ReplicappWindowController alloc] initWithWindowNibName:@"ReplicappWindow"
                                                                                                                     windowInfo:windowDictionary
                                                                                                                  highlightRect:flippedHighlightRect
                                                                                                            highlightScreenRect:highlightRect];
                
                NSWindow *replicappWindow = [replicappWindowController window]; 
                [replicappWindow makeKeyAndOrderFront:self];
            } @catch (NSException *e) {
                // Ignore, play warning sound
                [[NSSound soundNamed:@"Funk"] play];
                NSLog(@"mouseUp: NSException");
            }
            
            break;
        }
    }
    CFRelease(windowArray);
    CFRelease(mouseEvent);
    
    [self disable];
}

- (void)keyUp:(NSEvent *)event
{
    switch ([event keyCode]) {
        case KEYCODE_ESC:
            NSLog(@"postCaptureDidCancelNotification");
            [self disable];
            break;
        case KEYCODE_RETURN:
        case KEYCODE_SPACE:
            NSLog(@"postCaptureDidEndNotification");
            break;
        case KEYCODE_DEL:
        case KEYCODE_BS:
//            if (self.captureSession.highlightedFocusArea != nil) {
//                [self poofAndRemoveFocusArea:self.captureSession.highlightedFocusArea];
//                self.captureSession.highlightedFocusArea = nil;
//            }
            break;
        default:
            break;
    }
}

- (void)drawRect:(NSRect)rect {
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [[[NSColor blackColor] colorWithAlphaComponent:0.25] set];
    
    NSBezierPath *highlightBezier = [NSBezierPath bezierPathWithRect:highlightRect];
    [highlightBezier fill];
    
    CGFloat lineDash[] = { 6.0, 3.0, 2.0, 3.0 };
    [[NSColor whiteColor] set];
    [highlightBezier setLineWidth:1.0];
    [highlightBezier setLineDash:lineDash count:4 phase:0.0];
    
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform translateXBy: 0.5 yBy: 0.5];
    
    [highlightBezier transformUsingAffineTransform: transform];
    [highlightBezier stroke];
    
    [[NSGraphicsContext currentContext] restoreGraphicsState];
}

- (void)enable
{
    NSRect screenFrame = NSZeroRect;
    BOOL first = YES;
    
    for (NSScreen *screen in [NSScreen screens]) {
        if (first) {
            screenFrame = [screen frame];
            first = NO;
        } else {
            screenFrame = NSUnionRect(screenFrame, [screen frame]);
        }
    }
    
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    
    [selectionHighlightWindow setFrame:screenFrame display:YES];
	[selectionHighlightWindow setLevel:NSFloatingWindowLevel];
    [[selectionHighlightWindow contentView] setNeedsDisplay:YES];
	[selectionHighlightWindow makeKeyAndOrderFront:self];
    [selectionHighlightWindow makeFirstResponder:self];
    [selectionHighlightWindow setBackgroundColor:[NSColor clearColor]];
    
    [cursorPositionView updateCursorPosition:[NSEvent mouseLocation]];
    
    [cursorPositionWindow setLevel:NSFloatingWindowLevel];
    [cursorPositionWindow orderFront:self];
}
- (void)disable
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RCHighlightDisabledNotification" 
                                                        object:self];
    
    // Reset the highlight rect
    highlightRect = NSMakeRect(0, 0, 0, 0);
    flippedHighlightRect = CGRectMake(0, 0, 0, 0);
    
    [selectionHighlightWindow setIsVisible:NO];
    [selectionHighlightWindow orderOut:self];
    [cursorPositionWindow orderOut:self];
    
    [self setNeedsDisplay:YES];
}

@end
