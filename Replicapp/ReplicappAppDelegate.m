//
//  ReplicappAppDelegate.m
//  Replicapp
//
//  Created by Alex Winston on 7/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DDHotKeyCenter.h"
#import "ReplicappAppDelegate.h"

@implementation ReplicappAppDelegate

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(highlightDisabledNotification:) 
                                                 name:@"RCHighlightDisabledNotification"
                                               object:nil];
    
    [selectionHighlightWindow setHasShadow:NO];
    [selectionHighlightWindow setOpaque:NO];
    [selectionHighlightWindow setBackgroundColor:[NSColor clearColor]];
    [selectionHighlightWindow setMovableByWindowBackground:NO];
    [selectionHighlightWindow setIgnoresMouseEvents:NO];
    [selectionHighlightWindow setAcceptsMouseMovedEvents:YES];
    [selectionHighlightWindow setLevel:NSFloatingWindowLevel];
    [selectionHighlightWindow setAlphaValue:0.5];
    
    [cursorPositionWindow setStyleMask:NSBorderlessWindowMask];
    [cursorPositionWindow setHasShadow:NO];
    [cursorPositionWindow setOpaque:NO];
	[cursorPositionWindow setBackgroundColor:[NSColor clearColor]];
	[cursorPositionWindow setMovableByWindowBackground:NO];
	[cursorPositionWindow setIgnoresMouseEvents:NO];
	[cursorPositionWindow setAcceptsMouseMovedEvents:YES];
    
    // Create the status menubar
    // Set the menubar items
    NSMenu *menu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
//    [menu setDelegate:self];

    // Show
    NSMenuItem *showMenuItem = [menu addItemWithTitle:@"Enable Replicapp"
                                               action:@selector(enable:)
                                        keyEquivalent:@"5"];
    [showMenuItem setKeyEquivalentModifierMask:NSShiftKeyMask | NSCommandKeyMask];
    [showMenuItem setTarget:self];
    
    // Separator
    [menu addItem:[NSMenuItem separatorItem]];
    
    // Quit
    NSMenuItem *windowMenuItem = [menu addItemWithTitle:@"Window"
                                               action:nil
                                        keyEquivalent:@""];
    [windowMenuItem setTarget:self];
    statusWindowPopUpButton = [[[NSPopUpButton alloc] init] retain];
    [statusWindowPopUpButton sizeToFit];
    [statusWindowPopUpButton setPullsDown:NO];
    [statusWindowPopUpButton setTarget:self];
    [statusWindowPopUpButton setAction:nil];
    NSMenu *windowMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
    [windowMenu addItemWithTitle:@"Bring All to Front" action:@selector(bringAllToFront:) keyEquivalent:@""];
//    [windowMenu addItem:[NSMenuItem separatorItem]];
//    [windowMenu addItemWithTitle:@"Test Window" action:nil keyEquivalent:@""];
    [windowMenuItem setSubmenu:windowMenu];
    [windowMenu release];
    
    // Separator
    [menu addItem:[NSMenuItem separatorItem]];
    
    // Quit
    NSMenuItem *quitMenuItem = [menu addItemWithTitle:@"Quit Replicapp"
                                               action:@selector(quit:)
                                        keyEquivalent:@"q"];
    [quitMenuItem setKeyEquivalentModifierMask:NSCommandKeyMask];
    [quitMenuItem setTarget:self];
    
    // Add NSMenu to StatusItem
    statusBar = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    [statusBar setHighlightMode:YES];
    [statusBar setImage:[NSImage imageNamed:@"RCStatusItem"]];
    [statusBar setAlternateImage:[NSImage imageNamed:@"RCStatusItemAlt"]];
    [statusBar setMenu:menu];
    
    [menu release];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [statusBar release];
    [statusWindowPopUpButton release];
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    DDHotKeyCenter * c = [[DDHotKeyCenter alloc] init];
    if (![c registerHotKeyWithKeyCode:23 modifierFlags:NSShiftKeyMask | NSCommandKeyMask target:self action:@selector(handleHotKey:) object:nil]) {
		NSLog(@"Unable to register hotkey");
	} else {
		NSLog(@"Registered hotkey");
	}
	[c release];
    
    // Set the notification center delegate
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification{
    return YES;
}

- (void)applicationDidResignActive:(NSNotification *)notification
{
    [selectionHighlightView disable];
}


- (void)enable:(id)sender
{
    
    //    for (NSWindow *window in [NSApp windows])
    //        NSLog(@"%ld", [window windowNumber]);
    [statusBar setImage:[NSImage imageNamed:@"RCStatusItemEnabled"]];
    
    [selectionHighlightView enable];
}

- (void)highlightDisabledNotification:(id)sender
{
    NSLog(@"highlightDisabledNotification");
    [statusBar setImage:[NSImage imageNamed:@"RCStatusItem"]];
}

- (void)handleHotKey:(NSEvent *)event
{
    NSLog(@"handleHotKey:");
    
    [self enable:self];
}

- (void)bringAllToFront:(id)sender
{
    [NSApp activateIgnoringOtherApps:YES];
    [NSApp arrangeInFront:self];
}

- (void)quit:(id)sender
{
    [NSApp terminate:sender];
}

@end
