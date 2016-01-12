//
//  ReplicappWindowController.m
//  Replicapp
//
//  Created by Alex Winston on 8/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#include <Quartz/Quartz.h>

#import "ReplicappWindowController.h"

#define kCGImageMinimumValidWidth 1

#define kNSButtonStatusOff 0
#define kNSButtonStatusOn 1

#define kRCNotificationMinimumSecondsInterval 5
#define kRCImageDifferenceScaledWidth 50
#define kRCImageDifferenceScaledHeight 50
#define kRCImageDifferencePixels (kRCImageDifferenceScaledWidth * kRCImageDifferenceScaledHeight)
#define kRCWindowFrameMinWidth 115
#define kRCWindowFrameMinHeight 35
#define kRCWindowFramePopupOffset 5

static const float kRCRefreshRates[7] = { .1, .2, .5, 1, 5, 15, 60 };
static const float kRCHasChangedPercentage[5] = { 0.0, 0.15, 0.40, 0.65, (kRCImageDifferencePixels - 1.0) / kRCImageDifferencePixels };
static NSString *kRCHasChangedDescriptions[5] = { @"Changes any amount", @"Changes at least 25%", @"Changes at least 50%", @"Changes at least 75%", @"Changes 100%" };
static const int kRCNoChangesSeconds[5] = { 5, 15, 30, 60, 300 };
static NSString *kRCNoChangesDescriptions[5] = { @"No changes for 5 secs", @"No changes for 15 secs", @"No changes for 30 secs", @"No changes for 1 min", @"No changes for 5 mins" };


NSBitmapImageRep* CGImageCreateDifferenceWithImage(CGImageRef inputImageRef, CGImageRef inputBackgroundImageRef)
{
    NSBitmapImageRep *differenceImageRep = [[NSBitmapImageRep alloc] initWithCGImage:inputImageRef];
    
    CIImage *inputImage = [CIImage imageWithCGImage:inputImageRef];
    CIImage *inputBackgroundImage = [CIImage imageWithCGImage:inputBackgroundImageRef];
    
    CIFilter *differenceFilter = [CIFilter filterWithName:@"CIDifferenceBlendMode"];
    [differenceFilter setValue:inputImage forKey:@"inputImage"];
    [differenceFilter setValue:inputBackgroundImage forKey:@"inputBackgroundImage"];
    
    NSGraphicsContext *ctx = [NSGraphicsContext graphicsContextWithBitmapImageRep: differenceImageRep];
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext: ctx];
    
    CIImage *differenceImage = [differenceFilter valueForKey:@"outputImage"];
    [[ctx CIContext] drawImage:differenceImage atPoint:CGPointZero fromRect:[differenceImage extent]];
    
    [NSGraphicsContext restoreGraphicsState];
    
    return differenceImageRep;
}

CGImageRef CGImageCreateScaledImage(CGImageRef image, int width, int height)
{
    // Create context, keeping original image properties
    CGColorSpaceRef colorspace = CGImageGetColorSpace(image);
    CGContextRef context = CGBitmapContextCreate(NULL, width, height,
                                                 CGImageGetBitsPerComponent(image),
                                                 CGImageGetBytesPerRow(image),
                                                 colorspace,
                                                 CGImageGetAlphaInfo(image));
    if(context == NULL)
        return nil;
    
    // Draw image to context (resizing it)
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
    // Create image from context
    CGImageRef imgRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    return imgRef;
}

BOOL CGImageDataPixelIsBlack(unsigned char* imageData, NSInteger imageWidth, NSInteger x, NSInteger y)
{
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * imageWidth;
    NSUInteger byteIndex = (bytesPerRow * y) + x * bytesPerPixel;
    
//    CGFloat a   = (imageData[byteIndex] * 1.0);
    CGFloat r = (imageData[byteIndex + 1] * 1.0);
    CGFloat g  = (imageData[byteIndex + 2] * 1.0);
    CGFloat b = (imageData[byteIndex + 3] * 1.0);

    return r == 0.0 && g == 0.0 && b == 0.0;
}


@implementation ReplicappWindowController

- (id)initWithWindowNibName:(NSString *)nibNameOrNil
                 windowInfo:(NSDictionary *)windowInfo
              highlightRect:(CGRect)highlightRect
        highlightScreenRect:(NSRect)highlightScreenRect
{
    NSLog(@"initWithWindowNibName:");
    
    self = [super initWithWindowNibName:nibNameOrNil];
    if (self) {        
        // Get the window view so the controls are intialized from the NIB
        NSView *windowView = [[[self window] contentView] superview];
        
        // Initialize the default window level and text background style
        windowLevel = NSFloatingWindowLevel;
        [[windowWarningTextField cell] setBackgroundStyle:NSBackgroundStyleRaised];
        
        // Initialize the previous dates
        previousHasChangedDate = [[[NSDate date] dateByAddingTimeInterval:-kRCNotificationMinimumSecondsInterval] retain];
        previousNoChangesDate = [[NSDate date] retain];
        
        // Setup the titlebar buttons view        
        NSRect windowFrame = [windowView frame];
        NSRect contentRect;
        contentRect = [NSWindow contentRectForFrameRect:windowFrame
                                              styleMask:NSTitledWindowMask];
        
        NSRect settingsFrame = [titlebarButtonsView frame];
        settingsFrame = NSMakeRect(windowFrame.size.width - settingsFrame.size.width,
                                   windowFrame.size.height - settingsFrame.size.height,
                                   settingsFrame.size.width,
                                   settingsFrame.size.height);
        [titlebarButtonsView setFrame:settingsFrame];
        [titlebarButtonsView setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin];
        [titlebarButtonsView setAlphaValue:0.75];
        
        [windowView addSubview:titlebarButtonsView];
        
        // Initialize the settings popover controllers
        settingsTitlebarPopoverController = [[[INPopoverController alloc] initWithView:settingsTitlebarView] retain];
        settingsTitlebarPopoverController.color = [NSColor colorWithCalibratedRed:230.0/255.0 green:230.0/255.0 blue:230.0/255.0 alpha:1.0];
        settingsTitlebarPopoverController.borderColor = [NSColor blackColor];
        settingsTitlebarPopoverController.borderWidth = 0.0;
        
        // Initialize the replicapp image coordinates
        CGRect windowBounds;
        CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)[windowInfo objectForKey:(id)kCGWindowBounds],
                                               &windowBounds);
        
        for (NSScreen *screen in [NSScreen screens]) {
            NSRect rect = [screen convertRectToBacking:windowBounds];
            windowBounds.origin = rect.origin;
            windowBounds.size = rect.size;
//            windowBounds.origin = [screen convertRectToBacking:windowBounds].origin;
//            highlightRect.size.width = rect.size.width;
//            highlightRect.size.height = rect.size.height;
        }
        NSLog(@"ReplicappWindowController highlightRect %f %f", highlightRect.size.width, highlightRect.size.height);
        
        replicappRect.origin.x = highlightRect.origin.x - windowBounds.origin.x;
        replicappRect.origin.y = highlightRect.origin.y - windowBounds.origin.y;
        replicappRect.size.width = highlightRect.size.width <= windowBounds.size.width ? highlightRect.size.width : windowBounds.size.width;
        replicappRect.size.height = highlightRect.size.height <= windowBounds.size.height ? highlightRect.size.height : windowBounds.size.height;
        
        NSLog(@"ReplicappWindowController replicappRect %f %f", replicappRect.size.width, replicappRect.size.height);
        
        // Get the window id, name and replicapp the window image 
        replicappWindowId = [[windowInfo objectForKey:(id)kCGWindowNumber] unsignedIntValue];
        replicappWindowOwnerId = [[windowInfo objectForKey:(id)kCGWindowOwnerPID] unsignedIntValue];
        replicappWindowName = [[windowInfo objectForKey:(id)kCGWindowName] retain];
        replicappWindowOwnerName = [[windowInfo objectForKey:(id)kCGWindowOwnerName] retain];
        [self replicappWindowImage];
        
        // Set the window background color and opacity
        [[self window] setBackgroundColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.25]];
        [[self window] setOpaque:NO];
        
        // Set the window frame size and aspect ratio
        // http://stackoverflow.com/questions/11067066/mac-os-x-best-way-to-do-runtime-check-for-retina-display
        CGFloat imageWidth = [windowImageView image].size.width / [[self window] backingScaleFactor];
        CGFloat imageHeight = [windowImageView image].size.height / [[self window] backingScaleFactor];
        
        CGFloat titlebarHeight = (windowFrame.size.height - contentRect.size.height);
        
        // TODO Dragging outside from the left or top needs to account for offset of empty space
        CGFloat windowFrameWidth = imageWidth > kRCWindowFrameMinWidth ? imageWidth : kRCWindowFrameMinWidth;
        CGFloat windowFrameWidthOffset = imageWidth > kRCWindowFrameMinWidth ? 0 : (kRCWindowFrameMinWidth - imageWidth) / 2;
        if (highlightScreenRect.size.width < 0)
            windowFrameWidthOffset += -highlightScreenRect.size.width;
        
        CGFloat windowFrameHeight = imageHeight > kRCWindowFrameMinHeight - titlebarHeight ? imageHeight : kRCWindowFrameMinHeight - titlebarHeight;
        CGFloat windowFrameHeightOffset = imageHeight > kRCWindowFrameMinHeight - titlebarHeight ? 0 : (kRCWindowFrameMinHeight - titlebarHeight - imageHeight) / 2;
        if (highlightScreenRect.size.height > 0)
            windowFrameHeightOffset += -highlightScreenRect.size.height;
        
        [[self window] setFrame:NSMakeRect(highlightScreenRect.origin.x - windowFrameWidthOffset + kRCWindowFramePopupOffset,
                                           highlightScreenRect.origin.y - windowFrameHeightOffset + kRCWindowFramePopupOffset - imageHeight,
                                           windowFrameWidth,
                                           windowFrameHeight + titlebarHeight) display:YES];
        [[self window] setContentAspectRatio:NSMakeSize(imageWidth, imageHeight)];
        
        // Fade the window in
        [[self window] setAlphaValue:0.0];
        [[[self window] animator] setAlphaValue:1.0];
        
        // Start the image update timer
        replicappTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0
                                                           target:self
                                                         selector:@selector(replicappWindowImage)
                                                         userInfo:nil
                                                          repeats:YES] retain];
    }
    
    return self;
}

- (void)dealloc
{
    NSLog(@"dealloc");
    [settingsTitlebarPopoverController release];
    
    [replicappWindowOwnerName release];
    [replicappTimer release];
    replicappTimer = nil;
    
    if (previousImageRep != nil)
        [previousImageRep release];
    [previousHasChangedDate release];
    [previousNoChangesDate release];
    
    [super dealloc];
}

- (NSSize)windowWillResize:(NSWindow *)window toSize:(NSSize)frameSize {
    return NSMakeSize(frameSize.width > kRCWindowFrameMinWidth ? frameSize.width : kRCWindowFrameMinWidth,
                      frameSize.height > kRCWindowFrameMinHeight ? frameSize.height : kRCWindowFrameMinHeight);
}

- (void)windowDidResignMain:(NSNotification *)notification
{
//    NSLog(@"windowDidResignMain:");
    [[self window] setLevel:windowLevel];
}

- (void)windowWillClose:(NSNotification *)notification
{
    NSLog(@"windowWillClose:");
    [replicappTimer invalidate];
    
    [self autorelease];
}

- (NSSize)scaledImageSize
{
    NSSize scaledImageSize = replicappRect.size;
    if (scaledImageSize.width >= kRCImageDifferenceScaledWidth)
        scaledImageSize.width = kRCImageDifferenceScaledWidth;
    if (scaledImageSize.height >= kRCImageDifferenceScaledHeight)
        scaledImageSize.height = kRCImageDifferenceScaledHeight;
    
    return scaledImageSize;
}

- (void)setWindowDifferenceImage:(CGImageRef)cgImage
{
    NSSize scaledImageRefSize = [self scaledImageSize];
    CGImageRef scaledImageRef = CGImageCreateScaledImage(cgImage,
                                                         scaledImageRefSize.width,
                                                         scaledImageRefSize.height);
    
    NSBitmapImageRep *currentBitmapRep = [[[NSBitmapImageRep alloc] initWithCGImage:scaledImageRef] autorelease];

    if (previousImageRep != nil) {
        NSBitmapImageRep *bitmapRep = CGImageCreateDifferenceWithImage(scaledImageRef,
                                                                       [previousImageRep CGImage]);
    
        // Create an NSImage and add the bitmap rep to it...
        NSImage *image = [[NSImage alloc] init];
        [image addRepresentation:bitmapRep];
        [bitmapRep release];
        // Set the output view to the new NSImage.
        [windowImageView setImage:image];
        [image release];
    } else {
        // Create an NSImage and add the bitmap rep to it...
        NSImage *image = [[NSImage alloc] init];
        [image addRepresentation:currentBitmapRep];
        //[bitmapRep release];
        // Set the output view to the new NSImage.
        [windowImageView setImage:image];
        [image release];
    }

    CGImageRelease(scaledImageRef);
}

- (float)getPercentageImageChanged:(CGImageRef)imageRef
{
    NSSize scaledImageRefSize = [self scaledImageSize];
    CGImageRef scaledImageRef = CGImageCreateScaledImage(imageRef,
                                                         scaledImageRefSize.width,
                                                         scaledImageRefSize.height);
    
    NSBitmapImageRep *currentBitmapRep = [[[NSBitmapImageRep alloc] initWithCGImage:scaledImageRef] autorelease];
    
    int pixels = scaledImageRefSize.width * scaledImageRefSize.height;
    int blackPixels = 0;
    
    if (previousImageRep != nil) {
        NSBitmapImageRep *bitmapRep = CGImageCreateDifferenceWithImage(scaledImageRef,
                                                                       [previousImageRep CGImage]);
        
        unsigned char *imageData = [bitmapRep bitmapData];
        for (int x = 0; x < scaledImageRefSize.width; x++) {
            for (int y = 0; y < scaledImageRefSize.height; y++) {
                if (CGImageDataPixelIsBlack(imageData, scaledImageRefSize.width, x, y))
                    blackPixels++;
            }
        }

        [bitmapRep release];
    } else {
        // If there isn't a previousImageRep then there shouldn't be a change
        blackPixels = pixels;
    }
    
    CGImageRelease(scaledImageRef);

    [previousImageRep release];
    previousImageRep = [currentBitmapRep retain];
    
    // Return the difference as a decimal percentage
    return 1.0 - ((float)blackPixels / pixels);
}

- (void)setWindowImage:(CGImageRef)cgImage
{
    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];

    // Create an NSImage and add the bitmap rep to it...
    NSImage *image = [[NSImage alloc] init];
    [image addRepresentation:bitmapRep];
    
    // Set the output view to the new NSImage.
    [windowImageView setImage:image];
    
    [bitmapRep release];
    [image release];
}

- (NSString *)replicappNotificationTitle
{
    return [replicappWindowOwnerName stringByAppendingFormat:@" %@",
            [replicappWindowName isEqual:@""] ? @"" : [NSString stringWithFormat:@"(%@)", replicappWindowName]];
}

- (NSData *)replicappNotificationIconData
{
    return [[[NSRunningApplication runningApplicationWithProcessIdentifier:replicappWindowOwnerId] icon] TIFFRepresentation];
}

- (void)replicappWindowImage
{
//    NSLog(@"repliacppWindowImage");
    CGImageRef windowImage = CGWindowListCreateImage(CGRectNull,
                                                     kCGWindowListOptionIncludingWindow,
                                                     replicappWindowId,
                                                     kCGWindowImageDefault | kCGWindowImageShouldBeOpaque | kCGWindowImageBoundsIgnoreFraming);
    if(CGImageGetWidth(windowImage) > kCGImageMinimumValidWidth) {
        // Hide the window warning when there is a valid image
        [windowWarningTextField setHidden:YES];
        [[self window] setBackgroundColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.25]];
        
        CGImageRef replicappImage = CGImageCreateWithImageInRect(windowImage, replicappRect);
        
        [self setWindowImage:replicappImage];
        
        if ([hasChangedNotificationButton state] == kNSButtonStatusOn || [noChangesNotificationButton state] == kNSButtonStatusOn) {
            // Get the percentage the image has changed from the previous image
            float percentageImageChanged = [self getPercentageImageChanged:replicappImage];
//            NSLog(@"percentageImageChanged:%f", percentageImageChanged);
            
            // Check whether the image has changed the selected amount
            if ([hasChangedNotificationButton state] == kNSButtonStatusOn &&
                    percentageImageChanged > kRCHasChangedPercentage[[hasChangedNotificationSlider intValue]]) {
                
                NSTimeInterval currentInterval = [[NSDate date] timeIntervalSinceDate:previousHasChangedDate];
                if (currentInterval > kRCNotificationMinimumSecondsInterval) {
                    NSUserNotification *notification = [[NSUserNotification alloc] init];
                    notification.title = [self replicappNotificationTitle];
                    notification.informativeText = [kRCHasChangedDescriptions[[hasChangedNotificationSlider intValue]] stringByReplacingOccurrencesOfString:@"Changes" withString:@"Changed"];
                    notification.soundName = NSUserNotificationDefaultSoundName;
                    [notification setValue:[[NSImage alloc] initWithData:[self replicappNotificationIconData]]
                                    forKey:@"_identityImage"];
                    [notification setValue:[NSNumber numberWithBool:NO] forKey:@"_identityImageHasBorder"];
                    
                    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];

                    [previousHasChangedDate release];
                    previousHasChangedDate = [[NSDate date] retain];
                }
            }
            
            // Check whether the image hasn't changed for the selected duration
            if ([noChangesNotificationButton state] == kNSButtonStatusOn) {
                if (percentageImageChanged > 0.0) {
                    [previousNoChangesDate release];
                    previousNoChangesDate = [[NSDate date] retain];
                } else {
                    NSTimeInterval currentInterval = [[NSDate date] timeIntervalSinceDate:previousNoChangesDate];
                    if (currentInterval > kRCNoChangesSeconds[[noChangesNotificationSlider intValue]]) {
                        NSUserNotification *notification = [[NSUserNotification alloc] init];
                        notification.title = [self replicappNotificationTitle];
                        notification.informativeText = kRCNoChangesDescriptions[[noChangesNotificationSlider intValue]];
                        notification.soundName = NSUserNotificationDefaultSoundName;
                        [notification setValue:[[NSImage alloc] initWithData:[self replicappNotificationIconData]]
                                        forKey:@"_identityImage"];
                        [notification setValue:[NSNumber numberWithBool:NO] forKey:@"_identityImageHasBorder"];
                        
                        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];

                        [previousNoChangesDate release];
                        previousNoChangesDate = [[NSDate date] retain];
                    }
                }
            }
        }
        
        CGImageRelease(replicappImage);
    } else {
        // Show the window warning when there isn't a valid image
        [windowWarningTextField setHidden:NO];
        [[self window] setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"RCWhiteyBackground"]]];

        // Set the image view to nil if the replicapp is minimized or closed
        [windowImageView setImage:nil];
    }

	CGImageRelease(windowImage);
}

- (IBAction)anchorTitlebarButtonClicked:(NSButton *)button
{
    windowLevel = [button state] == kNSButtonStatusOn ? NSFloatingWindowLevel : NSNormalWindowLevel;        
}

- (IBAction)settingsTitlebarButtonClicked:(NSButton *)button
{
//    NSLog(@"settingsTitlebarButtonClicked");
    if (settingsTitlebarPopoverController.popoverIsVisible) {
        [settingsTitlebarPopoverController closePopover:nil];
    } else {
        NSRect buttonBounds = [button bounds];
        [settingsTitlebarPopoverController showPopoverAtPoint:NSMakePoint(NSMidX(buttonBounds), NSMidY(buttonBounds))
                                                       inView:button
                                      preferredArrowDirection:INPopoverArrowDirectionUp
                                        anchorsToPositionView:YES];
    }
}

- (IBAction)refreshSliderChanged:(NSSlider *)slider
{
//    NSLog(@"refreshSliderChanged:%d", [slider intValue]);
    [replicappTimer invalidate];
    [replicappTimer release];
    replicappTimer = nil;
    
    replicappTimer = [[NSTimer scheduledTimerWithTimeInterval:kRCRefreshRates[[slider intValue]]
                                                       target:self
                                                     selector:@selector(replicappWindowImage)
                                                     userInfo:nil
                                                      repeats:YES] retain];
}

- (IBAction)hasChangedButtonClicked:(NSButton *)button
{
//    NSLog(@"hasChangedButtonClicked:%ld", [button state]);
    if ([button state] == kNSButtonStatusOn) {
        [hasChangedNotificationSlider setEnabled:YES];
        
    } else {
        [hasChangedNotificationSlider setEnabled:NO];
    }
    
    [hasChangedNotificationSlider setNeedsDisplay:YES];
}

- (IBAction)hasChangedSliderChanged:(NSSlider *)slider
{
//    NSLog(@"hasChangedSliderChanged:%d", [slider intValue]);
    [hasChangedNotificationTextField setStringValue:kRCHasChangedDescriptions[[slider intValue]]];
    [hasChangedNotificationTextField setNeedsDisplay:YES];
}

- (IBAction)noChangesButtonClicked:(NSButton *)button
{
//    NSLog(@"noChangesButtonClicked:%ld", [button state]);
    if ([button state] == kNSButtonStatusOn) {
        [noChangesNotificationSlider setEnabled:YES];
        
        [previousNoChangesDate release];
        previousNoChangesDate = [[NSDate date] retain];
    } else {
        [noChangesNotificationSlider setEnabled:NO];
    }
    
    [noChangesNotificationSlider setNeedsDisplay:YES];
}

- (IBAction)noChangesSliderChanged:(NSSlider *)slider
{
//    NSLog(@"noChangesSliderChanged:%d", [slider intValue]);
    [noChangesNotificationTextField setStringValue:kRCNoChangesDescriptions[[slider intValue]]];
    [noChangesNotificationTextField setNeedsDisplay:YES];
}

@end
